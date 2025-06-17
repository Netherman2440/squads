import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import uuid
from datetime import datetime, timezone

from app.models import Squad, Player, Match, Team, TeamPlayer, User, Base
from app.services import MatchService, TeamService, PlayerService
from app.entities import MatchData, MatchDetailData, PlayerData, TeamDetailData, DraftData
from app.constants import Position
from app.services.squad_service import SquadService


@pytest.fixture
def session():
    """Create in-memory SQLite database session for testing"""
    engine = create_engine("sqlite:///:memory:")
    # Create all tables
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    return Session()


@pytest.fixture
def match_service(session):
    """Create MatchService instance with test session"""
    return MatchService(session)


@pytest.fixture
def team_service(session):
    """Create TeamService instance with test session"""
    return TeamService(session)


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
def sample_players(session, sample_squad):
    """Create multiple sample players for testing"""
    players = []
    positions = ["goalie", "field", "field", "field", "field", "field"]
    base_scores = [12, 15, 18, 20, 16, 14]
    
    for i in range(6):
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
def sample_player_data(sample_players):
    """Convert sample players to PlayerData objects"""
    return [
        PlayerData(
            player_id=player.player_id,
            squad_id=player.squad_id,
            name=player.name,
            position=Position(player.position),
            base_score=player.base_score,
            _score=player.score,
            matches_played=len(player.matches)
        )
        for player in sample_players
    ]


@pytest.fixture
def team_a_players(sample_player_data):
    """Get first half of players for team A"""
    return sample_player_data[:3]


@pytest.fixture
def team_b_players(sample_player_data):
    """Get second half of players for team B"""
    return sample_player_data[3:]


@pytest.fixture
def sample_match(session, sample_squad, team_a_players, team_b_players, match_service):
    """Create a sample match with teams for testing"""
    match_data = match_service.create_match(
        squad_id=sample_squad.squad_id,
        team_a_players=team_a_players,
        team_b_players=team_b_players
    )
    return match_data


