from datetime import datetime, timezone
import uuid
from sqlalchemy import Column, Float, Integer, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from ..database import Base


class Player(Base):
    __tablename__ = "players"

    player_id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    squad_id = Column(String(36), ForeignKey("squads.squad_id", ondelete="CASCADE"))
    name = Column(String(255), nullable=False)
    position = Column(String(255), nullable=False) # goalie or field
    base_score = Column(Integer, nullable=False)
    score = Column(Float, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    # age = Column(Integer, nullable=False)
    # height = Column(Integer, nullable=False)
    # weight = Column(Integer, nullable=False)

    matches = relationship(
        "Match",
        secondary="team_players",
        primaryjoin="Player.player_id==TeamPlayer.player_id",
        secondaryjoin="Match.match_id==TeamPlayer.match_id",
        viewonly=True
    )

    score_history = relationship(
        "ScoreHistory",
        foreign_keys="ScoreHistory.player_id",
        cascade="all, delete-orphan"
    )
