from pydantic import BaseModel

from app.schemas import PlayerResponse


class DraftBase(BaseModel):
    players_ids: list[str]

class DraftCreate(DraftBase):
    pass

class DraftResponse(BaseModel):
    team_a: list[PlayerResponse]
    team_b: list[PlayerResponse]

class DraftListResponse(BaseModel):
    drafts: list[DraftResponse]


