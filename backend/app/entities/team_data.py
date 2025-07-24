from dataclasses import dataclass
from typing import Optional
from app.schemas.match_schemas import TeamDetailResponse
from typing import TYPE_CHECKING
if TYPE_CHECKING:
    from app.entities.player_data import PlayerData


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
    players: list["PlayerData"] = None

    def to_response(self) -> TeamDetailResponse:
        return TeamDetailResponse(
            squad_id=self.squad_id,
            match_id=self.match_id,
            team_id=self.team_id,
            score=self.score,
            name=self.name,
            color=self.color,
            players_count=self.players_count,
            players=[p.to_response() for p in self.players] if self.players else [],
        )

