from dataclasses import dataclass, field
from typing import Optional
from .position import Position


@dataclass
class PlayerData:
    squad_id: str
    player_id: str
    name: str
    base_score: int
    _score: Optional[float] = None
    position: Position = Position.NONE
    matches_played: int = 0

    @property
    def score(self) -> float:
        # Return _score if set, otherwise base_score
        if self._score is None:
            self._score = self.base_score
        return self._score
    @score.setter
    def score(self, value: float):
        # Set _score
        self._score = value


@dataclass
class PlayerDetailData(PlayerData):
    matches: list = field(default_factory=list)
    

