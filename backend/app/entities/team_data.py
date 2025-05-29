from dataclasses import dataclass
from typing import Optional

from app.entities import PlayerData


@dataclass
class TeamData:
    team_id: str
    name: Optional[str]
    color: Optional[str]
    score: int = 0


@dataclass
class TeamDetailData(TeamData):
    players: list[PlayerData]
