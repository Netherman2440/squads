import datetime
from typing import Optional
from pydantic import BaseModel

from app.entities import TeamDetailData

class MatchBase(BaseModel):
    pass

#/matches

class MatchCreate(MatchBase):
    teams: list

class MatchResponse(MatchBase):
    squad_id: str
    match_id: str
    created_at: datetime
    score: tuple[int, int]

class MatchListResponse(BaseModel):
    matches: list[MatchResponse]

#/matches
#/matches/{match_id}

class MatchDetailResponse(MatchResponse):
    team_a: TeamDetailData
    team_b: TeamDetailData
#todo: stats

class MatchUpdate(MatchBase):
    score: Optional[tuple[int, int]]

