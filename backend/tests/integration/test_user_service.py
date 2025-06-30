import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import uuid
from datetime import datetime, timezone
from fastapi import HTTPException

from app.models import User, Base
from app.services.user_service import UserService
from app.entities import UserData

@pytest.fixture
def session():
    """Create in-memory SQLite database session for testing"""
    engine = create_engine("sqlite:///:memory:")
    # Create all tables
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    return Session()

@pytest.fixture
def user_service(session):
    return UserService(session)

class TestUserService:
    """Test class for UserService functionality"""

    def test_register_user_success(self, user_service, session):
        """Test successful user registration"""
        username = "test@example.com"
        password = "testpassword123"
        
        initial_count = session.query(User).count()
        
        user_data = user_service.register(username, password)
        
        # Verify user was created in database
        final_count = session.query(User).count()
        assert final_count == initial_count + 1
        
        # Verify returned data
        assert isinstance(user_data, UserData)
        assert user_data.user_id is not None
        assert user_data.username == username
        assert user_data.password_hash is not None
        assert user_data.created_at is not None
        assert user_data.owned_squads == []
        
        # Verify user exists in database
        db_user = session.query(User).filter(User.user_id == user_data.user_id).first()
        assert db_user is not None
        assert db_user.username == username
        assert db_user.password_hash is not None
        assert db_user.created_at is not None

    def test_register_user_email_exists(self, user_service, session):
        """Test registration with existing username"""
        username = "existing@example.com"
        password = "testpassword123"
        
        # Create initial user
        user_service.register(username, password)
        initial_count = session.query(User).count()
        
        # Try to register again with same username
        with pytest.raises(HTTPException) as exc_info:
            user_service.register(username, password)
        
        assert exc_info.value.status_code == 400
        assert exc_info.value.detail == "Email already registered"
        
        # Verify no new user was created
        final_count = session.query(User).count()
        assert final_count == initial_count

    def test_login_success(self, user_service, session):
        """Test successful login"""
        username = "test@example.com"
        password = "testpassword123"
        
        # Register user first
        registered_user = user_service.register(username, password)
        
        # Try to login
        logged_in_user = user_service.login(username, password)
        
        assert isinstance(logged_in_user, UserData)
        assert logged_in_user.user_id == registered_user.user_id
        assert logged_in_user.username == username
        assert logged_in_user.owned_squads == []

    def test_login_invalid_credentials(self, user_service, session):
        """Test login with invalid credentials"""
        username = "test@example.com"
        password = "testpassword123"
        
        # Register user first
        user_service.register(username, password)
        
        # Try to login with wrong password
        with pytest.raises(HTTPException) as exc_info:
            user_service.login(username, "wrongpassword")
        
        assert exc_info.value.status_code == 401
        assert exc_info.value.detail == "Invalid credentials"
        
        # Try to login with non-existent username
        with pytest.raises(HTTPException) as exc_info:
            user_service.login("nonexistent@example.com", password)
        
        assert exc_info.value.status_code == 401
        assert exc_info.value.detail == "Invalid credentials"

    def test_get_user_by_id_success(self, user_service, session):
        """Test getting user by ID when user exists"""
        username = "test@example.com"
        password = "testpassword123"
        
        # Register user first
        registered_user = user_service.register(username, password)
        
        # Get user by ID
        user = user_service.get_user_by_id(registered_user.user_id)
        
        assert isinstance(user, UserData)
        assert user.user_id == registered_user.user_id
        assert user.username == username
        assert user.owned_squads == []

    def test_get_user_by_id_not_found(self, user_service):
        """Test getting user by ID when user doesn't exist"""
        fake_id = str(uuid.uuid4())
        user = user_service.get_user_by_id(fake_id)
        assert user is None

    def test_multiple_users_isolation(self, user_service, session):
        """Test that operations on one user don't affect others"""
        # Create multiple users
        user1 = user_service.register("user1@example.com", "password1")
        user2 = user_service.register("user2@example.com", "password2")
        
        # Verify users are different
        assert user1.user_id != user2.user_id
        assert user1.username != user2.username
        
        # Verify login works for both users
        logged_in_user1 = user_service.login("user1@example.com", "password1")
        logged_in_user2 = user_service.login("user2@example.com", "password2")
        
        assert logged_in_user1.user_id == user1.user_id
        assert logged_in_user2.user_id == user2.user_id
        
        # Verify getting users by ID works correctly
        retrieved_user1 = user_service.get_user_by_id(user1.user_id)
        retrieved_user2 = user_service.get_user_by_id(user2.user_id)
        
        assert retrieved_user1.user_id == user1.user_id
        assert retrieved_user2.user_id == user2.user_id

    def test_logout_method(self, user_service):
        """Test logout method (currently empty implementation)"""
        # The logout method is currently empty, so we just test it doesn't raise an exception
        user_service.logout()
        # If we reach here, the test passes (no exception raised) 