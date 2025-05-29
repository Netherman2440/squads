import pytest
from app.services.match_service import MatchService
from app.entities import PlayerData, Position

@pytest.fixture
def players_10():
    return [
        PlayerData(
            squad_id="squad1",
            player_id=str(i),
            name=f"Player {i}",
            base_score=100 - i,
            position=Position.NONE
        )
        for i in range(10)
    ]

@pytest.fixture
def match_service():
    # Jeśli masz zależności (np. session), możesz je zamockować
    return MatchService(session=None)

def test_create_match(match_service, players_10):
    match = match_service.create_match(players_10)
    assert match is not None
    assert hasattr(match, "match_id")
    assert len(match.players) == 10

def test_get_match(match_service, players_10):
    match = match_service.create_match(players_10)
    fetched = match_service.get_match(match.match_id)
    assert fetched is not None
    assert fetched.match_id == match.match_id

def test_update_match(match_service, players_10):
    match = match_service.create_match(players_10)
    # Załóżmy, że update_match przyjmuje match_id i nową listę graczy
    new_players = players_10[:5]
    updated = match_service.update_match(match.match_id, new_players)
    assert updated is not None
    assert len(updated.players) == 5

def test_delete_match(match_service, players_10):
    match = match_service.create_match(players_10)
    match_service.delete_match(match.match_id)
    assert match_service.get_match(match.match_id) is None

def test_draw_teams_integration(match_service, players_10):
    # Wywołanie draw_teams przez serwis
    combos = match_service.draw_teams(players_10, amount_of_teams=2, amount_of_draws=10)
    assert isinstance(combos, list)
    assert len(combos) == 10
    for combo in combos:
        assert len(combo) == 5  # 10 graczy, 2 drużyny po 5

def test_draw_teams_user_can_choose_combo(match_service, players_10):
    combos = match_service.draw_teams(players_10, amount_of_teams=2, amount_of_draws=5)
    # Symulujemy wybór przez użytkownika pierwszej kombinacji
    chosen_combo = combos[0]
    team1 = [players_10[i] for i in chosen_combo]
    team2 = [players_10[i] for i in range(10) if i not in chosen_combo]
    assert len(team1) == 5
    assert len(team2) == 5
    # Możesz dodać więcej asercji, np. czy sumy punktów są zbliżone

# Możesz dodać więcej testów, np. na edge case'y, jeśli chcesz 