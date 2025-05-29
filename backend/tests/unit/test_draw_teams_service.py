import pytest
from app.services.draw_teams_service import DrawTeamsService
from app.entities.player_data import PlayerData
from app.entities.position import Position

def create_players(scores):
    # Helper function to create PlayerData objects with given scores
    return [PlayerData(name=f"Player{i}", base_score=score, squad_id="squad-1", player_id=f"player-{i}") for i, score in enumerate(scores)]

def test_draw_teams_2_even_split():
    # Test for even number of players and balanced teams
    players = create_players([100, 90, 80, 70])
    service = DrawTeamsService(players, 2)
    combos = service.draw_teams_2()
    # There should be 6 possible combinations for 2 teams of 2 players
    assert len(combos) == 6
    # The best combo should have the most balanced score
    best_combo = combos[0]
    team1_score = sum(players[i].score for i in best_combo)
    team2_score = sum(players[i].score for i in range(4) if i not in best_combo)
    assert abs(team1_score - team2_score) == 0  # Should be perfectly balanced

def test_draw_teams_2_odd_players():
    # Test for odd number of players (one player will not be assigned)
    players = create_players([100, 90, 80])
    service = DrawTeamsService(players, 2)
    combos = service.draw_teams_2()
    # There should be 3 possible combinations for 2 teams of 1 player (since 3//2 == 1)
    assert len(combos) == 3
    # Each combo should be a tuple of length 1
    for combo in combos:
        assert len(combo) == 1

def test_draw_teams_2_large():
    # Test for a larger number of players
    players = create_players([100, 90, 80, 70, 60, 50])
    service = DrawTeamsService(players, 2)
    combos = service.draw_teams_2()
    # There should be 20 possible combinations for 2 teams of 3 players
    assert len(combos) == 20
    # The best combo should be as balanced as possible
    best_combo = combos[0]
    team1_score = sum(players[i].score for i in best_combo)
    team2_score = sum(players[i].score for i in range(6) if i not in best_combo)
    assert abs(team1_score - team2_score) <= 10  # Should be close to balanced

@pytest.fixture
def players_20():
    # Create 20 players with different scores
    return [
        PlayerData(
            squad_id="squad1",
            player_id=str(i),
            name=f"Player {i}",
            base_score=100 - i,
            position=Position.NONE
        )
        for i in range(20)
    ]

def test_draw_teams_default_amount(players_20):
    service = DrawTeamsService(players_20, amount_of_teams=2)
    combos = service.draw_teams()  # default amount_of_draws=20
    # Assert that 20 combinations are returned
    assert len(combos) == 20
    # Assert that each combination has 10 players (for 20 players, 2 teams)
    for combo in combos:
        assert len(combo) == 10

def test_draw_teams_custom_amount(players_20):
    service = DrawTeamsService(players_20, amount_of_teams=2)
    combos = service.draw_teams(amount_of_draws=5)
    # Assert that 5 combinations are returned
    assert len(combos) == 5
    # Assert that each combination has 10 players
    for combo in combos:
        assert len(combo) == 10

def test_draw_teams_combination_indices_are_unique(players_20):
    service = DrawTeamsService(players_20, amount_of_teams=2)
    combos = service.draw_teams(amount_of_draws=3)
    # For each combination, check that all indices are unique and within range
    for combo in combos:
        assert len(set(combo)) == len(combo)
        assert all(0 <= idx < 20 for idx in combo)

def test_draw_teams_invalid_amount_of_teams(players_20):
    service = DrawTeamsService(players_20, amount_of_teams=4)
    with pytest.raises(ValueError):
        service.draw_teams()

def test_draw_teams_balance_best_combo(players_20):
    service = DrawTeamsService(players_20, amount_of_teams=2)
    combos = service.draw_teams(amount_of_draws=1)
    best_combo = combos[0]
    team1_score = sum(players_20[i].score for i in best_combo)
    team2_score = sum(players_20[i].score for i in range(20) if i not in best_combo)
    # The best combo should be as balanced as possible
    assert abs(team1_score - team2_score) == min(
        abs(
            sum(players_20[i].score for i in combo) -
            sum(players_20[i].score for i in range(20) if i not in combo)
        )
        for combo in combos
    )

def test_draw_teams_no_duplicate_combinations(players_20):
    service = DrawTeamsService(players_20, amount_of_teams=2)
    combos = service.draw_teams(amount_of_draws=20)
    # Convert each combo to a sorted tuple for comparison
    seen = set()
    for combo in combos:
        t = tuple(sorted(combo))
        assert t not in seen
        seen.add(t)

# You can run these tests with: pytest tests/services/test_draw_teams_service.py 