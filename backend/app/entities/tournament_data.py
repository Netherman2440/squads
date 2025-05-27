
from dataclasses import dataclass
from datetime import datetime
from .match_data import MatchData
from .team_data import TeamDetailData


@dataclass
class TournamentData:
    tournament_id: str
    name: str
    created_at: datetime
    teams_count: int
    matches_count: int



@dataclass
class TournamentDetailData(TournamentData):
    teams: list[TeamDetailData]
    matches: list[MatchData]



