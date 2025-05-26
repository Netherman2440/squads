from datetime import datetime, timezone
import uuid
from sqlalchemy import UUID, Column, Integer, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from .database import Base

class Tournament(Base):
    __tablename__ = "tournaments"

    squad_id = Column(UUID, ForeignKey("squads.squad_id", ondelete="CASCADE"))
    tournament_id = Column(UUID, primary_key=True, default=lambda: uuid.uuid4())
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    # List of tournament matches
    matches = relationship("Match", back_populates="tournament", cascade="all, delete-orphan")
     