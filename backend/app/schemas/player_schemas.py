from pydantic import BaseModel, Field
from typing import Optional
from app.constants import Position
from app.schemas.match_schemas import MatchResponse

class PlayerBase(BaseModel):
    """Base player schema with common fields"""
    name: str
    base_score: int


class PlayerCreate(PlayerBase):
    """Schema for creating a new player"""
    squad_id: str
    position: Optional[Position] = Field(None, description="Player position")
    


class PlayerUpdate(BaseModel):
    """Schema for updating player information"""
    player_id: str
    name: Optional[str] = Field(None, min_length=1, max_length=100, description="Player name")
    base_score: Optional[int] = Field(None, ge=0, le=100, description="Player base score (0-100)")
    position: Optional[Position] = Field(None, description="Player position")
    score: Optional[float] = Field(None, ge=0, description="Current calculated score")





class PlayerResponse(PlayerBase):
    """Schema for player response data"""

    squad_id: str
    player_id: str
    score: float
    position: Position
    matches_played: int

class PlayerListResponse(BaseModel):
    """Schema for list of players"""
    players: list[PlayerResponse]


class PlayerDetailResponse(PlayerResponse):
    """Schema for detailed player response with matches"""
    matches: list[MatchResponse]