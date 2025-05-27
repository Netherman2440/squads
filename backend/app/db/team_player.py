from datetime import datetime, timezone
from sqlalchemy import UUID, Column, ForeignKey, DateTime, PrimaryKeyConstraint
from .database import Base


class TeamPlayer(Base):
    __tablename__ = "team_players"

    squad_id = Column(UUID, ForeignKey("squads.squad_id", ondelete="CASCADE"))
    match_id = Column(UUID, ForeignKey("matches.match_id", ondelete="CASCADE"), nullable=False)
    team_id = Column(UUID, ForeignKey("teams.team_id", ondelete="CASCADE"), nullable=False)
    player_id = Column(UUID, ForeignKey("players.player_id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    __table_args__ = (
        PrimaryKeyConstraint('player_id', 'team_id', 'match_id'),
    )