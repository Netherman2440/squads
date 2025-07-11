from datetime import datetime
from pydantic import BaseModel, Field
from typing import Optional, TYPE_CHECKING
from app.constants import Position

class PlayerBase(BaseModel):
    """Base player schema with common fields"""
    name: str
    base_score: int


class PlayerCreate(PlayerBase):
    """Schema for creating a new player"""
    position: Optional[Position] = Field(None, description="Player position")
    


class PlayerUpdate(BaseModel):
    """Schema for updating player information"""
    name: Optional[str] = Field(None, min_length=1, max_length=100, description="Player name")
    base_score: Optional[int] = Field(None, ge=0, le=100, description="Player base score (0-100)")
    position: Optional[Position] = Field(None, description="Player position")
    score: Optional[float] = Field(None, ge=0, le=100, description="Current calculated score (0-100)")





class PlayerResponse(PlayerBase):
    """Schema for player response data"""

    squad_id: str
    player_id: str
    score: float
    position: Position
    matches_played: int
    created_at: datetime

class PlayerListResponse(BaseModel):
    """Schema for list of players"""
    players: list[PlayerResponse]


class PlayerDetailResponse(PlayerResponse):
    """Schema for detailed player response with matches"""
    matches: list["MatchResponse"]

if TYPE_CHECKING:
    from app.schemas.match_schemas import MatchResponse

from app.schemas.match_schemas import MatchResponse
PlayerDetailResponse.model_rebuild()