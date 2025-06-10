from datetime import datetime, timezone
from sqlalchemy import Column, DateTime, ForeignKey, String, PrimaryKeyConstraint, Float, Integer
from sqlalchemy.orm import relationship

from app.db.database import Base


class ScoreHistory(Base):
    __tablename__ = "score_history"

    match_id = Column(String, ForeignKey("matches.match_id", ondelete="CASCADE"), nullable=True)
    player_id = Column(String, ForeignKey("players.player_id", ondelete="CASCADE"))
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    previous_score = Column(Float, nullable=False)
    new_score = Column(Float, nullable=True)
    delta = Column(Float, nullable=False)

    __table_args__ = (
        PrimaryKeyConstraint('player_id', 'match_id'),
    )
