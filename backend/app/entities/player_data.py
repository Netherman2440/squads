
from dataclasses import dataclass
from .position import Position
from .match_data import MatchData

@dataclass
class PlayerData:
    player_id: str
    squad_id: str
    name: str
    position: Position
    base_score: int
    matches: list[MatchData]

    def score(self) -> float:
        return self.base_score + sum(match.score() for match in self.matches)
