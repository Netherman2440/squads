from pydantic import BaseModel

from app.schemas import PlayerResponse


class DraftBase(BaseModel):
    players: list[PlayerResponse]

class DraftCreate(DraftBase):
    pass

class DraftResponse(DraftBase):
    draft_id: str


