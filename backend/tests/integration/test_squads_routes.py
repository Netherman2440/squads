import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import uuid
from datetime import datetime, timezone
from unittest.mock import patch, MagicMock
import tempfile
import os

from app.main import app
from app.models import Squad, Player, Match, User, Base, UserSquad
from app.services.squad_service import SquadService
from app.services.player_service import PlayerService
from app.services.match_service import MatchService
from app.utils.jwt import create_access_token
from app.routes.squads import get_db as get_squads_db
from app.routes.auth import get_db as get_auth_db


@pytest.fixture
def session():
    """Create temporary SQLite database session for testing"""
    # Create a temporary file for the database
    temp_db = tempfile.NamedTemporaryFile(delete=False, suffix='.db')
    temp_db.close()
    
    # Use check_same_thread=False to avoid threading issues
    engine = create_engine(f"sqlite:///{temp_db.name}?check_same_thread=False")
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
    app.dependency_overrides[get_squads_db] = override_get_db
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


@pytest.fixture
def sample_squad(session, sample_user):
    """Create a sample squad for testing"""
    squad = Squad(
        squad_id=str(uuid.uuid4()),
        name="Test Squad",
        created_at=datetime.now(timezone.utc),
        owner_id=sample_user.user_id
    )
    session.add(squad)
    session.commit()
    return squad


@pytest.fixture
def auth_headers(sample_user):
    """Create authentication headers with JWT token"""
    token = create_access_token(data={"sub": sample_user.user_id})
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def guest_headers():
    """Create guest authentication headers"""
    from app.utils.jwt import get_guest_token
    token = get_guest_token()
    return {"Authorization": f"Bearer {token}"}


