import pytest
from app.services.draw_teams_service import DrawTeamsService, Relation
from app.entities import PlayerData, Position
import uuid


@pytest.fixture
def sample_players_balanced():
    """Create balanced sample players for testing"""
    return [
        PlayerData(
            player_id=str(uuid.uuid4()),
            squad_id="squad-1",
            name="Player A",
            position=Position.FIELD,
            base_score=100,
            _score=100.0,
            matches_played=5
        ),
        PlayerData(
            player_id=str(uuid.uuid4()),
            squad_id="squad-1",
            name="Player B",
            position=Position.FIELD,
            base_score=90,
            _score=90.0,
            matches_played=4
        ),
        PlayerData(
            player_id=str(uuid.uuid4()),
            squad_id="squad-1",
            name="Player C",
            position=Position.FIELD,
            base_score=80,
            _score=80.0,
            matches_played=3
        ),
        PlayerData(
            player_id=str(uuid.uuid4()),
            squad_id="squad-1",
            name="Player D",
            position=Position.GOALIE,
            base_score=70,
            _score=70.0,
            matches_played=2
        ),
        PlayerData(
            player_id=str(uuid.uuid4()),
            squad_id="squad-1",
            name="Player E",
            position=Position.FIELD,
            base_score=60,
            _score=60.0,
            matches_played=1
        ),
        PlayerData(
            player_id=str(uuid.uuid4()),
            squad_id="squad-1",
            name="Player F",
            position=Position.FIELD,
            base_score=50,
            _score=50.0,
            matches_played=0
        )
    ]


@pytest.fixture
def sample_players_uneven():
    """Create uneven number of players for edge case testing"""
    return [
        PlayerData(
            player_id=str(uuid.uuid4()),
            squad_id="squad-1",
            name="Player X",
            position=Position.FIELD,
            base_score=100,
            _score=100.0,
            matches_played=1
        ),
        PlayerData(
            player_id=str(uuid.uuid4()),
            squad_id="squad-1",
            name="Player Y",
            position=Position.FIELD,
            base_score=80,
            _score=80.0,
            matches_played=2
        ),
        PlayerData(
            player_id=str(uuid.uuid4()),
            squad_id="squad-1",
            name="Player Z",
            position=Position.GOALIE,
            base_score=60,
            _score=60.0,
            matches_played=3
        )
    ]


