from datetime import datetime, timezone
import uuid
from sqlalchemy import Column, String, DateTime
from sqlalchemy.orm import relationship
from .database import Base

class User(Base):
    __tablename__ = "users"

    user_id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String(255), nullable=False, unique=True)
    password_hash = Column(String(255), nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    squads = relationship(
        "Squad",
        secondary="user_players",
        primaryjoin="User.user_id==UserPlayer.user_id",
        secondaryjoin="UserPlayer.squad_id==Squad.squad_id",
        back_populates=None
    )