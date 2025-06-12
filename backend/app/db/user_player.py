from datetime import datetime, timezone
import uuid
from sqlalchemy import Column, String, ForeignKey, DateTime
from .database import Base

class UserPlayer(Base):
    __tablename__ = "user_players"

    user_id = Column(String(36), ForeignKey("users.user_id", ondelete="CASCADE"))
    player_id = Column(String(36), ForeignKey("players.player_id", ondelete="CASCADE"), primary_key=True)
    squad_id = Column(String(36), ForeignKey("squads.squad_id", ondelete="CASCADE"), primary_key=True)
    role = Column(String, nullable=False) # none, admin
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    
