from dataclasses import dataclass
from typing import Optional


@dataclass
class TeamData:
    team_id: str
    name: Optional[str]
    color: Optional[str]
    score: int = 0


@dataclass
class TeamDetailData(TeamData):
    def __post_init__(self):
        from .player_data import PlayerData  # local import
        self.players: list[PlayerData]
