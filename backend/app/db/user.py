from datetime import datetime, timezone
import uuid
from sqlalchemy import UUID, Column, String, DateTime
from sqlalchemy.orm import relationship
from .database import Base

class User(Base):
    __tablename__ = "users"

    user_id = Column(UUID, primary_key=True, default=lambda: uuid.uuid4())
    email = Column(String, nullable=False, unique=True)
    password_hash = Column(String, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    squads = relationship(
        "Squad",
        secondary="user_players",
        primaryjoin="User.user_id==UserPlayer.user_id",
        secondaryjoin="UserPlayer.squad_id==Squad.squad_id",
        back_populates=None
    )