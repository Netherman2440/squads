from dataclasses import dataclass
from datetime import datetime
from .team_data import TeamData, TeamDetailData

@dataclass
class MatchData:
    squad_id: str
    match_id: str
    score: tuple[int, int]
    created_at: datetime


@dataclass
class MatchDetailData:
    squad_id: str
    match_id: str
    created_at: datetime
    team_a: TeamDetailData
    team_b: TeamDetailData
    #todo: stats


