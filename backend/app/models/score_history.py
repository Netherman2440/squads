from datetime import datetime, timezone
import uuid
from sqlalchemy import Column, DateTime, ForeignKey, String, PrimaryKeyConstraint, Float, Integer

from ..database import Base


class ScoreHistory(Base):
    __tablename__ = "score_history"

    score_history_id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    match_id = Column(String(36), ForeignKey("matches.match_id", ondelete="CASCADE"), nullable=True)
    player_id = Column(String(36), ForeignKey("players.player_id", ondelete="CASCADE"))
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    previous_score = Column(Float, nullable=False)
    new_score = Column(Float, nullable=True)
    delta = Column(Float, nullable=False)

    __table_args__ = (
        PrimaryKeyConstraint('score_history_id'),
    )
