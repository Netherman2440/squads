from datetime import datetime, timezone
import uuid
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from ..database import Base

class Team(Base):
    __tablename__ = "teams"

    squad_id = Column(String(36), ForeignKey("squads.squad_id", ondelete="CASCADE"))
    match_id = Column(String(36), ForeignKey("matches.match_id", ondelete="CASCADE"))
    team_id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    color = Column(String(255), nullable=False) # white , black or color or maybe really a RGB value
    name = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    score = Column(Integer, nullable=False, default=0)
    # Reference to match
    match = relationship("Match", back_populates="teams")
    # List of players in the team
    players = relationship(
        "Player",
        secondary="team_players",
        primaryjoin="Team.team_id==TeamPlayer.team_id",
        secondaryjoin="TeamPlayer.player_id==Player.player_id",
        back_populates=None,
        viewonly=True
    )