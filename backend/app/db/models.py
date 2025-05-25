from datetime import datetime, timezone
import uuid
from sqlalchemy import UUID, Column, Integer, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from .database import Base


class Squad(Base):
    __tablename__ = "squads"

    squad_id = Column(UUID, primary_key=True, default= lambda: uuid.uuid4())
    name = Column(String, nullable=False)
    created_at = Column(DateTime, default= lambda: datetime.now(timezone.utc))
    # List of players in the squad
    players = relationship("Player", back_populates=None, cascade="all, delete-orphan")
    # List of matches in the squad
    matches = relationship("Match", back_populates=None, cascade="all, delete-orphan")

class Player(Base):
    __tablename__ = "players"

    squad_id = Column(UUID, ForeignKey("squads.squad_id", ondelete="CASCADE"))
    player_id = Column(UUID, primary_key=True, default=lambda: uuid.uuid4())
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

class Tournament(Base):
    __tablename__ = "tournaments"

    squad_id = Column(UUID, ForeignKey("squads.squad_id", ondelete="CASCADE"))
    tournament_id = Column(UUID, primary_key=True, default=lambda: uuid.uuid4())
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    # List of tournament matches
    matches = relationship("Match", back_populates="tournament", cascade="all, delete-orphan")
     
class Match(Base): 
    __tablename__ = "matches"

    squad_id = Column(UUID, ForeignKey("squads.squad_id", ondelete="CASCADE"))
    match_id = Column(UUID, primary_key=True, default=lambda: uuid.uuid4())
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    tournament_id = Column(UUID, ForeignKey("tournaments.tournament_id", ondelete="CASCADE"), nullable=True)

    # List of teams in the match
    teams = relationship("Team", back_populates="match", cascade="all, delete-orphan")

    tournament = relationship("Tournament", back_populates="matches")

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

class TeamPlayer(Base):
    __tablename__ = "team_players"

    squad_id = Column(UUID, ForeignKey("squads.squad_id", ondelete="CASCADE"))
    match_id = Column(UUID, ForeignKey("matches.match_id", ondelete="CASCADE"))
    team_id = Column(UUID, ForeignKey("teams.team_id", ondelete="CASCADE"))
    player_id = Column(UUID, ForeignKey("players.player_id", ondelete="SET NULL"), nullable=True, primary_key=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

class User(Base):
    __tablename__ = "users"

    user_id = Column(UUID, primary_key=True, default=lambda: uuid.uuid4())
    email = Column(String, nullable=False, unique=True)
    password_hash = Column(String, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    squads = relationship(
        "Squad",
        secondary="user_players",
        primaryjoin="User.user_id==UserPlayer.user_id",
        secondaryjoin="UserPlayer.squad_id==Squad.squad_id",
        back_populates=None
    )

class UserPlayer(Base):
    __tablename__ = "user_players"

    user_id = Column(UUID, ForeignKey("users.user_id", ondelete="CASCADE"))
    player_id = Column(UUID, ForeignKey("players.player_id", ondelete="CASCADE"), primary_key=True)
    squad_id = Column(UUID, ForeignKey("squads.squad_id", ondelete="CASCADE"))
    role = Column(String, nullable=False) # none, admin
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    

    
