# Import all models to ensure they are registered with SQLAlchemy
from ..database import Base, engine, SessionLocal
from .user import User
from .squad import Squad
from .player import Player
from .user_player import UserPlayer
from .team import Team
from .team_player import TeamPlayer
from .match import Match
from .tournament import Tournament
from .score_history import ScoreHistory

# Export commonly used items
__all__ = [
    "Base",
    "engine", 
    "SessionLocal",
    "User",
    "Squad", 
    "Player",
    "UserPlayer",
    "Team",
    "TeamPlayer", 
    "Match",
    "Tournament",
    "ScoreHistory"
]
