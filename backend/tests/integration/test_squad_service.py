import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import uuid
from datetime import datetime, timezone

from app.models import Squad, Player, Match, User, Base
from app.services.squad_service import SquadService
from app.entities import SquadData, SquadDetailData


@pytest.fixture
def session():
    """Create in-memory SQLite database session for testing"""
    engine = create_engine("sqlite:///:memory:")
    # Create all tables
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    return Session()


@pytest.fixture
def squad_service(session):
    """Create SquadService instance with test session"""
    return SquadService(session)


@pytest.fixture
def sample_user(session):
    """Create a sample user for testing"""
    user = User(
        user_id=str(uuid.uuid4()),
        email="test@example.com",
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
def sample_squad_with_players(session, sample_user):
    """Create a squad with players for testing"""
    squad = Squad(
        squad_id=str(uuid.uuid4()),
        name="Squad with Players",
        created_at=datetime.now(timezone.utc),
        owner_id=sample_user.user_id
    )
    session.add(squad)
    session.commit()
    
    # Add players to the squad
    players = []
    for i in range(3):
        player = Player(
            player_id=str(uuid.uuid4()),
            squad_id=squad.squad_id,
            name=f"Player {i+1}",
            position="field",
            base_score=10,
            score=10.0
        )
        players.append(player)
        session.add(player)
    
    session.commit()
    return squad, players


@pytest.fixture
def sample_squad_with_matches(session, sample_user):
    """Create a squad with matches for testing"""
    squad = Squad(
        squad_id=str(uuid.uuid4()),
        name="Squad with Matches",
        created_at=datetime.now(timezone.utc),
        owner_id=sample_user.user_id
    )
    session.add(squad)
    session.commit()
    
    # Add matches to the squad
    matches = []
    for i in range(2):
        match = Match(
            match_id=str(uuid.uuid4()),
            squad_id=squad.squad_id,
            created_at=datetime.now(timezone.utc)
        )
        matches.append(match)
        session.add(match)
    
    session.commit()
    return squad, matches


class TestSquadService:
    """Test class for SquadService functionality"""

    def test_list_squads_empty(self, squad_service):
        """Test listing squads when database is empty"""
        squads = squad_service.list_squads()
        assert squads == []
        assert isinstance(squads, list)

    def test_list_squads_with_data(self, squad_service, sample_squad):
        """Test listing squads with existing data"""
        squads = squad_service.list_squads()
        
        assert len(squads) == 1
        assert isinstance(squads[0], SquadData)
        
        # Test model conversion from Squad to SquadData
        squad_data = squads[0]
        assert squad_data.squad_id == sample_squad.squad_id
        assert squad_data.name == sample_squad.name
        assert squad_data.created_at == sample_squad.created_at

    def test_get_squad_existing(self, squad_service, sample_squad):
        """Test getting an existing squad"""
        squad_data = squad_service.get_squad(sample_squad.squad_id)
        
        assert isinstance(squad_data, SquadData)
        assert squad_data.squad_id == sample_squad.squad_id
        assert squad_data.name == sample_squad.name
        assert squad_data.created_at == sample_squad.created_at
        assert hasattr(squad_data, 'players_count')

    def test_get_squad_nonexistent(self, squad_service):
        """Test getting a non-existent squad raises ValueError"""
        fake_id = str(uuid.uuid4())
        
        with pytest.raises(ValueError, match="Squad not found"):
            squad_service.get_squad(fake_id)

    def test_create_squad(self, squad_service, session, sample_user):
        """Test creating a new squad"""
        initial_count = session.query(Squad).count()
        
        squad_data = squad_service.create_squad("Test Squad", sample_user.user_id)
        
        # Verify squad was created in database
        final_count = session.query(Squad).count()
        assert final_count == initial_count + 1
        
        # Verify returned data
        assert isinstance(squad_data, SquadData)
        assert squad_data.squad_id is not None
        assert squad_data.name is not None
        assert squad_data.created_at is not None
        assert hasattr(squad_data, 'players_count')
        
        # Verify squad exists in database
        db_squad = session.query(Squad).filter(Squad.squad_id == squad_data.squad_id).first()
        assert db_squad is not None
        assert db_squad.squad_id == squad_data.squad_id
        assert db_squad.name == squad_data.name
        assert db_squad.created_at == squad_data.created_at
        assert db_squad.owner_id == sample_user.user_id

    def test_update_squad_name(self, squad_service, sample_squad):
        """Test updating squad name"""
        new_name = "Updated Squad Name"
        updated_squad = squad_service.update_squad_name(sample_squad.squad_id, new_name)
        
        assert updated_squad.name == new_name
        assert updated_squad.squad_id == sample_squad.squad_id

    def test_delete_squad(self, squad_service, sample_squad, session):
        """Test deleting a squad"""
        squad_id = sample_squad.squad_id
        initial_count = session.query(Squad).count()
        
        squad_service.delete_squad(squad_id)
        
        final_count = session.query(Squad).count()
        assert final_count == initial_count - 1
        
        deleted_squad = session.query(Squad).filter(Squad.squad_id == squad_id).first()
        assert deleted_squad is None

    def test_delete_squad_nonexistent(self, squad_service):
        """Test deleting a non-existent squad raises ValueError"""
        fake_id = str(uuid.uuid4())
        
        with pytest.raises(ValueError, match="Squad not found"):
            squad_service.delete_squad(fake_id)

    def test_delete_squad_with_players_cascade(self, squad_service, sample_squad_with_players, session):
        """Test that deleting a squad also deletes associated players (cascade)"""
        squad, players = sample_squad_with_players
        squad_id = squad.squad_id
        
        initial_player_count = session.query(Player).filter(Player.squad_id == squad_id).count()
        assert initial_player_count == 3
        
        squad_service.delete_squad(squad_id)
        
        deleted_squad = session.query(Squad).filter(Squad.squad_id == squad_id).first()
        assert deleted_squad is None
        
        
        remaining_players = session.query(Player).filter(Player.squad_id == squad_id).count()
        
        assert remaining_players == 0

    def test_get_squad_detail_empty_squad(self, squad_service, sample_squad):
        """Test getting squad detail for squad with no players or matches"""
        squad_detail = squad_service.get_squad_detail(sample_squad.squad_id)
        
        assert isinstance(squad_detail, SquadDetailData)
        assert squad_detail.squad_id == sample_squad.squad_id
        assert squad_detail.name == sample_squad.name
        assert squad_detail.created_at == sample_squad.created_at
        assert squad_detail.players == []
        assert squad_detail.matches == []

    def test_get_squad_detail_with_players(self, squad_service, sample_squad_with_players):
        """Test getting squad detail for squad with players"""
        squad, players = sample_squad_with_players
        
        squad_detail = squad_service.get_squad_detail(squad.squad_id)
        
        assert isinstance(squad_detail, SquadDetailData)
        assert squad_detail.squad_id == squad.squad_id
        assert len(squad_detail.players) == 3
        
        for i, player_data in enumerate(squad_detail.players):
            original_player = players[i]
            assert player_data.player_id == original_player.player_id
            assert player_data.name == original_player.name
            assert player_data.position == original_player.position

    def test_get_squad_detail_with_matches(self, squad_service, sample_squad_with_matches):
        """Test getting squad detail for squad with matches"""
        squad, matches = sample_squad_with_matches
        
        squad_detail = squad_service.get_squad_detail(squad.squad_id)
        
        assert isinstance(squad_detail, SquadDetailData)
        assert squad_detail.squad_id == squad.squad_id
        assert len(squad_detail.matches) == 2
        
        for i, match_data in enumerate(squad_detail.matches):
            original_match = matches[i]
            assert match_data.match_id == original_match.match_id

    def test_get_squad_detail_nonexistent(self, squad_service):
        """Test getting squad detail for non-existent squad raises ValueError"""
        fake_id = str(uuid.uuid4())
        
        with pytest.raises(ValueError, match="Squad not found"):
            squad_service.get_squad_detail(fake_id)

    def test_multiple_squads_isolation(self, squad_service, session, sample_user):
        """Test that operations on one squad don't affect others"""
        # Create multiple squads
        squad1 = Squad(name="Squad 1", owner_id=sample_user.user_id)
        squad2 = Squad(name="Squad 2", owner_id=sample_user.user_id)
        session.add_all([squad1, squad2])
        session.commit()
        
        # Add player to squad1 only
        player = Player(
            squad_id=squad1.squad_id,
            name="Test Player",
            position="field",
            base_score=10,
            score=10.0
        )
        session.add(player)
        session.commit()
        
        # Get details for both squads
        detail1 = squad_service.get_squad_detail(squad1.squad_id)
        detail2 = squad_service.get_squad_detail(squad2.squad_id)
        
        # Verify isolation
        assert len(detail1.players) == 1
        assert len(detail2.players) == 0
        assert detail1.players_count == 1
        assert detail2.players_count == 0
        
        # Delete squad1 and verify squad2 is unaffected
        squad_service.delete_squad(squad1.squad_id)
        
        # squad2 should still exist
        remaining_squad = squad_service.get_squad(squad2.squad_id)
        assert remaining_squad.squad_id == squad2.squad_id
        assert remaining_squad.name == squad2.name
