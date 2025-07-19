from dataclasses import Field
from datetime import datetime
from typing import Optional
from pydantic import BaseModel
from app.constants import CarouselType




class PlayerRef(BaseModel):
  playerId: str
  playerName: str

class MatchRef(BaseModel):
  matchId: str
  matchDate: datetime
  score: Optional[tuple[int, int]] = None


class ScoreHistorySchema(BaseModel):
  score: float
  created_at: datetime
  match_ref: Optional[MatchRef] = None


class CarouselStat(BaseModel):
  type: CarouselType
  value: int | list[int] | float | list[float] | str | list[str]
  ref: Optional[PlayerRef | MatchRef] = None

class PlayerStats(BaseModel):
  player_id: str
  base_score: int
  score: float
  win_streak: int
  loss_streak: int
  biggest_win_streak: int
  biggest_loss_streak: int
  goals_scored: int
  goals_conceded: int
  avg_goals_per_match: float
  avg_score: tuple[float, float]
  total_matches: int
  total_wins: int
  total_losses: int
  total_draws: int
  score_history: list[ScoreHistorySchema]
  carousel_stats: list[CarouselStat]

class SquadStats(BaseModel):
  squad_id: str
  created_at: datetime
  total_players: int
  total_matches: int
  total_goals: int
  avg_goals_per_match: float
  avg_score: tuple[float, float]
  carousel_stats: list[CarouselStat]






