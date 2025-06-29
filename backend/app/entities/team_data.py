from dataclasses import dataclass
from typing import Optional

@dataclass
class TeamData:
    squad_id: str
    match_id: str
    team_id: str
    score: Optional[int] = None
    name: Optional[str] = None
    color: Optional[str] = None
    players_count: int = 0


@dataclass
class TeamDetailData(TeamData):
    players: list = None

