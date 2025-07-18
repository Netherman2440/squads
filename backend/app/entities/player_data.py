from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional

from app.schemas import PlayerResponse, PlayerDetailResponse, PlayerRef
from app.models import Player
# Changed: Direct import instead of importing through app.entities
from app.entities.match_data import MatchData
from app.constants import Position
from app.entities.stats_data import PlayerStatsData


@dataclass
class PlayerData:
    squad_id: str
    player_id: str
    name: str
    created_at: datetime
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

    def to_response(self) -> PlayerResponse:
        return PlayerResponse(
            name=self.name,
            base_score=self.base_score,
            squad_id=self.squad_id,
            player_id=self.player_id,
            score=self.score,
            position=self.position,
            matches_played=self.matches_played,
            created_at=self.created_at,
        )
    
    def to_ref(self) -> PlayerRef:
        return PlayerRef(
            playerId=self.player_id,
            playerName=self.name,
        )
    
    @classmethod
    def from_orm(cls, orm_player: Player) -> 'PlayerData':
        return cls(
            squad_id=orm_player.squad_id,
            player_id=orm_player.player_id,
            name=orm_player.name,
            position=orm_player.position,
            base_score=orm_player.base_score,
            _score=orm_player.score,
            matches_played=len(orm_player.matches),
            created_at=orm_player.created_at,
        )

@dataclass
class PlayerDetailData(PlayerData):
    matches: list = field(default_factory=list)
    stats: PlayerStatsData = field(default_factory=PlayerStatsData)
    
    def to_response(self) -> PlayerDetailResponse:
        matches_response = [match.to_response() for match in self.matches]
        return PlayerDetailResponse(
            name=self.name,
            base_score=self.base_score,
            squad_id=self.squad_id,
            player_id=self.player_id,
            score=self.score,
            position=self.position,
            matches_played=self.matches_played,
            created_at=self.created_at,
            stats=self.stats.to_schema(),
        )

    @classmethod
    def from_orm(cls, orm_player: Player) -> 'PlayerDetailData':
        player_data = PlayerData.from_orm(orm_player)

        matches = []
        for match in orm_player.matches:
            matches.append(MatchData.from_orm(match))

        return cls(
            **player_data.__dict__,
            matches=matches,
        )
