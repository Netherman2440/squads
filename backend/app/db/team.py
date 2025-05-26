from datetime import datetime, timezone
import uuid
from sqlalchemy import UUID, Column, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from .database import Base

class Team(Base):
    __tablename__ = "teams"

    squad_id = Column(UUID, ForeignKey("squads.squad_id", ondelete="CASCADE"))
    match_id = Column(UUID, ForeignKey("matches.match_id", ondelete="CASCADE"))
    team_id = Column(UUID, primary_key=True, default=lambda: uuid.uuid4())
    color = Column(String, nullable=False) # white , black or color or maybe really a RGB value
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    # Reference to match
    match = relationship("Match", back_populates="teams")
    # List of players in the team
    players = relationship(
        "Player",
        secondary="team_players",
        primaryjoin="Team.team_id==TeamPlayer.team_id",
        secondaryjoin="TeamPlayer.match_id==Match.match_id",
        back_populates=None,
        viewonly=True
    )