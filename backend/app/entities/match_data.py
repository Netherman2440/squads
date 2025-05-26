from dataclasses import dataclass
from datetime import datetime
from .team_data import TeamData

@dataclass
class MatchData:
    match_id: str
    squad_id: str
    team_a: TeamData
    team_b: TeamData
    created_at: datetime


    def score(self) -> str:
        return f"{self.team_a.score} - {self.team_b.score}"
