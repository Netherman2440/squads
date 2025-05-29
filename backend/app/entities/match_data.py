from dataclasses import dataclass
from datetime import datetime
from .team_data import TeamData, TeamDetailData

@dataclass
class MatchData:
    match_id: str
    team_a: TeamData
    team_b: TeamData
    created_at: datetime


    def score(self) -> tuple[int, int]:
        return self.team_a.score, self.team_b.score


@dataclass
class MatchDetailData(MatchData):
    team_a: TeamDetailData
    team_b: TeamDetailData
    #todo: stats


