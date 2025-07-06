from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel

from app.schemas.player_schemas import PlayerResponse

class MatchBase(BaseModel):
    pass

#/matches

class MatchCreate(MatchBase):
    team_a_ids: list[str]
    team_b_ids: list[str]
    team_a_name: Optional[str] = None
    team_b_name: Optional[str] = None

class MatchResponse(MatchBase):
    squad_id: str
    match_id: str
    created_at: datetime
    score: Optional[tuple[int, int]]

class MatchListResponse(BaseModel):
    matches: list[MatchResponse]

#/matches
#/matches/{match_id}

class TeamDetailResponse(BaseModel):
    squad_id: str
    match_id: str
    team_id: str
    score: Optional[int] = None
    name: Optional[str] = None
    color: Optional[str] = None
    players_count: int = 0
    players: list[PlayerResponse]

class MatchDetailResponse(BaseModel):
    squad_id: str
    match_id: str
    created_at: datetime
    team_a: TeamDetailResponse
    team_b: TeamDetailResponse
#todo: stats

class TeamUpdate(BaseModel):
    team_id: str
    players: Optional[List[str]] = None  # list of player IDs
    score: Optional[int] = None

class MatchUpdate(MatchBase):
    team_a: TeamUpdate
    team_b: TeamUpdate

