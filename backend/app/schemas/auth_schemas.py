from datetime import datetime
from pydantic import BaseModel, Field
from typing import Optional

from app.schemas import SquadResponse


class UserRegister(BaseModel):
    username: str = Field(..., description="User username")
    password: str = Field(..., min_length=3, description="User password (minimum 3 characters)")

class UserLogin(BaseModel):
    username: str = Field(..., description="User username")
    password: str = Field(..., description="User password")

class UserResponse(BaseModel):
    user_id: str
    username: str
    created_at: datetime
    owned_squads: list[SquadResponse]
    squads: list[SquadResponse]

class AuthResponse(BaseModel):
    access_token: str
    token_type: str
    user: Optional[UserResponse] = None