class TestDrawTeamsService:
    """Test class for DrawTeamsService functionality"""

    def test_init_default_values(self, sample_players_balanced):
        """Test initialization with default values"""
        service = DrawTeamsService(sample_players_balanced)
        
        assert service.amount_of_teams == 2
        assert service.amount_of_draws == 20
        assert len(service.players) == len(sample_players_balanced)
        
        # Verify players are sorted by score in descending order
        scores = [player.score for player in service.players]
        assert scores == sorted(scores, reverse=True)

    def test_init_empty_players(self):
        """Test initialization with empty players list"""
        service = DrawTeamsService([])
        
        assert service.amount_of_teams == 2
        assert service.amount_of_draws == 20
        assert len(service.players) == 0

    def test_players_sorting(self, sample_players_balanced):
        """Test that players are properly sorted by score descending"""
        # Create players in random order
        unsorted_players = [sample_players_balanced[i] for i in [2, 0, 4, 1, 5, 3]]
        service = DrawTeamsService(unsorted_players)
        
        # Verify sorting
        expected_scores = [100.0, 90.0, 80.0, 70.0, 60.0, 50.0]
        actual_scores = [player.score for player in service.players]
        assert actual_scores == expected_scores

    def test_draw_teams_2_teams(self, sample_players_balanced):
        """Test draw_teams method with 2 teams"""
        service = DrawTeamsService(sample_players_balanced, amount_of_teams=2)
        results = service.draw_teams()
        
        assert isinstance(results, list)
        assert len(results) <= service.amount_of_draws
        
        # Each result should be a tuple of player indices
        for team_combo in results:
            assert isinstance(team_combo, tuple)
            assert len(team_combo) == len(sample_players_balanced) // 2  # Team size
            # All indices should be valid
            for player_index in team_combo:
                assert 0 <= player_index < len(sample_players_balanced)

    def test_draw_teams_invalid_amount(self, sample_players_balanced):
        """Test draw_teams method with invalid team amount"""
        service = DrawTeamsService(sample_players_balanced, amount_of_teams=4)
        
        with pytest.raises(ValueError, match="Invalid amount of teams"):
            service.draw_teams()

    def test_draw_teams_2_directly(self, sample_players_balanced):
        """Test draw_teams_2 method directly"""
        service = DrawTeamsService(sample_players_balanced)
        results = service.draw_teams_2()
        
        team_size = len(sample_players_balanced) // 2
        total_score = sum(player.score for player in sample_players_balanced)
        
        assert isinstance(results, list)
        assert len(results) > 0
        
        # Verify each combination
        for team_combo in results:
            assert isinstance(team_combo, tuple)
            assert len(team_combo) == team_size
            
            # Verify team score balance (results should be sorted by balance)
            team_score = sum(service.players[i].score for i in team_combo)
            balance_diff = abs(team_score - total_score / 2)
            
            # First result should be the most balanced
            if team_combo == results[0]:
                first_balance = balance_diff
            else:
                assert balance_diff >= first_balance

    def test_team_balance_verification_2_teams(self, sample_players_balanced):
        """Test that 2-team combinations are properly balanced"""
        service = DrawTeamsService(sample_players_balanced)
        results = service.draw_teams_2()
        
        total_score = sum(player.score for player in sample_players_balanced)
        target_score = total_score / 2
        
        # Results should be sorted by balance (closest to target first)
        previous_diff = -1
        for team_combo in results:
            team_score = sum(service.players[i].score for i in team_combo)
            diff = abs(team_score - target_score)
            
            if previous_diff >= 0:
                assert diff >= previous_diff
            previous_diff = diff

    def test_edge_case_two_players(self):
        """Test with minimum viable number of players for 2 teams"""
        players = [
            PlayerData(
                player_id=str(uuid.uuid4()),
                squad_id="squad-1",
                name="Player 1",
                position=Position.FIELD,
                base_score=100,
                _score=100.0,
                matches_played=1
            ),
            PlayerData(
                player_id=str(uuid.uuid4()),
                squad_id="squad-1",
                name="Player 2",
                position=Position.FIELD,
                base_score=80,
                _score=80.0,
                matches_played=1
            )
        ]
        
        service = DrawTeamsService(players, amount_of_teams=2)
        results = service.draw_teams()
        
        assert len(results) == 1  # Only one way to split 2 players into 2 teams
        assert results[0] == (0,) or results[0] == (1,)

    def test_edge_case_uneven_division(self, sample_players_uneven):
        """Test with players that don't divide evenly into teams"""
        # 3 players for 2 teams = 1 player per team (1 left over)
        service = DrawTeamsService(sample_players_uneven, amount_of_teams=2)
        results = service.draw_teams()
        
        # Should still work, taking floor division
        team_size = len(sample_players_uneven) // 2  # = 1
        
        for team_combo in results:
            assert len(team_combo) == team_size

    def test_amount_of_draws_limit(self, sample_players_balanced):
        """Test that amount_of_draws limits the results"""
        service = DrawTeamsService(sample_players_balanced, amount_of_draws=5)
        results = service.draw_teams()
        
        assert len(results) <= 5

    def test_large_amount_of_draws(self, sample_players_balanced):
        """Test with amount_of_draws larger than possible combinations"""
        # Calculate total possible combinations
        from math import comb
        team_size = len(sample_players_balanced) // 2
        total_combinations = comb(len(sample_players_balanced), team_size)
        
        service = DrawTeamsService(sample_players_balanced, amount_of_draws=total_combinations + 10)
        results = service.draw_teams()
        
        # Should return all possible combinations, not more
        assert len(results) <= total_combinations

    def test_player_data_integrity(self, sample_players_balanced):
        """Test that original player data is not modified"""
        original_scores = [player.score for player in sample_players_balanced]
        original_names = [player.name for player in sample_players_balanced]
        
        service = DrawTeamsService(sample_players_balanced)
        service.draw_teams()
        
        # Original data should remain unchanged
        assert [player.score for player in sample_players_balanced] == original_scores
        assert [player.name for player in sample_players_balanced] == original_names

    def test_reproducibility_with_same_input(self, sample_players_balanced):
        """Test that same input produces same results"""
        service1 = DrawTeamsService(sample_players_balanced.copy())
        service2 = DrawTeamsService(sample_players_balanced.copy())
        
        results1 = service1.draw_teams()
        results2 = service2.draw_teams()
        
        assert results1 == results2

    def test_different_squad_ids_handling(self):
        """Test that players from different squads are handled correctly"""
        players = [
            PlayerData(
                player_id=str(uuid.uuid4()),
                squad_id="squad-1",
                name="Player A",
                position=Position.FIELD,
                base_score=100,
                _score=100.0,
                matches_played=1
            ),
            PlayerData(
                player_id=str(uuid.uuid4()),
                squad_id="squad-2",
                name="Player B",
                position=Position.FIELD,
                base_score=90,
                _score=90.0,
                matches_played=1
            ),
            PlayerData(
                player_id=str(uuid.uuid4()),
                squad_id="squad-1",
                name="Player C",
                position=Position.GOALIE,
                base_score=80,
                _score=80.0,
                matches_played=1
            ),
            PlayerData(
                player_id=str(uuid.uuid4()),
                squad_id="squad-2",
                name="Player D",
                position=Position.FIELD,
                base_score=70,
                _score=70.0,
                matches_played=1
            )
        ]
        
        service = DrawTeamsService(players)
        results = service.draw_teams()
        
        # Should work regardless of squad_id differences
        assert len(results) > 0
        for team_combo in results:
            assert len(team_combo) == 2  # 4 players / 2 teams = 2 per team

    def test_performance_with_larger_dataset(self):
        """Test performance with a larger dataset"""
        # Create 12 players for more realistic testing
        players = []
        for i in range(12):
            players.append(PlayerData(
                player_id=str(uuid.uuid4()),
                squad_id="squad-1",
                name=f"Player {i}",
                position=Position.FIELD,
                base_score=100 - i * 5,
                _score=float(100 - i * 5),
                matches_played=i
            ))
        
        service = DrawTeamsService(players, amount_of_teams=2, amount_of_draws=50)
        results = service.draw_teams()
        
        assert len(results) > 0
        assert len(results) <= 50
        
        # Verify structure
        for team_combo in results:
            assert len(team_combo) == 6  # 12 players / 2 teams = 6 per team
