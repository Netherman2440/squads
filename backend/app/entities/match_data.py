from dataclasses import dataclass
from datetime import datetime
from typing import Optional
from .team_data import TeamDetailData
from app.schemas.match_schemas import MatchResponse, MatchDetailResponse

@dataclass
class MatchData:
    squad_id: str
    match_id: str
    score: Optional[tuple[int, int]]
    created_at: datetime

    def to_response(self) -> MatchResponse:
        return MatchResponse(
            squad_id=self.squad_id,
            match_id=self.match_id,
            score=self.score,
            created_at=self.created_at,
        )

@dataclass
class MatchDetailData:
    squad_id: str
    match_id: str
    created_at: datetime
    team_a: TeamDetailData
    team_b: TeamDetailData
    #todo: stats

    @property
    def score(self) -> Optional[tuple[int, int]]:
        # Check if score is actually set (not default 0-0)
        if self.team_a.score is None or self.team_b.score is None:
            return None
        return (self.team_a.score, self.team_b.score)

    def to_response(self) -> MatchDetailResponse:
        return MatchDetailResponse(
            squad_id=self.squad_id,
            match_id=self.match_id,
            created_at=self.created_at,
            score=self.score,
            team_a=self.team_a,
            team_b=self.team_b,
        )   