class TestSquadsRoutes:
    """Test class for squads routes functionality"""

    def test_get_all_squads_authenticated(self, client, session, sample_squad, auth_headers):
        """Test getting all squads with authenticated user"""
        response = client.get("/api/v1/squads/", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert "squads" in data
        assert len(data["squads"]) == 1
        assert data["squads"][0]["squad_id"] == sample_squad.squad_id
        assert data["squads"][0]["name"] == sample_squad.name

    def test_get_all_squads_guest(self, client, session, sample_squad, guest_headers):
        """Test getting all squads with guest user"""
        response = client.get("/api/v1/squads/", headers=guest_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert "squads" in data
        assert len(data["squads"]) == 1

    def test_get_all_squads_unauthorized(self, client):
        """Test getting all squads without authentication"""
        response = client.get("/api/v1/squads/")
        
        assert response.status_code == 403  # FastAPI security returns 403 for missing auth

    def test_create_squad_authenticated(self, client, session, sample_user, auth_headers):
        """Test creating a squad with authenticated user"""
        squad_data = {"name": "New Test Squad"}
        response = client.post("/api/v1/squads/", json=squad_data, headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "New Test Squad"
        assert data["owner_id"] == sample_user.user_id
        assert "squad_id" in data
        assert "created_at" in data

    def test_create_squad_guest_forbidden(self, client, guest_headers):
        """Test that guest users cannot create squads"""
        squad_data = {"name": "New Test Squad"}
        response = client.post("/api/v1/squads/", json=squad_data, headers=guest_headers)
        
        assert response.status_code == 403
        assert "Guest users cannot create squads" in response.json()["detail"]

    def test_create_squad_unauthorized(self, client):
        """Test creating a squad without authentication"""
        squad_data = {"name": "New Test Squad"}
        response = client.post("/api/v1/squads/", json=squad_data)
        
        assert response.status_code == 403

    def test_get_squad_detail_authenticated(self, client, session, sample_squad, auth_headers):
        """Test getting squad detail with authenticated user"""
        response = client.get(f"/api/v1/squads/{sample_squad.squad_id}", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["squad_id"] == sample_squad.squad_id
        assert data["name"] == sample_squad.name
        assert "players" in data
        assert "matches" in data

    def test_get_squad_detail_nonexistent(self, client, auth_headers):
        """Test getting non-existent squad"""
        fake_id = str(uuid.uuid4())
        response = client.get(f"/api/v1/squads/{fake_id}", headers=auth_headers)
        
        assert response.status_code == 404
        assert "Squad not found" in response.json()["detail"]

    def test_delete_squad_owner(self, client, session, sample_squad, auth_headers):
        """Test deleting squad by owner"""
        response = client.delete(f"/api/v1/squads/{sample_squad.squad_id}", headers=auth_headers)
        
        assert response.status_code == 204
        
        # Verify squad was deleted
        squad_exists = session.query(Squad).filter(Squad.squad_id == sample_squad.squad_id).first()
        assert squad_exists is None

    def test_delete_squad_non_owner(self, client, session, sample_squad):
        """Test that non-owner cannot delete squad"""
        # Create another user
        other_user = User(
            user_id=str(uuid.uuid4()),
            username="other@example.com",
            password_hash="hashed_password",
            created_at=datetime.now(timezone.utc)
        )
        session.add(other_user)
        session.commit()
        
        # Create token for other user
        other_token = create_access_token(data={"sub": other_user.user_id})
        other_headers = {"Authorization": f"Bearer {other_token}"}
        
        response = client.delete(f"/api/v1/squads/{sample_squad.squad_id}", headers=other_headers)
        
        assert response.status_code == 403
        assert "Only squad owner can delete the squad" in response.json()["detail"]

    def test_delete_squad_nonexistent(self, client, auth_headers):
        """Test deleting non-existent squad"""
        fake_id = str(uuid.uuid4())
        response = client.delete(f"/api/v1/squads/{fake_id}", headers=auth_headers)
        
        assert response.status_code == 403  # Forbidden because user cannot access non-existent squad

    def test_get_players_authenticated(self, client, session, sample_squad, auth_headers):
        """Test getting players in squad"""
        # Add a player to the squad
        player = Player(
            player_id=str(uuid.uuid4()),
            squad_id=sample_squad.squad_id,
            name="Test Player",
            position="field",
            base_score=10,
            score=10.0
        )
        session.add(player)
        session.commit()
        
        response = client.get(f"/api/v1/squads/{sample_squad.squad_id}/players", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert "players" in data
        assert len(data["players"]) == 1
        assert data["players"][0]["name"] == "Test Player"

    def test_add_player_owner(self, client, session, sample_squad, auth_headers):
        """Test adding player by squad owner"""
        player_data = {
            "name": "New Player",
            "base_score": 15,
            "position": "field"
        }
        
        response = client.post(f"/api/v1/squads/{sample_squad.squad_id}/players", 
                             json=player_data, headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "New Player"
        assert data["base_score"] == 15
        assert data["position"] == "field"

    def test_add_player_non_owner(self, client, session, sample_squad):
        """Test that non-owner cannot add players"""
        # Create another user
        other_user = User(
            user_id=str(uuid.uuid4()),
            username="other@example.com",
            password_hash="hashed_password",
            created_at=datetime.now(timezone.utc)
        )
        session.add(other_user)
        session.commit()
        
        # Create token for other user
        other_token = create_access_token(data={"sub": other_user.user_id})
        other_headers = {"Authorization": f"Bearer {other_token}"}
        
        player_data = {
            "name": "New Player",
            "base_score": 15,
            "position": "field"
        }
        
        response = client.post(f"/api/v1/squads/{sample_squad.squad_id}/players", 
                             json=player_data, headers=other_headers)
        
        assert response.status_code == 403
        assert "Only squad owner can add players" in response.json()["detail"]

    def test_get_matches_authenticated(self, client, session, sample_squad, auth_headers):
        """Test getting matches in squad"""
        # Add a match to the squad
        match = Match(
            match_id=str(uuid.uuid4()),
            squad_id=sample_squad.squad_id,
            created_at=datetime.now(timezone.utc)
        )
        session.add(match)
        session.commit()
        
        response = client.get(f"/api/v1/squads/{sample_squad.squad_id}/matches", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert "matches" in data
        assert len(data["matches"]) == 1

    def test_create_match_authenticated(self, client, session, sample_squad, auth_headers):
        """Test creating a match with valid authentication"""
        match_data = {
            "team_a": [],  # Empty teams for now
            "team_b": []
        }
        
        response = client.post(f"/api/v1/squads/{sample_squad.squad_id}/matches", 
                              json=match_data, headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert "squad_id" in data
        assert "match_id" in data
        assert data["squad_id"] == sample_squad.squad_id

    def test_create_match_non_owner(self, client, session, sample_squad):
        """Test that non-owner cannot create matches"""
        # Create another user
        other_user = User(
            user_id=str(uuid.uuid4()),
            username="other@example.com",
            password_hash="hashed_password",
            created_at=datetime.now(timezone.utc)
        )
        session.add(other_user)
        session.commit()
        
        # Create token for other user
        other_token = create_access_token(data={"sub": other_user.user_id})
        other_headers = {"Authorization": f"Bearer {other_token}"}
        
        match_data = {
            "team_a": [],  # Empty teams
            "team_b": []
        }
        
        response = client.post(f"/api/v1/squads/{sample_squad.squad_id}/matches", 
                             json=match_data, headers=other_headers)
        
        assert response.status_code == 403
        assert "Only squad owner can create matches" in response.json()["detail"] 