from datetime import datetime, timezone
import uuid
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from ..database import Base

class Tournament(Base):
    __tablename__ = "tournaments"

    squad_id = Column(String(36), ForeignKey("squads.squad_id", ondelete="CASCADE"))
    tournament_id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(255), nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    # List of tournament matches
    matches = relationship("Match", back_populates="tournament")

