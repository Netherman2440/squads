from pydantic import BaseModel

from app.schemas import PlayerResponse


class DraftBase(BaseModel):
    squad_id: str
    players: list[PlayerResponse]

class DraftCreate(DraftBase):
    pass

class DraftResponse(DraftBase):
    team_a: list[PlayerResponse]
    team_b: list[PlayerResponse]
    team_a_score: int
    team_b_score: int

class DraftListResponse(BaseModel):
    drafts: list[DraftResponse]


