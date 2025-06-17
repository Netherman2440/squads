
from datetime import datetime
from pydantic import BaseModel

from app.schemas import SquadResponse


class UserRegister(BaseModel):
    email: str
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

class UserResponse(BaseModel):
    user_id: str
    email: str
    password_hash: str
    created_at: datetime
    owned_squads: list[SquadResponse]
