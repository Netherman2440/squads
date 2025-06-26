from datetime import datetime
from pydantic import BaseModel, EmailStr, Field
from typing import Optional

from app.schemas import SquadResponse


class UserRegister(BaseModel):
    email: EmailStr = Field(..., description="User email address")
    password: str = Field(..., min_length=6, description="User password (minimum 6 characters)")

class UserLogin(BaseModel):
    email: EmailStr = Field(..., description="User email address")
    password: str = Field(..., description="User password")

class UserResponse(BaseModel):
    user_id: str
    email: str
    created_at: datetime
    owned_squads: list[SquadResponse]
    squads: list[SquadResponse]

class AuthResponse(BaseModel):
    access_token: str
    token_type: str
    user: Optional[UserResponse] = None
