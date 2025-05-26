
from dataclasses import dataclass
from datetime import datetime

from .squad_data import SquadData

@dataclass
class UserData:
    user_id: str
    email: str
    password_hash: str
    created_at: datetime
    squads: list[SquadData]
