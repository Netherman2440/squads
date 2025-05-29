import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import uuid

from app.db import Player, Base as PlayerBase
from app.db import Match, Base as MatchBase
from app.db import Team, Base as TeamBase
from app.db import TeamPlayer, Base as TeamPlayerBase
from app.services import PlayerService
from app.entities import PlayerData, Position

@pytest.fixture
def session():
    # Create in-memory SQLite database
    engine = create_engine("sqlite:///:memory:")
    # Create all tables
    PlayerBase.metadata.create_all(engine)
    MatchBase.metadata.create_all(engine)
    TeamBase.metadata.create_all(engine)
    TeamPlayerBase.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    return Session()

def create_player(session, name="Test Player", base_score=10, squad_id=None):
    player_id = uuid.uuid4()
    player = Player(
        name=name,
        position= Position.GOALIE.value,
        base_score=base_score,
        squad_id=squad_id,
        player_id=player_id
    )
    session.add(player)
    session.commit()
    return player

def create_match_with_teams_and_player(session, player, player_team_score, opponent_team_score, created_at):
    # Create teams
    team1 = Team(score=player_team_score, color="white")
    team2 = Team(score=opponent_team_score, color="black")
    session.add_all([team1, team2])
    session.commit()

    # Create match
    match_id = uuid.uuid4()
    match = Match(created_at=created_at, match_id=match_id)
    session.add(match)
    session.commit()

    # Link teams to match
    team1.match_id = match_id
    team2.match_id = match_id
    session.commit()

    # Link player to team1
    team_player = TeamPlayer(
        player_id=player.player_id,
        team_id=team1.team_id,
        match_id=match_id
    )
    session.add(team_player)
    session.commit()

    return match

def test_recalculate_and_update_score(session):
    service = PlayerService(session)
    # Create player
    player = create_player(session, base_score=10)
    # Create two matches
    import datetime
    match1 = create_match_with_teams_and_player(
        session, player, player_team_score=5, opponent_team_score=3,
        created_at=datetime.datetime(2023, 1, 1)
    )
    match2 = create_match_with_teams_and_player(
        session, player, player_team_score=2, opponent_team_score=4,
        created_at=datetime.datetime(2023, 1, 2)
    )

    # Recalculate score
    player_data = service.recalculate_and_update_score(player.player_id)

    # Calculate expected score manually:
    # base_score = 10
    # match1: (5-3)/1 = 2
    # match2: (2-4)/1.2 = -1.6666666666666667
    # total = 10 + 2 - 1.6666666666666667 = 10.333333333333334
    assert player_data.score == 10.333333333333334
    assert player_data.base_score == 10
    assert player_data.name == player.name
    assert player_data.player_id == str(player.player_id)