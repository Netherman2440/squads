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

class StatType(Enum):
#squad
    RECENT_MATCH = "recent_match"
    NEXT_MATCH = "next_match"
    BEST_PLAYER = "best_player"
    BEST_DELTA = "best_delta" # największa różnica pomiędzy score a base_score

    DOMINATION = "domination" # kto z kim najczęściej wygrywa
    TEAMWORK = "teamwork" # kto będąc z kim w drużynie najczęściej wygrywa


#both    
    BIGGEST_WIN = "biggest_win" #największa różnica bramek w meczu (a dla gracza to jego największe zwycięstwo)
    WIN_STREAK = "win_streak" # najdłuższa seria wygranych meczów
    WIN_RATIO = "win_ratio" # procent wygranych meczów
    AVG_GOALS = "avg_goals" # średnia bramek w meczu

#player
    BIGGEST_LOSS = "biggest_loss" #  największe porażka gracza
    TOP_TEAMMATE = "top_teammate"   # najczęstszy partner
    WIN_TEAMMATE = "win_teammate"   # najczęściej wygrywający partner
    WORST_TEAMMATE = "worst_teammate" # najczęściej przegrywający partner

    TOP_RIVAL = "top_rival" # najczęstszy przeciwnik
    NEMEZIS = "nemezis" # najczęściej wygrywający przeciwnik
    WORST_RIVAL = "worst_rival" # najczęściej przegrywający przeciwnik

    H2H = "h2h" # head to head z innym graczem
    AVG_GOALS_AGAINST = "avg_goals_against" # średnia bramek przeciwników w meczu





