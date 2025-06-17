import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import uuid
from datetime import datetime, timezone

from app.models import Squad, Player, Match, Team, TeamPlayer, ScoreHistory, User, Base
from app.services import PlayerService, SquadService
from app.entities import PlayerData, PlayerDetailData
from app.constants import Position


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


@pytest.fixture
def sample_match_with_score_history(session, sample_squad, sample_players):
    """Create a match with teams, players, and score history for testing"""
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
    
    # Create score history entries
    score_history1 = ScoreHistory(
        match_id=match.match_id,
        player_id=sample_players[0].player_id,
        previous_score=sample_players[0].score,
        new_score=sample_players[0].score + 2.0,
        delta=2.0
    )
    score_history2 = ScoreHistory(
        match_id=match.match_id,
        player_id=sample_players[1].player_id,
        previous_score=sample_players[1].score,
        new_score=sample_players[1].score - 2.0,
        delta=-2.0
    )
    session.add_all([score_history1, score_history2])
    session.commit()
    
    return match, team1, team2, score_history1, score_history2


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

    def test_get_player_data_for_match_with_history(self, player_service, sample_match_with_score_history, session):
        """Test getting player data for a match with existing score history"""
        match, team1, team2, score_history1, score_history2 = sample_match_with_score_history
        
        player_id = score_history1.player_id
        player_data = player_service.get_player_data_for_match(player_id, match.match_id)
        
        assert player_data is not None
        assert isinstance(player_data, PlayerData)
        assert player_data.player_id == player_id
        # Should return previous_score from score history, not current score
        assert player_data.score == score_history1.previous_score

    def test_get_player_data_for_match_without_history(self, player_service, sample_player):
        """Test getting player data for a match without score history"""
        fake_match_id = str(uuid.uuid4())
        player_data = player_service.get_player_data_for_match(sample_player.player_id, fake_match_id)
        
        assert player_data is not None
        assert isinstance(player_data, PlayerData)
        assert player_data.player_id == sample_player.player_id
        # Should return current score since no score history exists
        assert player_data.score == sample_player.score

    def test_get_player_data_for_match_nonexistent_player(self, player_service):
        """Test getting player data for a match with non-existent player"""
        fake_player_id = str(uuid.uuid4())
        fake_match_id = str(uuid.uuid4())
        player_data = player_service.get_player_data_for_match(fake_player_id, fake_match_id)
        
        assert player_data is None

    def test_update_player_score_with_match_id_new_history(self, player_service, sample_player, session):
        """Test updating player score with match_id creates new score history"""
        match_id = str(uuid.uuid4())
        original_score = sample_player.score
        new_score = 25.5
        
        # Ensure no existing score history
        existing_history = session.query(ScoreHistory).filter(
            ScoreHistory.player_id == sample_player.player_id,
            ScoreHistory.match_id == match_id
        ).first()
        assert existing_history is None
        
        updated_player = player_service.update_player_score(sample_player.player_id, new_score, match_id)
        
        assert updated_player is not None
        assert updated_player.score == new_score
        
        # Check that score history was created
        score_history = session.query(ScoreHistory).filter(
            ScoreHistory.player_id == sample_player.player_id,
            ScoreHistory.match_id == match_id
        ).first()
        
        assert score_history is not None
        assert score_history.previous_score == original_score
        assert score_history.new_score == new_score
        assert score_history.delta == new_score - original_score

    def test_update_player_score_with_match_id_existing_history(self, player_service, sample_match_with_score_history, session):
        """Test updating player score with match_id updates existing score history"""
        match, team1, team2, score_history1, score_history2 = sample_match_with_score_history
        
        player_id = score_history1.player_id
        match_id = match.match_id
        new_score = 30.0
        original_previous_score = score_history1.previous_score
        
        updated_player = player_service.update_player_score(player_id, new_score, match_id)
        
        assert updated_player is not None
        assert updated_player.score == new_score
        
        # Check that existing score history was updated
        session.refresh(score_history1)
        assert score_history1.new_score == new_score
        assert score_history1.delta == new_score - original_previous_score

    def test_update_player_score_without_match_id(self, player_service, sample_player):
        """Test updating player score without match_id (no score history changes)"""
        new_score = 22.0
        
        updated_player = player_service.update_player_score(sample_player.player_id, new_score)
        
        assert updated_player is not None
        assert updated_player.score == new_score

    def test_recalculate_and_update_score_with_history(self, player_service, sample_match_with_score_history, session):
        """Test recalculating player score using score history"""
        match, team1, team2, score_history1, score_history2 = sample_match_with_score_history
        
        player_id = score_history1.player_id
        player = session.query(Player).filter(Player.player_id == player_id).first()
        original_base_score = player.base_score
        
        updated_player = player_service.recalculate_and_update_score(player_id)
        
        assert updated_player is not None
        assert isinstance(updated_player, PlayerData)
        
        # Score should be base_score + sum of all deltas from score history
        expected_score = original_base_score + score_history1.delta
        assert updated_player.score == expected_score

    def test_recalculate_and_update_score_multiple_matches(self, player_service, sample_squad, sample_player, session):
        """Test recalculating player score with multiple match histories"""
        player_id = sample_player.player_id
        
        # Create multiple matches with score histories
        match1 = Match(match_id=str(uuid.uuid4()), squad_id=sample_squad.squad_id, created_at=datetime.now(timezone.utc))
        match2 = Match(match_id=str(uuid.uuid4()), squad_id=sample_squad.squad_id, created_at=datetime.now(timezone.utc))
        session.add_all([match1, match2])
        session.commit()
        
        # Create score histories in chronological order
        history1 = ScoreHistory(
            match_id=match1.match_id,
            player_id=player_id,
            previous_score=15.0,
            new_score=17.0,
            delta=2.0
        )
        history2 = ScoreHistory(
            match_id=match2.match_id,
            player_id=player_id,
            previous_score=17.0,
            new_score=15.5,
            delta=-1.5
        )
        session.add_all([history1, history2])
        session.commit()
        
        updated_player = player_service.recalculate_and_update_score(player_id)
        
        assert updated_player is not None
        # Score should be base_score + delta1 + delta2 = 15 + 2.0 + (-1.5) = 15.5
        expected_score = sample_player.base_score + 2.0 + (-1.5)
        assert updated_player.score == expected_score

    def test_recalculate_and_update_score_no_history(self, player_service, sample_player):
        """Test recalculating player score with no score history"""
        updated_player = player_service.recalculate_and_update_score(sample_player.player_id)
        
        assert updated_player is not None
        # Score should remain as base_score since no history exists
        assert updated_player.score == sample_player.base_score

    def test_update_old_match_preserves_newer_matches_deltas(self, player_service, sample_squad, sample_player, session):
        """Test that updating an old match score preserves deltas from newer matches"""
        player_id = sample_player.player_id
        base_score = sample_player.base_score  # Should be 15
        
        # Create three matches in chronological order
        from datetime import timedelta
        base_time = datetime.now(timezone.utc)
        
        match1 = Match(
            match_id=str(uuid.uuid4()), 
            squad_id=sample_squad.squad_id, 
            created_at=base_time
        )
        match2 = Match(
            match_id=str(uuid.uuid4()), 
            squad_id=sample_squad.squad_id, 
            created_at=base_time + timedelta(hours=1)
        )
        match3 = Match(
            match_id=str(uuid.uuid4()), 
            squad_id=sample_squad.squad_id, 
            created_at=base_time + timedelta(hours=2)
        )
        session.add_all([match1, match2, match3])
        session.commit()
        
        # Create initial score histories in chronological order
        # Match 1: +10 delta (base 15 -> 25)
        history1 = ScoreHistory(
            match_id=match1.match_id,
            player_id=player_id,
            previous_score=base_score,  # 15
            new_score=base_score + 10,  # 25
            delta=10.0
        )
        
        # Match 2: +5 delta (25 -> 30)
        history2 = ScoreHistory(
            match_id=match2.match_id,
            player_id=player_id,
            previous_score=base_score + 10,  # 25
            new_score=base_score + 15,  # 30
            delta=5.0
        )
        
        # Match 3: -3 delta (30 -> 27)
        history3 = ScoreHistory(
            match_id=match3.match_id,
            player_id=player_id,
            previous_score=base_score + 15,  # 30
            new_score=base_score + 12,  # 27
            delta=-3.0
        )
        
        session.add_all([history1, history2, history3])
        session.commit()
        
        # Set player's current score to reflect all matches
        player = session.query(Player).filter(Player.player_id == player_id).first()
        player.score = base_score + 12  # 27 (base + 10 + 5 - 3)
        session.commit()
        
        # Verify initial state
        initial_player = player_service.get_player(player_id)
        assert initial_player.score == base_score + 12  # 27
        
        # NOW THE EDGE CASE: Update the OLD match (match1) score
        # Change match1 delta from +10 to +15
        old_match_new_score = base_score + 15  # 30 instead of 25
        
        updated_player = player_service.update_player_score(player_id, old_match_new_score, match1.match_id)
        
        # Verify the update worked correctly
        assert updated_player is not None
        
        # Expected calculation:
        # base_score (15) + new_match1_delta (15) + match2_delta (5) + match3_delta (-3) = 32
        expected_final_score = base_score + 15 + 5 + (-3)  # 15 + 15 + 5 - 3 = 32
        assert updated_player.score == expected_final_score
        
        # Verify score history was updated correctly for match1
        updated_history1 = session.query(ScoreHistory).filter(
            ScoreHistory.match_id == match1.match_id,
            ScoreHistory.player_id == player_id
        ).first()
        assert updated_history1.new_score == old_match_new_score  # 30
        assert updated_history1.delta == 15.0  # Updated delta
        assert updated_history1.previous_score == base_score  # Should remain 15
        
        # Verify other matches' score histories are unchanged
        unchanged_history2 = session.query(ScoreHistory).filter(
            ScoreHistory.match_id == match2.match_id,
            ScoreHistory.player_id == player_id
        ).first()
        assert unchanged_history2.delta == 5.0  # Should be unchanged
        
        unchanged_history3 = session.query(ScoreHistory).filter(
            ScoreHistory.match_id == match3.match_id,
            ScoreHistory.player_id == player_id
        ).first()
        assert unchanged_history3.delta == -3.0  # Should be unchanged
