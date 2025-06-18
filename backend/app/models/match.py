from datetime import datetime, timezone
import uuid
from sqlalchemy import String, Column, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from ..database import Base


class Match(Base): 
    __tablename__ = "matches"

    squad_id = Column(String(36), ForeignKey("squads.squad_id", ondelete="CASCADE"))
    match_id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    tournament_id = Column(String(36), ForeignKey("tournaments.tournament_id", ondelete="CASCADE"), nullable=True)


    # List of teams in the match
    teams = relationship("Team",
                         foreign_keys="Team.match_id",
                         primaryjoin="Match.match_id==Team.match_id",
                         back_populates="match",
                         )

    tournament = relationship("Tournament", back_populates="matches")

