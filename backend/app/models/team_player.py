from datetime import datetime, timezone
from sqlalchemy import String, Column, ForeignKey, DateTime, PrimaryKeyConstraint
from ..database import Base


class TeamPlayer(Base):
    __tablename__ = "team_players"

    squad_id = Column(String(36), ForeignKey("squads.squad_id", ondelete="CASCADE"))
    match_id = Column(String(36), ForeignKey("matches.match_id", ondelete="CASCADE"))
    team_id = Column(String(36), ForeignKey("teams.team_id", ondelete="CASCADE"))
    player_id = Column(String(36), ForeignKey("players.player_id", ondelete="CASCADE"))
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    __table_args__ = (
        PrimaryKeyConstraint('player_id', 'team_id', 'match_id'),
    )