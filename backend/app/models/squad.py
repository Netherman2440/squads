from datetime import datetime, timezone
import uuid
from sqlalchemy import UUID, Column, ForeignKey, String, DateTime
from sqlalchemy.orm import relationship
from ..database import Base

class Squad(Base):
    __tablename__ = "squads"

    squad_id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(255), nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    
    owner_id = Column(String(36), ForeignKey("users.user_id"), nullable=False)
    # List of players in the squad
    players = relationship("Player", back_populates=None, cascade="all, delete-orphan")
    # List of matches in the squad
    matches = relationship("Match", back_populates=None, cascade="all, delete-orphan")

    owner = relationship("User", back_populates="owned_squads")
