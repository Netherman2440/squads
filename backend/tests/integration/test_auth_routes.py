import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import uuid
import tempfile
import os
from datetime import datetime, timezone
from unittest.mock import patch, MagicMock

from app.main import app
from app.models import User, Base
from app.services.user_service import UserService
from app.utils.jwt import create_access_token
from app.routes.auth import get_db as get_auth_db


@pytest.fixture
def session():
    """Create temporary SQLite database session for testing"""
    # Create a temporary file for the database
    temp_db = tempfile.NamedTemporaryFile(delete=False, suffix='.db')
    temp_db.close()
    
    engine = create_engine(f"sqlite:///{temp_db.name}")
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    session = Session()
    
    yield session
    
    # Cleanup
    session.close()
    engine.dispose()
    os.unlink(temp_db.name)


@pytest.fixture
def client(session):
    """Create test client with test database"""
    def override_get_db():
        try:
            yield session
        finally:
            pass
    
    app.dependency_overrides = {}
    app.dependency_overrides[get_auth_db] = override_get_db
    return TestClient(app)


@pytest.fixture
def sample_user(session):
    """Create a sample user for testing"""
    user = User(
        user_id=str(uuid.uuid4()),
        username="test@example.com",
        password_hash="hashed_password",
        created_at=datetime.now(timezone.utc)
    )
    session.add(user)
    session.commit()
    return user


class TestAuthRoutes:
    """Test class for auth routes functionality"""

    def test_register_new_user(self, client, session):
        """Test registering a new user"""
        user_data = {
            "username": "newuser@example.com",
            "password": "testpassword123"
        }
        
        response = client.post("/api/v1/auth/register", json=user_data)
        
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
        assert "user" in data
        assert data["user"]["username"] == "newuser@example.com"
        assert "user_id" in data["user"]
        assert "created_at" in data["user"]
        assert "password" not in data["user"]  # Password should not be returned

    def test_register_existing_user(self, client, session, sample_user):
        """Test registering with existing username"""
        user_data = {
            "username": sample_user.username,
            "password": "testpassword123"
        }
        
        response = client.post("/api/v1/auth/register", json=user_data)
        
        assert response.status_code == 400
        assert "Email already registered" in response.json()["detail"]

    def test_login_valid_credentials(self, client, session, sample_user):
        """Test login with valid credentials"""
        # Mock the password verification
        with patch.object(UserService, 'login') as mock_login:
            # Create a mock user with to_response method
            mock_user = MagicMock()
            mock_user.user_id = sample_user.user_id
            mock_user.username = sample_user.username
            mock_user.to_response.return_value = {
                "user_id": sample_user.user_id,
                "username": sample_user.username,
                "created_at": sample_user.created_at.isoformat(),
                "owned_squads": [],
                "squads": []
            }
            mock_login.return_value = mock_user
            
            login_data = {
                "username": sample_user.username,
                "password": "testpassword123"
            }
            
            response = client.post("/api/v1/auth/login", data=login_data)
            
            assert response.status_code == 200
            data = response.json()
            assert "access_token" in data
            assert data["token_type"] == "bearer"
            assert "user" in data
            assert data["user"]["username"] == sample_user.username

    def test_login_invalid_credentials(self, client):
        """Test login with invalid credentials"""
        with patch.object(UserService, 'login') as mock_login:
            from fastapi import HTTPException
            mock_login.side_effect = HTTPException(status_code=401, detail="Invalid credentials")
            
            login_data = {
                "username": "wrong@example.com",
                "password": "wrongpassword"
            }
            
            response = client.post("/api/v1/auth/login", data=login_data)
            
            assert response.status_code == 401
            assert "Invalid credentials" in response.json()["detail"]

    def test_login_nonexistent_user(self, client):
        """Test login with non-existent user"""
        with patch.object(UserService, 'login') as mock_login:
            from fastapi import HTTPException
            mock_login.side_effect = HTTPException(status_code=404, detail="User not found")
            
            login_data = {
                "username": "nonexistent@example.com",
                "password": "testpassword123"
            }
            
            response = client.post("/api/v1/auth/login", data=login_data)
            
            assert response.status_code == 404
            assert "User not found" in response.json()["detail"]

    def test_guest_login(self, client):
        """Test guest login endpoint"""
        response = client.post("/api/v1/auth/guest")
        
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
        # Guest login should return user as null
        assert "user" in data
        assert data["user"] is None

    def test_register_missing_fields(self, client):
        """Test register with missing required fields"""
        # Missing email
        user_data = {
            "password": "testpassword123"
        }
        
        response = client.post("/api/v1/auth/register", json=user_data)
        
        assert response.status_code == 422

        # Missing password
        user_data = {
            "username": "test@example.com"
        }
        
        response = client.post("/api/v1/auth/register", json=user_data)
        
        assert response.status_code == 422

    def test_login_missing_fields(self, client):
        """Test login with missing required fields"""
        # Missing username
        login_data = {
            "password": "testpassword123"
        }
        
        response = client.post("/api/v1/auth/login", data=login_data)
        
        assert response.status_code == 422

        # Missing password
        login_data = {
            "username": "test@example.com"
        }
        
        response = client.post("/api/v1/auth/login", data=login_data)
        
        assert response.status_code == 422

    def test_register_empty_fields(self, client):
        """Test register with empty fields"""
        user_data = {
            "username": "",
            "password": ""
        }
        
        response = client.post("/api/v1/auth/register", json=user_data)
        
        assert response.status_code == 422

    def test_login_empty_fields(self, client):
        """Test login with empty fields"""
        login_data = {
            "username": "",
            "password": ""
        }
        
        response = client.post("/api/v1/auth/login", data=login_data)
        
        assert response.status_code == 401  # Unauthorized for empty credentials 