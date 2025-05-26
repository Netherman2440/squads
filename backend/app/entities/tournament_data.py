
from dataclasses import dataclass
from datetime import datetime
from .match_data import MatchData
from .team_data import TeamData


@dataclass
class TournamentData:
    tournament_id: str
    name: str
    created_at: datetime
    teams: list[TeamData]
    matches: list[MatchData]


