from datetime import datetime
from pydantic import BaseModel, EmailStr, Field

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
    password_hash: str
    created_at: datetime
    owned_squads: list[SquadResponse]
    squads: list[SquadResponse]
