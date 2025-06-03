from dataclasses import dataclass
from typing import Optional


@dataclass
class TeamData:
    team_id: str
    name: Optional[str]
    color: Optional[str]
    score: int = 0
    players_count: int = 0


@dataclass
class TeamDetailData(TeamData):
    def post_init(self):
        from .player_data import PlayerData
        self.players : list[PlayerData]
