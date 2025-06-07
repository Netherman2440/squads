from datetime import datetime
from pydantic import BaseModel

from app.schemas import MatchResponse, PlayerResponse

class SquadBase(BaseModel):
    name: str

class SquadCreate(SquadBase):
    pass

class SquadResponse(SquadBase):
    squad_id: str
    created_at: datetime
    players_count: int

#/squads
class SquadListResponse(BaseModel):
    squads: list[SquadResponse]

#/squads/{squad_id}
class SquadDetailResponse(SquadResponse):
    players: list[PlayerResponse]
    matches: list[MatchResponse]

class SquadUpdate(SquadBase):
    #update admin
    pass