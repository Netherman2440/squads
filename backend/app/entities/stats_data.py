
from datetime import datetime
import json
from typing import Optional, TYPE_CHECKING
from app.constants import CarouselType
# Changed: Direct imports instead of importing through app.entities
from app.entities.match_data import MatchData
from app.schemas import CarouselStat, MatchRef
from app.schemas.stats_schemas import PlayerStats, ScoreHistorySchema, SquadStats

# Import only for type checking to avoid circular import
if TYPE_CHECKING:
    from app.entities.player_data import PlayerData

class ScoreHistoryData:
    def __init__(self, score: float, created_at: datetime, match_ref: Optional[MatchRef] = None):
        self.score = score
        self.created_at = created_at
        self.match_ref = match_ref
    
    def to_schema(self):
        return ScoreHistorySchema(
            score=self.score,
            created_at=self.created_at,
            match_ref=self.match_ref
        )

class CarouselData:
    def __init__(self, carousel_type: CarouselType,  value, ref: Optional["PlayerData | MatchData"] = None):
        self.carousel_type = carousel_type
        self.value = value
        self.ref = ref

    def to_schema(self):

        return CarouselStat(
            type=self.carousel_type,
            ref=self.ref if self.ref else None,
            value=self.value
        )

    
class Teammate_Ref:
    def __init__(self, player_id: str):
        self.player_id = player_id
        self.games_together = 0
        self.wins_together = 0
        self.losses_together = 0
        self.games_against = 0
        self.wins_against_him = 0
        self.losses_against_him = 0


    @classmethod
    def from_player_Data(cls, player_data: "PlayerData"):
        return cls(player_id=player_data.player_id)

class PlayerStatsData:
    def __init__(self,
                 player_id: str,
                 base_score: int,
                 score: float,
                 win_streak: int,
                 loss_streak: int,
                 biggest_win_streak: int,
                 biggest_loss_streak: int,
                 goals_scored: int,
                 goals_conceded: int,
                 avg_goals_per_match: float,
                 avg_score: tuple[float, float],
                 total_matches: int,
                 total_wins: int,
                 total_losses: int,
                 total_draws: int,
                 score_history: list[ScoreHistoryData],
                 carousel_stats: list[CarouselData]):
        self.player_id = player_id
        self.base_score = base_score
        self.score = score
        self.win_streak = win_streak
        self.loss_streak = loss_streak
        self.biggest_win_streak = biggest_win_streak
        self.biggest_loss_streak = biggest_loss_streak
        self.goals_scored = goals_scored
        self.goals_conceded = goals_conceded
        self.avg_goals_per_match = avg_goals_per_match
        self.avg_score = avg_score
        self.total_matches = total_matches
        self.total_wins = total_wins    
        self.total_losses = total_losses
        self.total_draws = total_draws
        self.score_history = score_history
        self.carousel_stats = carousel_stats
    
    def to_schema(self):
        return PlayerStats(
            player_id=self.player_id,
            base_score=self.base_score,
            score=self.score,
            win_streak=self.win_streak,
            loss_streak=self.loss_streak,
            biggest_win_streak=self.biggest_win_streak,
            biggest_loss_streak=self.biggest_loss_streak,
            goals_scored=self.goals_scored, 
            goals_conceded=self.goals_conceded,
            avg_goals_per_match=self.avg_goals_per_match,
            avg_score=self.avg_score,
            total_matches=self.total_matches,
            total_wins=self.total_wins,
            total_losses=self.total_losses,
            total_draws=self.total_draws,
            score_history=[score_history.to_schema() for score_history in self.score_history],
            carousel_stats=[carousel_stat.to_schema() for carousel_stat in self.carousel_stats],
        )

class SquadStatsData:
    def __init__(self,  
                 squad_id: str,
                 created_at: datetime,
                 total_players: int,
                 total_matches: int,
                 total_goals: int,
                 avg_goals_per_match: float,
                 avg_score: tuple[float, float],
                 carousel_stats: list[CarouselData]):
        self.squad_id = squad_id
        self.created_at = created_at
        self.total_players = total_players
        self.total_matches = total_matches
        self.total_goals = total_goals
        self.avg_goals_per_match = avg_goals_per_match
        self.avg_score = avg_score
        self.carousel_stats = carousel_stats
    
    def to_schema(self):
        return SquadStats(
            squad_id=self.squad_id,
            created_at=self.created_at,
            total_players=self.total_players,
            total_matches=self.total_matches,
            total_goals=self.total_goals,
            avg_goals_per_match=self.avg_goals_per_match,
            avg_score=self.avg_score,
            carousel_stats=[carousel_stat.to_schema() for carousel_stat in self.carousel_stats],
        )