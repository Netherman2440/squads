from dataclasses import dataclass
from datetime import datetime

from .squad_data import SquadData
from app.schemas import UserResponse
@dataclass
class UserData:
    user_id: str
    email: str
    password_hash: str
    created_at: datetime            
    owned_squads: list[SquadData]

    def to_response(self):
        return UserResponse(
            user_id=self.user_id,
            email=self.email,
            password_hash=self.password_hash,
            created_at=self.created_at,
            owned_squads=[squad.to_response() for squad in self.owned_squads]
        )