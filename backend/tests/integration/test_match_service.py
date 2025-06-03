import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import uuid

from app.db import Match, Base as MatchBase
from app.db import Team, Base as TeamBase
from app.db import TeamPlayer, Base as TeamPlayerBase
from app.db import Player, Base as PlayerBase
from app.db import Squad, Base as SquadBase
from app.services import MatchService
from app.entities import PlayerData

@pytest.fixture
def session():
    # Create in-memory SQLite database
    engine = create_engine("sqlite:///:memory:")
    # Create all tables
    PlayerBase.metadata.create_all(engine)
    MatchBase.metadata.create_all(engine)
    TeamBase.metadata.create_all(engine)
    TeamPlayerBase.metadata.create_all(engine)
    SquadBase.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    return Session()

def create_player_data(name="Test Player", score=10, player_id=None) -> PlayerData:
    if player_id is None:
        player_id = str(uuid.uuid4())
    return PlayerData(
        player_id=player_id,
        name=name, 
        base_score=score,
        position="GOALIE",
        squad_id=None
    )

def test_create_match(session):
    service = MatchService(session)

    # Create squad in DB
    squad = Squad( name="Test Squad")
    session.add(squad)
    session.commit()
    team_a_players = [create_player_data(name="Player A1"), create_player_data(name="Player A2")]
    team_b_players = [create_player_data(name="Player B1"), create_player_data(name="Player B2")]

    match_data = service.create_match(squad.squad_id, team_a_players, team_b_players)

    assert match_data.match_id is not None
    assert match_data.team_a is not None
    assert match_data.team_b is not None
    assert match_data.created_at is not None

def test_get_match(session):
    service = MatchService(session)
    squad_id = str(uuid.uuid4())
    # Create squad in DB
    squad = Squad(squad_id=squad_id, name="Test Squad")
    session.add(squad)
    session.commit()
    team_a_players = [create_player_data(name="Player A1")]
    team_b_players = [create_player_data(name="Player B1")]

    match_data = service.create_match(squad.squad_id, team_a_players, team_b_players)

    fetched_match = service.get_match(match_data.match_id)
    assert fetched_match is not None
    assert fetched_match.match_id == match_data.match_id

def test_draw_teams(session):
    service = MatchService(session)
    players = [
        create_player_data(name="Player 1", score=20),
        create_player_data(name="Player 2", score=15),
        create_player_data(name="Player 3", score=10),
        create_player_data(name="Player 4", score=5)
    ]
    sorted_players, list_of_teams = service.draw_teams(players, amount_of_teams=2)
    assert len(sorted_players) == 4
    assert isinstance(list_of_teams, list)
