from enum import Enum

class Position(Enum):
    """Player position enumeration"""
    NONE = "none"
    GOALIE = "goalie"
    FIELD = "field"
    DEFENDER = "defender"
    MIDFIELDER = "midfielder"
    FORWARD = "forward" 

class UserRole(Enum):
    """User role enumeration"""
    NONE = "none"
    OWNER = "owner"
    ADMIN = "admin"
    MODERATOR = "moderator"
    MEMBER = "member"

class CarouselType(Enum):
  BIGGEST_WIN = 'biggest_win'
  BIGGEST_LOSS = 'biggest_loss'
  WIN_RATIO = 'win_ratio'
  TOP_TEAMMATE = 'top_teammate'
  WIN_TEAMMATE = 'win_teammate' 
  WORST_TEAMMATE = 'worst_teammate'  #?
  NEMEZIS = 'nemezis'
  WORST_RIVAL = 'worst_rival'
  H2H = 'h2h'
 
 
  RECENT_MATCH = "recent_match"
  NEXT_MATCH = "next_match"
  #biggest win for squad

  BEST_PLAYER = "best_player"
  BEST_DELTA = "best_delta"
  WIN_STREAK = "win_streak"
  
  DOMINATION = "domination"
  GAMES_PLAYED_TOGETHER = "games_played_together"
  WIN_RATE_TOGETHER = "win_rate_together"
    




