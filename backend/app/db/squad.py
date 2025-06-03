from datetime import datetime, timezone
import uuid
from sqlalchemy import UUID, Column, String, DateTime
from sqlalchemy.orm import relationship
from .database import Base

class Squad(Base):
    __tablename__ = "squads"

    squad_id = Column(String, primary_key=True, default= lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    created_at = Column(DateTime, default= lambda: datetime.now(timezone.utc))
    # List of players in the squad
    players = relationship("Player", back_populates=None, cascade="all, delete-orphan")
    # List of matches in the squad
    matches = relationship("Match", back_populates=None, cascade="all, delete-orphan")
