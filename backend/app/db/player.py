from datetime import datetime, timezone
import uuid
from sqlalchemy import UUID, Column, Integer, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from .database import Base


class Player(Base):
    __tablename__ = "players"

    player_id = Column(UUID, primary_key=True, default=lambda: uuid.uuid4())
    squad_id = Column(UUID, ForeignKey("squads.squad_id", ondelete="CASCADE"))
    name = Column(String, nullable=False)
    position = Column(String, nullable=False) # goalie or field
    base_score = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    # age = Column(Integer, nullable=False)
    # height = Column(Integer, nullable=False)
    # weight = Column(Integer, nullable=False)

    matches = relationship(
        "Match",
        secondary="team_players",
        primaryjoin="Player.player_id==TeamPlayer.player_id",
        secondaryjoin="TeamPlayer.match_id==Match.match_id",
        back_populates=None,
        viewonly=True
    )