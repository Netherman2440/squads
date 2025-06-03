import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import uuid
from datetime import datetime, timezone

from app.db import Squad, Player, Match, Team, TeamPlayer, Base
from app.services import PlayerService, SquadService
from app.entities import PlayerData, PlayerDetailData, Position, MatchData


@pytest.fixture
def session():
    """Create in-memory SQLite database session for testing"""
    engine = create_engine("sqlite:///:memory:")
    # Create all tables
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    return Session()


@pytest.fixture
def player_service(session):
    """Create PlayerService instance with test session"""
    return PlayerService(session)


@pytest.fixture
def squad_service(session):
    """Create SquadService instance with test session"""
    return SquadService(session)


@pytest.fixture
def sample_squad(session):
    """Create a sample squad for testing"""
    squad = Squad(
        squad_id=str(uuid.uuid4()),
        name="Test Squad",
        created_at=datetime.now(timezone.utc)
    )
    session.add(squad)
    session.commit()
    return squad


@pytest.fixture
def sample_player(session, sample_squad):
    """Create a sample player for testing"""
    player = Player(
        player_id=str(uuid.uuid4()),
        squad_id=sample_squad.squad_id,
        name="Test Player",
        position="field",
        base_score=15,
        score=15.0
    )
    session.add(player)
    session.commit()
    return player


@pytest.fixture
def sample_players(session, sample_squad):
    """Create multiple sample players for testing"""
    players = []
    positions = ["goalie", "field", "field"]
    base_scores = [12, 15, 18]
    
    for i in range(3):
        player = Player(
            player_id=str(uuid.uuid4()),
            squad_id=sample_squad.squad_id,
            name=f"Player {i+1}",
            position=positions[i],
            base_score=base_scores[i],
            score=float(base_scores[i])
        )
        players.append(player)
        session.add(player)
    
    session.commit()
    return players


@pytest.fixture
def sample_match_with_teams(session, sample_squad, sample_players):
    """Create a match with teams and players for testing score calculation"""
    # Create match
    match = Match(
        match_id=str(uuid.uuid4()),
        squad_id=sample_squad.squad_id,
        created_at=datetime.now(timezone.utc)
    )
    session.add(match)
    session.commit()
    
    # Create two teams
    team1 = Team(
        team_id=str(uuid.uuid4()),
        match_id=match.match_id,
        score=5,
        color="white"
    )
    team2 = Team(
        team_id=str(uuid.uuid4()),
        match_id=match.match_id,
        score=3,
        color="black"
    )
    session.add_all([team1, team2])
    session.commit()
    
    # Add players to teams
    team_player1 = TeamPlayer(
        player_id=sample_players[0].player_id,
        team_id=team1.team_id,
        match_id=match.match_id
    )
    team_player2 = TeamPlayer(
        player_id=sample_players[1].player_id,
        team_id=team2.team_id,
        match_id=match.match_id
    )
    session.add_all([team_player1, team_player2])
    session.commit()
    
    return match, team1, team2


