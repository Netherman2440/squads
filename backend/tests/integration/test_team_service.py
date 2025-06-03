import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import uuid

from app.db import Team, Base as TeamBase
from app.db import TeamPlayer, Base as TeamPlayerBase
from app.db import Player, Base as PlayerBase
from app.db import Match, Base as MatchBase
from app.services import TeamService
from app.entities import PlayerData
from app.entities import Position

@pytest.fixture
def session():
    # Create in-memory SQLite database
    engine = create_engine("sqlite:///:memory:")
    # Create all tables
    TeamBase.metadata.create_all(engine)
    TeamPlayerBase.metadata.create_all(engine)
    PlayerBase.metadata.create_all(engine)
    MatchBase.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    return Session()

def create_player(session, name="Test Player", squad_id=None):
    player_id = str(uuid.uuid4())
    player = Player(
        name=name,
        position=Position.GOALIE.value,
        base_score=10,
        squad_id=squad_id,
        player_id=player_id
    )
    session.add(player)
    session.commit()
    return player

def create_match(session):
    match = Match()
    session.add(match)
    session.commit()
    return match

def test_create_team(session):
    team_service = TeamService(session)
    match = create_match(session)
    squad_id = str(uuid.uuid4())
    players = [create_player(session, name=f"Player {i}", squad_id=squad_id) for i in range(3)]
    player_data_list = [
        PlayerData(
            player_id=player.player_id,
            name=player.name,
            position=player.position,
            base_score=player.base_score,
            squad_id=player.squad_id,
            matches_played=len(player.matches)
        ) for player in players
    ]
    team_data = team_service.create_team(
        squad_id=squad_id,
        match_id=match.match_id,
        players=player_data_list,
        color="red",
        name="Red Team"
    )
    assert team_data.name == "Red Team"
    assert team_data.color == "red"
    assert team_data.players_count == 3

def test_get_team(session):
    team_service = TeamService(session)
    match = create_match(session)
    squad_id = str(uuid.uuid4())
    players = [create_player(session, name=f"Player {i}", squad_id=squad_id) for i in range(2)]
    player_data_list = [
        PlayerData(
            player_id=player.player_id,
            name=player.name,
            position=player.position,
            base_score=player.base_score,
            squad_id=player.squad_id,
            matches_played=len(player.matches)
        ) for player in players
    ]
    team_data = team_service.create_team(
        squad_id=squad_id,
        match_id=match.match_id,
        players=player_data_list,
        color="blue",
        name="Blue Team"
    )
    fetched_team = team_service.get_team(team_data.team_id)
    assert fetched_team.team_id == team_data.team_id
    assert fetched_team.name == "Blue Team"
    assert fetched_team.players_count == 2

def test_get_team_details(session):
    team_service = TeamService(session)
    match = create_match(session)
    squad_id = str(uuid.uuid4())
    players = [create_player(session, name=f"Player {i}", squad_id=squad_id) for i in range(4)]
    player_data_list = [
        PlayerData(
            player_id=player.player_id,
            name=player.name,
            position=player.position,
            base_score=player.base_score,
            squad_id=player.squad_id,
            matches_played=len(player.matches)
        ) for player in players
    ]
    team_data = team_service.create_team(
        squad_id=squad_id,
        match_id=match.match_id,
        players=player_data_list,
        color="green",
        name="Green Team"
    )
    team_details = team_service.get_team_details(team_data.team_id)
    assert team_details.team_id == team_data.team_id
    assert team_details.name == "Green Team"
    assert team_details.players_count == 4
    assert len(team_details.players) == 4
    assert all(player.name.startswith("Player") for player in team_details.players)
    assert all(player.matches_played == 1 for player in team_details.players)
