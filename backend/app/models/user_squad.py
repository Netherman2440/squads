from datetime import datetime, timezone
from sqlalchemy import Column, PrimaryKeyConstraint, String, ForeignKey, DateTime
from ..database import Base

class UserSquad(Base):
    __tablename__ = "user_squads"

    user_id = Column(String(36), ForeignKey("users.user_id", ondelete="CASCADE"))
    squad_id = Column(String(36), ForeignKey("squads.squad_id", ondelete="CASCADE"))
    player_id = Column(String(36), ForeignKey("players.player_id", ondelete="CASCADE"), nullable = True)
    role = Column(String(255), nullable=True) # none, admin
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    
    __table_args__ = (
        PrimaryKeyConstraint('user_id', 'squad_id'),
    )