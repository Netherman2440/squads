from datetime import datetime
from pydantic import BaseModel

from app.schemas import MatchResponse, PlayerResponse
from app.schemas.stats_schemas import SquadStats

class SquadBase(BaseModel):
    name: str

class SquadCreate(SquadBase):
    pass

class SquadResponse(SquadBase):
    squad_id: str
    created_at: datetime
    players_count: int
    owner_id: str

#/squads
class SquadListResponse(BaseModel):
    squads: list[SquadResponse]

#/squads/{squad_id}
class SquadDetailResponse(SquadResponse):
    players: list[PlayerResponse]
    matches: list[MatchResponse]
    stats: SquadStats

class SquadUpdate(SquadBase):
    #update admin
    pass