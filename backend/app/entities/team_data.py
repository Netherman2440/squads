from dataclasses import dataclass

from .player_data import PlayerData

@dataclass
class TeamData:
    team_id: str
    name: str
    players: list[PlayerData]
    score: int
