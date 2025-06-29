from datetime import datetime
from typing import Optional
from pydantic import BaseModel

from app.entities.team_data import TeamDetailData

class MatchBase(BaseModel):
    pass

#/matches

class MatchCreate(MatchBase):
    team_a: list
    team_b: list

class MatchResponse(MatchBase):
    squad_id: str
    match_id: str
    created_at: datetime
    score: Optional[tuple[int, int]]

class MatchListResponse(BaseModel):
    matches: list[MatchResponse]

#/matches
#/matches/{match_id}

class MatchDetailResponse(MatchResponse):
    team_a: TeamDetailData
    team_b: TeamDetailData
#todo: stats

class MatchUpdate(MatchBase):
    team_a: Optional[list]
    team_b: Optional[list]
    score: Optional[tuple[int, int]]

