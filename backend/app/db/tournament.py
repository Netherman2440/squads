from datetime import datetime, timezone
import uuid
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from .database import Base

class Tournament(Base):
    __tablename__ = "tournaments"

    squad_id = Column(String, ForeignKey("squads.squad_id", ondelete="CASCADE"))
    tournament_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    # List of tournament matches
    matches = relationship("Match", back_populates="tournament", cascade="all, delete-orphan")
     