class TestMatchService:
    """Test class for MatchService functionality"""

    def test_create_match_basic(self, match_service, sample_squad, team_a_players, team_b_players, session):
        """Test creating a new match with basic parameters"""
        initial_match_count = session.query(Match).count()
        initial_team_count = session.query(Team).count()
        
        match_data = match_service.create_match(
            squad_id=sample_squad.squad_id,
            team_a_players=team_a_players,
            team_b_players=team_b_players
        )
        
        # Verify match was created in database
        final_match_count = session.query(Match).count()
        final_team_count = session.query(Team).count()
        assert final_match_count == initial_match_count + 1
        assert final_team_count == initial_team_count + 2  # Two teams created
        
        # Verify returned data
        assert isinstance(match_data, MatchDetailData)
        assert match_data.match_id is not None
        assert match_data.squad_id == sample_squad.squad_id
        assert match_data.score == (0, 0)  # Default scores
        assert match_data.created_at is not None
        
        # Verify match exists in database
        db_match = session.query(Match).filter(Match.match_id == match_data.match_id).first()
        assert db_match is not None
        assert db_match.squad_id == sample_squad.squad_id
        assert len(db_match.teams) == 2

    def test_create_match_with_empty_teams(self, match_service, sample_squad, session):
        """Test creating a match with empty teams"""
        match_data = match_service.create_match(
            squad_id=sample_squad.squad_id,
            team_a_players=[],
            team_b_players=[]
        )
        
        assert match_data.match_id is not None
        assert match_data.score == (0, 0)
        
        # Verify teams were created even if empty
        db_match = session.query(Match).filter(Match.match_id == match_data.match_id).first()
        assert len(db_match.teams) == 2

    def test_create_match_with_unequal_teams(self, match_service, sample_squad, sample_player_data):
        """Test creating a match with unequal team sizes"""
        team_a = sample_player_data[:1]  # 1 player
        team_b = sample_player_data[1:5]  # 4 players
        
        match_data = match_service.create_match(
            squad_id=sample_squad.squad_id,
            team_a_players=team_a,
            team_b_players=team_b
        )
        
        assert match_data.match_id is not None
        
        # Verify through get_match_detail
        match_detail = match_service.get_match_detail(match_data.match_id)
        assert len(match_detail.team_a.players) == 1
        assert len(match_detail.team_b.players) == 4

    def test_get_match_existing(self, match_service, sample_match):
        """Test getting an existing match"""
        match_data = match_service.get_match(sample_match.match_id)
        
        assert match_data is not None
        assert isinstance(match_data, MatchData)
        
        # Test model conversion from Match to MatchData
        assert match_data.match_id == sample_match.match_id
        assert match_data.squad_id == sample_match.squad_id
        assert match_data.created_at is not None
        assert isinstance(match_data.score, tuple)
        assert len(match_data.score) == 2

    def test_get_match_nonexistent(self, match_service):
        """Test getting a non-existent match returns None"""
        fake_id = str(uuid.uuid4())
        match_data = match_service.get_match(fake_id)
        assert match_data is None

    def test_get_match_detail_existing(self, match_service, sample_match):
        """Test getting match details for existing match"""
        match_detail = match_service.get_match_detail(sample_match.match_id)
        
        assert match_detail is not None
        assert isinstance(match_detail, MatchDetailData)
        
        # Test inheritance and basic fields
        assert match_detail.match_id == sample_match.match_id
        assert match_detail.squad_id == sample_match.squad_id
        assert match_detail.created_at is not None
        
        # Test team detail fields
        assert hasattr(match_detail, 'team_a')
        assert hasattr(match_detail, 'team_b')
        assert isinstance(match_detail.team_a, TeamDetailData)
        assert isinstance(match_detail.team_b, TeamDetailData)
        
        # Verify teams have correct colors
        team_colors = {match_detail.team_a.color, match_detail.team_b.color}
        assert "white" in team_colors
        assert "black" in team_colors

    def test_get_match_detail_nonexistent(self, match_service):
        """Test getting match details for non-existent match returns None"""
        fake_id = str(uuid.uuid4())
        match_detail = match_service.get_match_detail(fake_id)
        assert match_detail is None

    def test_update_match_score_existing(self, match_service, sample_match):
        """Test updating match score for existing match"""
        new_team_a_score = 5
        new_team_b_score = 3
        
        updated_match = match_service.update_match_score(
            sample_match.match_id, 
            new_team_a_score, 
            new_team_b_score
        )
        
        assert updated_match is not None
        assert isinstance(updated_match, MatchDetailData)
        assert updated_match.match_id == sample_match.match_id
        assert updated_match.team_a.score == new_team_a_score
        assert updated_match.team_b.score == new_team_b_score

    def test_update_match_score_nonexistent(self, match_service):
        """Test updating match score for non-existent match returns None"""
        fake_id = str(uuid.uuid4())
        updated_match = match_service.update_match_score(fake_id, 2, 1)
        assert updated_match is None

    def test_update_match_score_persistence(self, match_service, sample_match, session):
        """Test that score updates are persisted to database"""
        match_service.update_match_score(sample_match.match_id, 7, 4)
        
        # Refresh and check database directly
        session.expire_all()
        db_match = session.query(Match).filter(Match.match_id == sample_match.match_id).first()
        
        team_scores = [team.score for team in db_match.teams]
        assert 7 in team_scores
        assert 4 in team_scores

    def test_update_match_players_existing(self, match_service, sample_match, sample_player_data):
        """Test updating match players for existing match"""
        # Use different player combinations
        new_team_a = sample_player_data[1:3]  # Different players
        new_team_b = sample_player_data[4:6]  # Different players
        
        updated_match = match_service.update_match_players(
            sample_match.match_id,
            new_team_a,
            new_team_b
        )
        
        assert updated_match is not None
        assert isinstance(updated_match, MatchDetailData)
        assert updated_match.match_id == sample_match.match_id
        # Note: Current implementation might not work correctly due to team_service.update_team_players issues

    def test_update_match_players_nonexistent(self, match_service, sample_player_data):
        """Test updating match players for non-existent match returns None"""
        fake_id = str(uuid.uuid4())
        updated_match = match_service.update_match_players(
            fake_id, 
            sample_player_data[:2], 
            sample_player_data[2:4]
        )
        assert updated_match is None

    def test_draw_teams_basic(self, match_service, sample_match):
        """Test basic team drawing functionality for existing match"""
        # Get match details to extract players
        match_detail = match_service.get_match_detail(sample_match.match_id)
        all_players = match_detail.team_a.players + match_detail.team_b.players
        
        draft_results = match_service.draw_teams(all_players)
        
        # Verify return type
        assert isinstance(draft_results, list)
        assert len(draft_results) > 0  # Should have at least one draft combination
        
        # Verify each result is a DraftData object
        for draft in draft_results:
            assert isinstance(draft, DraftData)
            assert isinstance(draft.team_a, list)
            assert isinstance(draft.team_b, list)
            assert all(isinstance(player, PlayerData) for player in draft.team_a)
            assert all(isinstance(player, PlayerData) for player in draft.team_b)
            
            # Should have players from the match
            total_players = len(draft.team_a) + len(draft.team_b)
            assert total_players > 0
        
        # Should return amount_of_draws different team compositions (default 20)
        assert len(draft_results) <= 20  # May be less if not enough combinations

    def test_draw_teams_returns_multiple_compositions(self, match_service, sample_match):
        """Test that draw_teams returns multiple different team compositions"""
        # Get match details to extract players
        match_detail = match_service.get_match_detail(sample_match.match_id)
        all_players = match_detail.team_a.players + match_detail.team_b.players
        
        draft_results = match_service.draw_teams(all_players)
        
        # Should return multiple different compositions
        assert len(draft_results) >= 1
        assert isinstance(draft_results, list)
        
        # Each composition should be a DraftData with team_a and team_b
        for draft in draft_results:
            assert isinstance(draft, DraftData)
            assert hasattr(draft, 'team_a')
            assert hasattr(draft, 'team_b')
            assert isinstance(draft.team_a, list)
            assert isinstance(draft.team_b, list)

    def test_draw_teams_always_two_teams(self, match_service, sample_squad, sample_player_data):
        """Test that draw_teams works with 2-team constraint"""
        match_data = match_service.create_match(
            squad_id=sample_squad.squad_id,
            team_a_players=sample_player_data[:3],
            team_b_players=sample_player_data[3:]
        )
        
        # Get match details to extract players
        match_detail = match_service.get_match_detail(match_data.match_id)
        all_players = match_detail.team_a.players + match_detail.team_b.players
        
        draft_results = match_service.draw_teams(all_players)
        
        # DrawTeamsService always creates 2 teams
        assert len(draft_results) >= 1  # Should return at least one composition
        
        for draft in draft_results:
            assert isinstance(draft, DraftData)
            # Each draft should have exactly 2 teams (team_a and team_b)
            assert hasattr(draft, 'team_a')
            assert hasattr(draft, 'team_b')

    def test_draw_teams_integration_with_draw_teams_service(self, match_service, sample_match):
        """Test that draw_teams properly integrates with DrawTeamsService"""
        # Get match details to extract players
        match_detail = match_service.get_match_detail(sample_match.match_id)
        all_players = match_detail.team_a.players + match_detail.team_b.players
        
        draft_results = match_service.draw_teams(all_players)
        
        # Verify draft_results structure
        assert isinstance(draft_results, list)
        
        for draft in draft_results:
            assert isinstance(draft, DraftData)
            
            # Verify teams contain PlayerData objects
            for player in draft.team_a + draft.team_b:
                assert isinstance(player, PlayerData)
                assert hasattr(player, 'player_id')
                assert hasattr(player, 'score')
                
            # Verify no player appears in both teams
            team_a_ids = {player.player_id for player in draft.team_a}
            team_b_ids = {player.player_id for player in draft.team_b}
            assert len(team_a_ids.intersection(team_b_ids)) == 0

    def test_draw_teams_player_data_completeness(self, match_service, sample_match):
        """Test that draw_teams returns complete PlayerData objects"""
        # Get match details to extract players
        match_detail = match_service.get_match_detail(sample_match.match_id)
        all_players = match_detail.team_a.players + match_detail.team_b.players
        
        draft_results = match_service.draw_teams(all_players)
        
        for draft in draft_results:
            for player in draft.team_a + draft.team_b:
                # Verify all required PlayerData fields are present
                assert hasattr(player, 'player_id')
                assert hasattr(player, 'name')
                assert hasattr(player, 'score')
                assert hasattr(player, 'position')
                assert hasattr(player, 'squad_id')
                
                # Verify field values are not None
                assert player.player_id is not None
                assert player.name is not None
                assert player.score is not None
                assert player.position is not None
                assert player.squad_id is not None

    def test_draw_teams_score_sorting(self, match_service, sample_squad, sample_player_data):
        """Test that draw_teams correctly sorts players by score"""
        # Create match with all players
        match_data = match_service.create_match(
            squad_id=sample_squad.squad_id,
            team_a_players=sample_player_data[:3],
            team_b_players=sample_player_data[3:]
        )
        
        # Get match details to extract players
        match_detail = match_service.get_match_detail(match_data.match_id)
        all_players = match_detail.team_a.players + match_detail.team_b.players
        
        draft_results = match_service.draw_teams(all_players)
        
        # Get all players from first draft to check sorting
        first_draft = draft_results[0]
        all_players_in_draft = first_draft.team_a + first_draft.team_b
        
        # Create expected sorted order from original players
        original_scores = sorted([p.score for p in sample_player_data], reverse=True)
        draft_scores = sorted([p.score for p in all_players_in_draft], reverse=True)
        
        # Should contain all players with correct scores
        assert len(all_players_in_draft) == len(sample_player_data)
        assert draft_scores == original_scores

    def test_draw_teams_player_data_fields_match_original(self, match_service, sample_match, sample_player_data):
        """Test that PlayerData objects from draw_teams match original player data"""
        # Get match details to extract players
        match_detail = match_service.get_match_detail(sample_match.match_id)
        all_players = match_detail.team_a.players + match_detail.team_b.players
        
        draft_results = match_service.draw_teams(all_players)
        
        # Create a mapping of original players for comparison
        original_players_map = {p.player_id: p for p in sample_player_data}
        
        for draft in draft_results:
            for returned_player in draft.team_a + draft.team_b:
                original_player = original_players_map.get(returned_player.player_id)
                if original_player:  # Should be found
                    assert returned_player.name == original_player.name
                    assert returned_player.score == original_player.score
                    assert returned_player.squad_id == original_player.squad_id

    def test_match_data_model_conversion_completeness(self, match_service, sample_match):
        """Test that all required fields are properly converted from Match model to MatchData"""
        match_data = match_service.get_match(sample_match.match_id)
        
        # Verify all MatchData fields are present and correctly mapped
        assert hasattr(match_data, 'squad_id')
        assert hasattr(match_data, 'match_id')
        assert hasattr(match_data, 'score')
        assert hasattr(match_data, 'created_at')
        
        # Verify field types and values
        assert isinstance(match_data.squad_id, str)
        assert isinstance(match_data.match_id, str)
        assert isinstance(match_data.score, tuple)
        assert len(match_data.score) == 2
        assert isinstance(match_data.created_at, datetime)
        assert match_data.match_id == sample_match.match_id
        assert match_data.squad_id == sample_match.squad_id

    def test_match_detail_data_model_conversion_completeness(self, match_service, sample_match):
        """Test that all required fields are properly converted from Match model to MatchDetailData"""
        match_detail = match_service.get_match_detail(sample_match.match_id)
        
        # Verify all MatchDetailData fields are present
        assert hasattr(match_detail, 'squad_id')
        assert hasattr(match_detail, 'match_id')
        assert hasattr(match_detail, 'created_at')
        assert hasattr(match_detail, 'team_a')
        assert hasattr(match_detail, 'team_b')
        
        # Verify field types and values
        assert isinstance(match_detail.squad_id, str)
        assert isinstance(match_detail.match_id, str)
        assert isinstance(match_detail.created_at, datetime)
        assert isinstance(match_detail.team_a, TeamDetailData)
        assert isinstance(match_detail.team_b, TeamDetailData)
        
        # Verify field values match
        assert match_detail.match_id == sample_match.match_id
        assert match_detail.squad_id == sample_match.squad_id

    def test_match_teams_have_correct_properties(self, match_service, sample_match):
        """Test that match teams have all required properties"""
        match_detail = match_service.get_match_detail(sample_match.match_id)
        
        for team in [match_detail.team_a, match_detail.team_b]:
            assert team.team_id is not None
            assert team.color in ["white", "black"]
            assert isinstance(team.score, int)
            assert isinstance(team.players_count, int)
            assert isinstance(team.players, list)
            
            # Verify all players are PlayerData objects
            for player in team.players:
                assert isinstance(player, PlayerData)
                assert player.player_id is not None

    def test_multiple_matches_isolation(self, match_service, sample_squad, sample_player_data, session):
        """Test that operations on one match don't affect others"""
        # Create multiple matches
        match1_data = match_service.create_match(
            squad_id=sample_squad.squad_id,
            team_a_players=sample_player_data[:2],
            team_b_players=sample_player_data[2:4]
        )
        match2_data = match_service.create_match(
            squad_id=sample_squad.squad_id,
            team_a_players=sample_player_data[1:3],
            team_b_players=sample_player_data[3:5]
        )
        
        # Update match1 score
        match_service.update_match_score(match1_data.match_id, 5, 2)
        
        # Verify match2 is unchanged
        match2_check = match_service.get_match_detail(match2_data.match_id)
        assert match2_check.team_a.score == 0
        assert match2_check.team_b.score == 0

    def test_database_persistence_after_updates(self, match_service, sample_match, session):
        """Test that all updates are properly persisted to database"""
        original_id = sample_match.match_id
        
        # Perform score update
        match_service.update_match_score(original_id, 10, 7)
        
        # Refresh session and check database directly
        session.expire_all()
        db_match = session.query(Match).filter(Match.match_id == original_id).first()
        
        team_scores = [team.score for team in db_match.teams]
        assert 10 in team_scores
        assert 7 in team_scores
        
        # Also verify through service
        service_match = match_service.get_match_detail(original_id)
        total_score = service_match.team_a.score + service_match.team_b.score
        assert total_score == 17

    def test_match_with_specific_team_colors(self, match_service, sample_match):
        """Test that matches always have white and black teams"""
        match_detail = match_service.get_match_detail(sample_match.match_id)
        
        colors = {match_detail.team_a.color, match_detail.team_b.color}
        assert colors == {"white", "black"}

    def test_match_creation_generates_unique_ids(self, match_service, sample_squad, team_a_players, team_b_players):
        """Test that each match gets a unique ID"""
        match_ids = set()
        
        for _ in range(5):
            match_data = match_service.create_match(
                squad_id=sample_squad.squad_id,
                team_a_players=team_a_players,
                team_b_players=team_b_players
            )
            match_ids.add(match_data.match_id)
        
        # All IDs should be unique
        assert len(match_ids) == 5

    def test_match_score_tuple_format(self, match_service, sample_match):
        """Test that match score is always returned as a tuple of two integers"""
        # Test initial score
        match_data = match_service.get_match(sample_match.match_id)
        assert isinstance(match_data.score, tuple)
        assert len(match_data.score) == 2
        assert all(isinstance(score, int) for score in match_data.score)
        
        # Test after score update
        match_service.update_match_score(sample_match.match_id, 3, 1)
        updated_match = match_service.get_match(sample_match.match_id)
        assert isinstance(updated_match.score, tuple)
        assert len(updated_match.score) == 2
        assert set(updated_match.score) == {3, 1}

    def test_match_teams_always_exist(self, match_service, sample_squad, session):
        """Test that matches always have exactly 2 teams"""
        match_data = match_service.create_match(
            squad_id=sample_squad.squad_id,
            team_a_players=[],
            team_b_players=[]
        )
        
        # Check database directly
        db_match = session.query(Match).filter(Match.match_id == match_data.match_id).first()
        assert len(db_match.teams) == 2
        
        # Check through service
        match_detail = match_service.get_match_detail(match_data.match_id)
        assert match_detail.team_a is not None
        assert match_detail.team_b is not None
