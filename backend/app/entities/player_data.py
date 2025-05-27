
from dataclasses import dataclass
from .position import Position
from .match_data import MatchData


@dataclass
class PlayerData:
    player_id: str
    name: str
    position: Position
    base_score: int
    score: float


@dataclass
class PlayerDetailData(PlayerData):
    matches: list[MatchData]
    #stats
