from datetime import datetime, timezone
from sqlalchemy import UUID, Column, ForeignKey, DateTime
from .database import Base


class TeamPlayer(Base):
    __tablename__ = "team_players"

    squad_id = Column(UUID, ForeignKey("squads.squad_id", ondelete="CASCADE"))
    match_id = Column(UUID, ForeignKey("matches.match_id", ondelete="CASCADE"))
    team_id = Column(UUID, ForeignKey("teams.team_id", ondelete="CASCADE"))
    player_id = Column(UUID, ForeignKey("players.player_id", ondelete="SET NULL"), nullable=True, primary_key=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))