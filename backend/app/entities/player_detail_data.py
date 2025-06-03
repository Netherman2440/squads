from dataclasses import dataclass
from . import PlayerData


@dataclass
class PlayerDetailData(PlayerData):
    
    #stats
    def post_init(self):
        from .match_data import MatchData
        self.matches : list[MatchData]
