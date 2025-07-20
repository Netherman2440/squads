

from dataclasses import dataclass
from datetime import datetime

from app.schemas import SquadResponse, SquadDetailResponse
from app.entities.stats_data import SquadStatsData

from .player_data import PlayerData
from .match_data import MatchData


@dataclass
class SquadData:
    squad_id: str
    name: str
    created_at: datetime    
    players_count: int
    owner_id: str

    def to_response(self) -> SquadResponse:
        return SquadResponse(
            squad_id=self.squad_id,
            name=self.name,
            created_at=self.created_at,
            players_count=self.players_count,
            owner_id=self.owner_id,
        )
    



@dataclass
class SquadDetailData(SquadData):
    players: list[PlayerData]
    matches: list[MatchData]
    stats: SquadStatsData
    #stats

    def to_response(self) -> SquadDetailResponse:

        players_response = [player.to_response() for player in self.players]
        matches_response = [match.to_response() for match in self.matches]
        return SquadDetailResponse(
            squad_id=self.squad_id,
            name=self.name,
            created_at=self.created_at,
            players_count=self.players_count,
            players=players_response,
            matches=matches_response,
            owner_id=self.owner_id,
            stats=self.stats.to_schema(),
        )

    