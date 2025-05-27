

from dataclasses import dataclass
from datetime import datetime

from .player_data import PlayerData
from .match_data import MatchData


@dataclass
class SquadData:
    squad_id: str
    name: str
    created_at: datetime    
    players_count: int


@dataclass
class SquadDetailData(SquadData):
    players: list[PlayerData]
    matches: list[MatchData]
    #stats

    