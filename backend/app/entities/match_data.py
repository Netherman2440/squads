from dataclasses import dataclass
from datetime import datetime
from typing import Optional
from .team_data import TeamDetailData
from app.schemas.match_schemas import MatchResponse, MatchDetailResponse, TeamDetailResponse
from app.schemas.player_schemas import PlayerResponse

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

    def to_response(self) -> MatchDetailResponse:
        return MatchDetailResponse(
            squad_id=self.squad_id,
            match_id=self.match_id,
            created_at=self.created_at,
            team_a=self.team_a.to_response(),
            team_b=self.team_b.to_response(),
        )   

