import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import uuid
from datetime import datetime, timezone

from app.models import Squad, Player, Match, User, Base, UserSquad
from app.services.squad_service import SquadService
from app.entities import SquadData, SquadDetailData
from app.constants import UserRole


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
            assert player_data.position.value == original_player.position

    def test_get_squad_detail_with_matches(self, squad_service, sample_squad_with_matches):
        """Test getting squad detail for squad with matches"""
        squad, matches = sample_squad_with_matches
        
        squad_detail = squad_service.get_squad_detail(squad.squad_id)
        
        assert isinstance(squad_detail, SquadDetailData)
        assert squad_detail.squad_id == squad.squad_id
        assert len(squad_detail.matches) == 2
        
        # Get match IDs from both original and detail data
        original_match_ids = {match.match_id for match in matches}
        detail_match_ids = {match_data.match_id for match_data in squad_detail.matches}
        
        # Verify all original matches are present in detail data
        assert original_match_ids == detail_match_ids

    def test_get_squad_detail_nonexistent(self, squad_service):
        """Test getting squad detail for non-existent squad raises ValueError"""
        fake_id = str(uuid.uuid4())
        
        with pytest.raises(ValueError, match="Squad not found"):
            squad_service.get_squad_detail(fake_id)

    def test_multiple_squads_isolation(self, squad_service, session, sample_user):
        """Test that operations on one squad don't affect others"""
        # Create multiple squads
        squad1 = squad_service.create_squad("Squad 1", sample_user.user_id)
        squad2 = squad_service.create_squad("Squad 2", sample_user.user_id)
        
        # Verify squads are different
        assert squad1.squad_id != squad2.squad_id
        assert squad1.name != squad2.name
        
        # Update one squad and verify the other is unchanged
        updated_squad1 = squad_service.update_squad_name(squad1.squad_id, "Updated Squad 1")
        unchanged_squad2 = squad_service.get_squad_detail(squad2.squad_id)
        
        assert updated_squad1.name == "Updated Squad 1"
        assert unchanged_squad2.name == "Squad 2"

    def test_update_squad_owner_success(self, squad_service, session, sample_user):
        """Test updating squad owner successfully"""
        # Create squad using create_squad to ensure UserSquad entry is created
        squad = squad_service.create_squad("Test Squad", sample_user.user_id)
        new_owner_id = str(uuid.uuid4())
        
        # Add the new user to the squad as a member first
        squad_service.add_user_to_squad(squad.squad_id, new_owner_id, UserRole.MEMBER)
        
        updated_squad = squad_service.update_squad_owner(squad.squad_id, new_owner_id)
        
        assert updated_squad.owner_id == new_owner_id
        assert updated_squad.squad_id == squad.squad_id
        
        # Verify database was updated
        db_squad = session.query(Squad).filter(Squad.squad_id == squad.squad_id).first()
        assert db_squad.owner_id == new_owner_id

    def test_update_squad_owner_nonexistent_squad(self, squad_service):
        """Test updating owner of non-existent squad raises ValueError"""
        fake_id = str(uuid.uuid4())
        new_owner_id = str(uuid.uuid4())
        
        with pytest.raises(ValueError, match="Squad not found"):
            squad_service.update_squad_owner(fake_id, new_owner_id)

    def test_update_squad_owner_with_empty_owner_id(self, squad_service, session, sample_user):
        """Test updating squad owner with empty owner ID"""
        # Create squad using create_squad to ensure UserSquad entry is created
        squad = squad_service.create_squad("Test Squad", sample_user.user_id)
        empty_owner_id = ""
        
        # Add empty user ID to squad first
        squad_service.add_user_to_squad(squad.squad_id, empty_owner_id, UserRole.MEMBER)
        
        updated_squad = squad_service.update_squad_owner(squad.squad_id, empty_owner_id)
        
        assert updated_squad.owner_id == empty_owner_id
        assert updated_squad.squad_id == squad.squad_id

    def test_update_squad_owner_success_with_user_squad_roles(self, squad_service, session, sample_user):
        """Test updating squad owner successfully with UserSquad role changes"""
        # Create squad using create_squad to ensure UserSquad entry is created
        squad = squad_service.create_squad("Test Squad", sample_user.user_id)
        
        # Create a new user to be the new owner
        new_owner_id = str(uuid.uuid4())
        
        # Add the new user to the squad as a member first
        squad_service.add_user_to_squad(squad.squad_id, new_owner_id, UserRole.MEMBER)
        
        # Update the owner
        updated_squad = squad_service.update_squad_owner(squad.squad_id, new_owner_id)
        
        assert updated_squad.owner_id == new_owner_id
        assert updated_squad.squad_id == squad.squad_id
        
        # Verify database was updated
        db_squad = session.query(Squad).filter(Squad.squad_id == squad.squad_id).first()
        assert db_squad.owner_id == new_owner_id
        
        # Verify UserSquad roles were updated
        previous_owner_user_squad = session.query(UserSquad).filter(
            UserSquad.squad_id == squad.squad_id,
            UserSquad.user_id == sample_user.user_id
        ).first()
        assert previous_owner_user_squad.role == UserRole.MEMBER.value
        
        new_owner_user_squad = session.query(UserSquad).filter(
            UserSquad.squad_id == squad.squad_id,
            UserSquad.user_id == new_owner_id
        ).first()
        assert new_owner_user_squad.role == UserRole.OWNER.value

    def test_update_squad_owner_previous_owner_not_found(self, squad_service, session, sample_user):
        """Test updating squad owner when previous owner not found in UserSquad"""
        # Create squad using create_squad to ensure UserSquad entry is created
        squad = squad_service.create_squad("Test Squad", sample_user.user_id)
        new_owner_id = str(uuid.uuid4())
        
        # Delete the UserSquad entry for the current owner
        session.query(UserSquad).filter(
            UserSquad.squad_id == squad.squad_id,
            UserSquad.role == UserRole.OWNER.value
        ).delete()
        session.commit()
        
        with pytest.raises(ValueError, match="Previous owner not found in the squad"):
            squad_service.update_squad_owner(squad.squad_id, new_owner_id)

    def test_update_squad_owner_new_owner_not_found(self, squad_service, session, sample_user):
        """Test updating squad owner when new owner not found in UserSquad"""
        # Create squad using create_squad to ensure UserSquad entry is created
        squad = squad_service.create_squad("Test Squad", sample_user.user_id)
        new_owner_id = str(uuid.uuid4())
        
        with pytest.raises(ValueError, match="New owner not found in the squad"):
            squad_service.update_squad_owner(squad.squad_id, new_owner_id)

    def test_add_user_to_squad_success(self, squad_service, session, sample_user):
        """Test adding user to squad successfully"""
        # Create squad using create_squad to ensure UserSquad entry is created
        squad = squad_service.create_squad("Test Squad", sample_user.user_id)
        new_user_id = str(uuid.uuid4())
        
        updated_squad = squad_service.add_user_to_squad(squad.squad_id, new_user_id)
        
        assert updated_squad.squad_id == squad.squad_id
        
        # Verify UserSquad was created in database
        user_squad = session.query(UserSquad).filter(
            UserSquad.squad_id == squad.squad_id,
            UserSquad.user_id == new_user_id
        ).first()
        assert user_squad is not None
        assert user_squad.role == UserRole.MEMBER.value

    def test_add_user_to_squad_with_custom_role(self, squad_service, session, sample_user):
        """Test adding user to squad with custom role"""
        # Create squad using create_squad to ensure UserSquad entry is created
        squad = squad_service.create_squad("Test Squad", sample_user.user_id)
        new_user_id = str(uuid.uuid4())
        
        updated_squad = squad_service.add_user_to_squad(squad.squad_id, new_user_id, UserRole.ADMIN)
        
        assert updated_squad.squad_id == squad.squad_id
        
        # Verify UserSquad was created with correct role
        user_squad = session.query(UserSquad).filter(
            UserSquad.squad_id == squad.squad_id,
            UserSquad.user_id == new_user_id
        ).first()
        assert user_squad is not None
        assert user_squad.role == UserRole.ADMIN.value

    def test_add_user_to_squad_nonexistent_squad(self, squad_service):
        """Test adding user to non-existent squad"""
        fake_squad_id = str(uuid.uuid4())
        new_user_id = str(uuid.uuid4())
        
        with pytest.raises(ValueError, match="Squad not found"):
            squad_service.add_user_to_squad(fake_squad_id, new_user_id)

    def test_add_user_to_squad_duplicate_user(self, squad_service, session, sample_user):
        """Test adding user who is already in the squad"""
        # Create squad using create_squad to ensure UserSquad entry is created
        squad = squad_service.create_squad("Test Squad", sample_user.user_id)
        new_user_id = str(uuid.uuid4())
        
        # Add user first time
        squad_service.add_user_to_squad(squad.squad_id, new_user_id)
        
        # Try to add the same user again - should raise IntegrityError due to unique constraint
        with pytest.raises(Exception):  # IntegrityError or similar
            squad_service.add_user_to_squad(squad.squad_id, new_user_id)

    def test_remove_user_from_squad_success(self, squad_service, session, sample_user):
        """Test removing user from squad successfully"""
        # Create squad using create_squad to ensure UserSquad entry is created
        squad = squad_service.create_squad("Test Squad", sample_user.user_id)
        new_user_id = str(uuid.uuid4())
        
        # Add user first
        squad_service.add_user_to_squad(squad.squad_id, new_user_id)
        
        # Remove user
        updated_squad = squad_service.remove_user_from_squad(squad.squad_id, new_user_id)
        
        assert updated_squad.squad_id == squad.squad_id
        
        # Verify UserSquad was deleted from database
        user_squad = session.query(UserSquad).filter(
            UserSquad.squad_id == squad.squad_id,
            UserSquad.user_id == new_user_id
        ).first()
        assert user_squad is None

    def test_remove_user_from_squad_nonexistent_user(self, squad_service, session, sample_user):
        """Test removing non-existent user from squad"""
        # Create squad using create_squad to ensure UserSquad entry is created
        squad = squad_service.create_squad("Test Squad", sample_user.user_id)
        fake_user_id = str(uuid.uuid4())
        
        with pytest.raises(ValueError, match="User not found in the squad"):
            squad_service.remove_user_from_squad(squad.squad_id, fake_user_id)

    def test_remove_user_from_squad_nonexistent_squad(self, squad_service):
        """Test removing user from non-existent squad"""
        fake_squad_id = str(uuid.uuid4())
        fake_user_id = str(uuid.uuid4())
        
        with pytest.raises(ValueError, match="User not found in the squad"):
            squad_service.remove_user_from_squad(fake_squad_id, fake_user_id)

    def test_remove_owner_from_squad(self, squad_service, session, sample_user):
        """Test removing owner from squad (should work)"""
        # Create squad using create_squad to ensure UserSquad entry is created
        squad = squad_service.create_squad("Test Squad", sample_user.user_id)
        owner_id = sample_user.user_id
        
        updated_squad = squad_service.remove_user_from_squad(squad.squad_id, owner_id)
        
        assert updated_squad.squad_id == squad.squad_id
        
        # Verify UserSquad was deleted from database
        user_squad = session.query(UserSquad).filter(
            UserSquad.squad_id == squad.squad_id,
            UserSquad.user_id == owner_id
        ).first()
        assert user_squad is None

    def test_update_user_role_success(self, squad_service, session, sample_user):
        """Test updating user role successfully"""
        # Create squad using create_squad to ensure UserSquad entry is created
        squad = squad_service.create_squad("Test Squad", sample_user.user_id)
        new_user_id = str(uuid.uuid4())
        
        # Add user as member first
        squad_service.add_user_to_squad(squad.squad_id, new_user_id, UserRole.MEMBER)
        
        # Update role to admin
        updated_squad = squad_service.update_user_role(squad.squad_id, new_user_id, UserRole.ADMIN)
        
        assert updated_squad.squad_id == squad.squad_id
        
        # Verify role was updated in database
        user_squad = session.query(UserSquad).filter(
            UserSquad.squad_id == squad.squad_id,
            UserSquad.user_id == new_user_id
        ).first()
        assert user_squad.role == UserRole.ADMIN.value

    def test_update_user_role_to_owner_raises_error(self, squad_service, session, sample_user):
        """Test updating user role to owner raises error"""
        # Create squad using create_squad to ensure UserSquad entry is created
        squad = squad_service.create_squad("Test Squad", sample_user.user_id)
        new_user_id = str(uuid.uuid4())
        
        # Add user as member first
        squad_service.add_user_to_squad(squad.squad_id, new_user_id, UserRole.MEMBER)
        
        with pytest.raises(ValueError, match="Owner role cannot be updated, use update_squad_owner instead"):
            squad_service.update_user_role(squad.squad_id, new_user_id, UserRole.OWNER)

    def test_update_user_role_nonexistent_user(self, squad_service, session, sample_user):
        """Test updating role of non-existent user"""
        # Create squad using create_squad to ensure UserSquad entry is created
        squad = squad_service.create_squad("Test Squad", sample_user.user_id)
        fake_user_id = str(uuid.uuid4())
        
        with pytest.raises(ValueError, match="User not found in the squad"):
            squad_service.update_user_role(squad.squad_id, fake_user_id, UserRole.ADMIN)

    def test_update_user_role_nonexistent_squad(self, squad_service):
        """Test updating user role in non-existent squad"""
        fake_squad_id = str(uuid.uuid4())
        fake_user_id = str(uuid.uuid4())
        
        with pytest.raises(ValueError, match="User not found in the squad"):
            squad_service.update_user_role(fake_squad_id, fake_user_id, UserRole.ADMIN)

    def test_multiple_users_in_squad_management(self, squad_service, session, sample_user):
        """Test managing multiple users in a squad"""
        # Create squad using create_squad to ensure UserSquad entry is created
        squad = squad_service.create_squad("Test Squad", sample_user.user_id)
        user1_id = str(uuid.uuid4())
        user2_id = str(uuid.uuid4())
        user3_id = str(uuid.uuid4())
        
        # Add multiple users
        squad_service.add_user_to_squad(squad.squad_id, user1_id, UserRole.MEMBER)
        squad_service.add_user_to_squad(squad.squad_id, user2_id, UserRole.ADMIN)
        squad_service.add_user_to_squad(squad.squad_id, user3_id, UserRole.MEMBER)
        
        # Verify all users were added
        user_squads = session.query(UserSquad).filter(UserSquad.squad_id == squad.squad_id).all()
        assert len(user_squads) == 4  # 3 new users + 1 owner
        
        # Update one user's role
        squad_service.update_user_role(squad.squad_id, user1_id, UserRole.ADMIN)
        
        # Remove one user
        squad_service.remove_user_from_squad(squad.squad_id, user2_id)
        
        # Verify final state
        final_user_squads = session.query(UserSquad).filter(UserSquad.squad_id == squad.squad_id).all()
        assert len(final_user_squads) == 3  # 2 remaining users + 1 owner
        
        # Verify specific roles
        user1_squad = session.query(UserSquad).filter(
            UserSquad.squad_id == squad.squad_id,
            UserSquad.user_id == user1_id
        ).first()
        assert user1_squad.role == UserRole.ADMIN.value
        
        # Verify user2 was removed
        user2_squad = session.query(UserSquad).filter(
            UserSquad.squad_id == squad.squad_id,
            UserSquad.user_id == user2_id
        ).first()
        assert user2_squad is None