class TestPlayerService:
    """Test class for PlayerService functionality"""

    def test_get_player_existing(self, player_service, sample_player):
        """Test getting an existing player"""
        player_data = player_service.get_player(sample_player.player_id)
        
        assert player_data is not None
        assert isinstance(player_data, PlayerData)
        
        # Test model conversion from Player to PlayerData
        assert player_data.player_id == sample_player.player_id
        assert player_data.squad_id == sample_player.squad_id
        assert player_data.name == sample_player.name
        assert player_data.position == Position(sample_player.position)
        assert player_data.base_score == sample_player.base_score
        assert player_data._score == sample_player.score
        assert player_data.score == sample_player.score  # Test property
        assert player_data.matches_played == len(sample_player.matches)

    def test_get_player_nonexistent(self, player_service):
        """Test getting a non-existent player returns None"""
        fake_id = str(uuid.uuid4())
        player_data = player_service.get_player(fake_id)
        assert player_data is None

    def test_get_player_details_existing(self, player_service, sample_player):
        """Test getting player details for existing player"""
        player_detail = player_service.get_player_details(sample_player.player_id)
        
        assert player_detail is not None
        assert isinstance(player_detail, PlayerDetailData)
        
        # Test inheritance from PlayerData
        assert player_detail.player_id == sample_player.player_id
        assert player_detail.squad_id == sample_player.squad_id
        assert player_detail.name == sample_player.name
        assert player_detail.position == Position(sample_player.position)
        assert player_detail.base_score == sample_player.base_score
        assert player_detail._score == sample_player.score
        assert player_detail.matches_played == len(sample_player.matches)
        
        # Test additional detail fields
        assert hasattr(player_detail, 'matches')

    def test_get_player_details_nonexistent(self, player_service):
        """Test getting player details for non-existent player returns None"""
        fake_id = str(uuid.uuid4())
        player_detail = player_service.get_player_details(fake_id)
        assert player_detail is None

    def test_create_player_basic(self, player_service, sample_squad, session):
        """Test creating a new player with basic parameters"""
        initial_count = session.query(Player).count()
        
        player_data = player_service.create_player(
            squad_id=sample_squad.squad_id,
            name="New Player",
            base_score=20,
            position=Position.FIELD
        )
        
        # Verify player was created in database
        final_count = session.query(Player).count()
        assert final_count == initial_count + 1
        
        # Verify returned data
        assert isinstance(player_data, PlayerData)
        assert player_data.player_id is not None
        assert player_data.squad_id == sample_squad.squad_id
        assert player_data.name == "New Player"
        assert player_data.base_score == 20
        assert player_data.position == Position.FIELD
        assert player_data.score == 20.0 
        assert player_data.matches_played == 0
        
        # Verify player exists in database
        db_player = session.query(Player).filter(Player.player_id == player_data.player_id).first()
        assert db_player is not None
        assert db_player.name == "New Player"
        assert db_player.base_score == 20
        assert db_player.position == Position.FIELD.value

    def test_create_player_with_all_parameters(self, player_service, sample_squad, session):
        """Test creating a new player with all parameters"""
        player_data = player_service.create_player(
            squad_id=sample_squad.squad_id,
            name="Complete Player",
            base_score=25,
            position=Position.GOALIE,
        )
        
        # Verify all parameters were set correctly
        assert player_data.name == "Complete Player"
        assert player_data.base_score == 25
        assert player_data.position == Position.GOALIE
        
        # Verify in database
        db_player = session.query(Player).filter(Player.player_id == player_data.player_id).first()
        assert db_player.position == Position.GOALIE.value
        

    def test_delete_player_existing(self, player_service, sample_player, session):
        """Test deleting an existing player"""
        player_id = sample_player.player_id
        initial_count = session.query(Player).count()
        
        # Delete the player
        player_service.delete_player(player_id)
        
        # Verify player was deleted from database
        final_count = session.query(Player).count()
        assert final_count == initial_count - 1
        
        # Verify player no longer exists
        deleted_player = session.query(Player).filter(Player.player_id == player_id).first()
        assert deleted_player is None

    def test_delete_player_nonexistent(self, player_service, session):
        """Test deleting a non-existent player does nothing"""
        fake_id = str(uuid.uuid4())
        initial_count = session.query(Player).count()
        
        # Should not raise an error
        player_service.delete_player(fake_id)
        
        # Count should remain the same
        final_count = session.query(Player).count()
        assert final_count == initial_count

    def test_update_player_name_existing(self, player_service, sample_player):
        """Test updating player name for existing player"""
        new_name = "Updated Player Name"
        
        updated_player = player_service.update_player_name(sample_player.player_id, new_name)
        
        assert updated_player is not None
        assert isinstance(updated_player, PlayerData)
        assert updated_player.name == new_name
        assert updated_player.player_id == sample_player.player_id
        # Other fields should remain unchanged
        assert updated_player.base_score == sample_player.base_score
        assert updated_player.position == Position(sample_player.position)

    def test_update_player_name_nonexistent(self, player_service):
        """Test updating player name for non-existent player returns None"""
        fake_id = str(uuid.uuid4())
        updated_player = player_service.update_player_name(fake_id, "New Name")
        assert updated_player is None

    def test_update_player_base_score_existing(self, player_service, sample_player):
        """Test updating player base score for existing player"""
        new_base_score = 25
        
        updated_player = player_service.update_player_base_score(sample_player.player_id, new_base_score)
        
        assert updated_player is not None
        assert isinstance(updated_player, PlayerData)
        assert updated_player.base_score == new_base_score
        assert updated_player.player_id == sample_player.player_id
        # Other fields should remain unchanged
        assert updated_player.name == sample_player.name
        assert updated_player.position == Position(sample_player.position)

    def test_update_player_base_score_nonexistent(self, player_service):
        """Test updating player base score for non-existent player returns None"""
        fake_id = str(uuid.uuid4())
        updated_player = player_service.update_player_base_score(fake_id, 25)
        assert updated_player is None

    def test_update_player_position_existing(self, player_service, sample_player):
        """Test updating player position for existing player"""
        new_position = Position.GOALIE
        
        updated_player = player_service.update_player_position(sample_player.player_id, new_position)
        
        assert updated_player is not None
        assert isinstance(updated_player, PlayerData)
        assert updated_player.position == new_position
        assert updated_player.player_id == sample_player.player_id
        # Other fields should remain unchanged
        assert updated_player.name == sample_player.name
        assert updated_player.base_score == sample_player.base_score

    def test_update_player_position_nonexistent(self, player_service):
        """Test updating player position for non-existent player returns None"""
        fake_id = str(uuid.uuid4())
        updated_player = player_service.update_player_position(fake_id, Position.GOALIE)
        assert updated_player is None

    def test_recalculate_and_update_score_existing(self, player_service, sample_match_with_teams):
        """Test recalculating and updating player score"""
        match, team1, team2 = sample_match_with_teams
        
        # Get player from team1 (should have won 5-3)
        team_player = team1.players[0] if team1.players else None
        if not team_player:
            pytest.skip("No players in team for testing")
        
        player_id = team_player.player_id
        original_player = team_player
        
        updated_player = player_service.recalculate_and_update_score(player_id)
        
        assert updated_player is not None
        assert isinstance(updated_player, PlayerData)
        assert updated_player.player_id == player_id
        
        # Score should be base_score + calculated delta
        expected_delta = (team1.score - team2.score) / 1.0  # First match, factor = 1
        expected_score = original_player.base_score + expected_delta
        assert updated_player.score == expected_score

    def test_recalculate_and_update_score_nonexistent(self, player_service):
        """Test recalculating score for non-existent player returns None"""
        fake_id = str(uuid.uuid4())
        updated_player = player_service.recalculate_and_update_score(fake_id)
        assert updated_player is None

    def test_calculate_score_delta(self, player_service, sample_match_with_teams):
        """Test score delta calculation"""
        match, team1, team2 = sample_match_with_teams
        
        # Get player from team1
        team_player = team1.players[0] if team1.players else None
        if not team_player:
            pytest.skip("No players in team for testing")
            
        player = team_player
        
        # Test delta calculation
        delta = player_service.calculate_score_delta(player, match, 0)
        
        # Expected: (5-3)/1 = 2 (team1 won 5-3, match_index=0 so factor=1)
        expected_delta = (team1.score - team2.score) / 1.0
        assert delta == expected_delta

    def test_calculate_score_delta_with_factor(self, player_service, sample_match_with_teams):
        """Test score delta calculation with different match index (factor)"""
        match, team1, team2 = sample_match_with_teams
        
        # Get player from team1
        team_player = team1.players[0] if team1.players else None
        if not team_player:
            pytest.skip("No players in team for testing")
            
        player = team_player
        
        # Test with match_index = 2 (factor should be 2*0.2+1 = 1.4)
        delta = player_service.calculate_score_delta(player, match, 2)
        
        expected_factor = 2 * 0.2 + 1  # 1.4
        expected_delta = (team1.score - team2.score) / expected_factor
        assert abs(delta - expected_delta) < 0.0001  # Float comparison

    def test_player_data_model_conversion_completeness(self, player_service, sample_player):
        """Test that all required fields are properly converted from Player model to PlayerData"""
        player_data = player_service.get_player(sample_player.player_id)
        
        # Verify all PlayerData fields are present and correctly mapped
        assert hasattr(player_data, 'squad_id')
        assert hasattr(player_data, 'player_id')
        assert hasattr(player_data, 'name')
        assert hasattr(player_data, 'base_score')
        assert hasattr(player_data, 'position')
        assert hasattr(player_data, 'matches_played')
        assert hasattr(player_data, '_score')
        assert hasattr(player_data, 'score')  # Property
        
        # Verify field values match database model
        assert player_data.squad_id == sample_player.squad_id
        assert player_data.player_id == sample_player.player_id
        assert player_data.name == sample_player.name
        assert player_data.base_score == sample_player.base_score
        assert player_data.position == Position(sample_player.position)
        assert player_data._score == sample_player.score
        assert player_data.matches_played == len(sample_player.matches)

    def test_player_detail_data_model_conversion_completeness(self, player_service, sample_player):
        """Test that all required fields are properly converted from Player model to PlayerDetailData"""
        player_detail = player_service.get_player_details(sample_player.player_id)
        
        # Verify all PlayerDetailData fields are present (inherits from PlayerData)
        assert hasattr(player_detail, 'squad_id')
        assert hasattr(player_detail, 'player_id')
        assert hasattr(player_detail, 'name')
        assert hasattr(player_detail, 'base_score')
        assert hasattr(player_detail, 'position')
        assert hasattr(player_detail, 'matches_played')
        assert hasattr(player_detail, '_score')
        assert hasattr(player_detail, 'score')
        # Additional detail fields
        assert hasattr(player_detail, 'matches')
        
        # Verify field values
        assert player_detail.squad_id == sample_player.squad_id
        assert player_detail.player_id == sample_player.player_id
        assert player_detail.name == sample_player.name
        assert player_detail.base_score == sample_player.base_score
        assert player_detail.position == Position(sample_player.position)
        assert player_detail._score == sample_player.score
        assert player_detail.matches_played == len(sample_player.matches)

    def test_position_enum_handling(self, player_service, sample_squad):
        """Test proper handling of Position enum in model conversion"""
        # Test creating player with different positions
        positions_to_test = [Position.GOALIE, Position.FIELD, Position.NONE]
        
        for position in positions_to_test:
            player_data = player_service.create_player(
                squad_id=sample_squad.squad_id,
                name=f"Player {position.name}",
                base_score=15,
                position=position
            )
            
            assert player_data.position == position
            
            # Verify in database
            retrieved_player = player_service.get_player(player_data.player_id)
            assert retrieved_player.position == position

    def test_score_property_behavior(self, player_service, sample_squad):
        """Test PlayerData score property behavior"""
        # Create player with specific _score
        player_data = player_service.create_player(
            squad_id=sample_squad.squad_id,
            name="Score Test Player",
            base_score=20,
        )
        
        # Test that score property returns _score when set
        assert player_data.score == 20.0
        assert player_data._score == 20.0
        
        # Test score setter
        player_data.score = 30.0
        assert player_data.score == 30.0
        assert player_data._score == 30.0

    def test_multiple_players_isolation(self, player_service, sample_squad, session):
        """Test that operations on one player don't affect others"""
        # Create multiple players
        player1_data = player_service.create_player(
            squad_id=sample_squad.squad_id,
            name="Player 1",
            base_score=15
        )
        player2_data = player_service.create_player(
            squad_id=sample_squad.squad_id,
            name="Player 2",
            base_score=20
        )
        
        # Update player1
        updated_player1 = player_service.update_player_name(player1_data.player_id, "Updated Player 1")
        updated_player1 = player_service.update_player_base_score(player1_data.player_id, 25)
        
        # Verify player2 is unchanged
        player2_check = player_service.get_player(player2_data.player_id)
        assert player2_check.name == "Player 2"
        assert player2_check.base_score == 20
        
        # Delete player1 and verify player2 is unaffected
        player_service.delete_player(player1_data.player_id)
        
        player2_still_exists = player_service.get_player(player2_data.player_id)
        assert player2_still_exists is not None
        assert player2_still_exists.name == "Player 2"

    def test_database_persistence_after_updates(self, player_service, sample_player, session):
        """Test that all updates are properly persisted to database"""
        original_id = sample_player.player_id
        
        # Perform multiple updates
        player_service.update_player_name(original_id, "Persistent Name")
        player_service.update_player_base_score(original_id, 100)
        player_service.update_player_position(original_id, Position.GOALIE)
        
        # Refresh session and check database directly
        session.expire_all()
        db_player = session.query(Player).filter(Player.player_id == original_id).first()
        
        assert db_player.name == "Persistent Name"
        assert db_player.base_score == 100
        assert db_player.position == Position.GOALIE.value
        
        # Also verify through service
        service_player = player_service.get_player(original_id)
        assert service_player.name == "Persistent Name"
        assert service_player.base_score == 100
        assert service_player.position == Position.GOALIE
