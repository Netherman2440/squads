from dataclasses import dataclass
from typing import Optional
from .position import Position


@dataclass
class PlayerData:
    squad_id: str
    player_id: str
    name: str
    base_score: int
    position: Optional[Position] = Position.NONE
    matches_played: Optional[int] = 0
    _score: Optional[float] = 0.0

    @property
    def score(self) -> float:
        # Return _score if set, otherwise base_score
        return self._score if self._score is not None else self.base_score
    @score.setter
    def score(self, value: float):
        # Set _score
        self._score = value


