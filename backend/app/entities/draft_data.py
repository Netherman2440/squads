from dataclasses import dataclass

# Changed: Direct imports instead of importing through app.entities
from app.entities.player_data import PlayerData
from app.entities.team_data import TeamData
from app.schemas.draft_schemas import DraftResponse

@dataclass
class DraftData:
    team_a: list[PlayerData]
    team_b: list[PlayerData]

    def to_response(self) -> DraftResponse:
        return DraftResponse(
            team_a=[player.to_response() for player in self.team_a],
            team_b=[player.to_response() for player in self.team_b],
        )
