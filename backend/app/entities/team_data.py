from dataclasses import dataclass
from typing import Optional

@dataclass
class TeamData:
    squad_id: str
    match_id: str
    team_id: str
    name: Optional[str]
    color: Optional[str]
    score: int = 0
    players_count: int = 0


@dataclass
class TeamDetailData(TeamData):
    players: list = None

