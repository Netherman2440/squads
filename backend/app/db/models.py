import uuid
from datetime import datetime
from sqlalchemy import UUID, Column, Integer, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from .base import Base


class Squad(Base):
    __tablename__ = "squads"

    squad_id = Column(UUID, primary_key=True, default= lambda: uuid.uuid4())
    name = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.now(datetime.UTC))

class Player(Base):
    __tablename__ = "players"

    squad_id = Column(UUID, ForeignKey("squads.squad_id", ondelete="CASCADE"))
    player_id = Column(UUID, primary_key=True, default=lambda: uuid.uuid4())
    name = Column(String, nullable=False)
    position = Column(String, nullable=False) # goalie or field
    base_score = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=datetime.now(datetime.UTC))
    # age = Column(Integer, nullable=False)
    # height = Column(Integer, nullable=False)
    # weight = Column(Integer, nullable=False)
    
class Match(Base): 
    __tablename__ = "matches"

    squad_id = Column(UUID, ForeignKey("squads.squad_id", ondelete="CASCADE"))
    match_id = Column(UUID, primary_key=True, default=lambda: uuid.uuid4())
    created_at = Column(DateTime, default=datetime.now(datetime.UTC))

class Team(Base):
    __tablename__ = "teams"

    squad_id = Column(UUID, ForeignKey("squads.squad_id", ondelete="CASCADE"))
    match_id = Column(UUID, ForeignKey("matches.match_id", ondelete="CASCADE"))
    team_id = Column(UUID, primary_key=True, default=lambda: uuid.uuid4())
    color = Column(String, nullable=False) # white , black or color or maybe really a RGB value
    created_at = Column(DateTime, default=datetime.now(datetime.UTC))

class TeamPlayer(Base):
    __tablename__ = "team_players"

    squad_id = Column(UUID, ForeignKey("squads.squad_id", ondelete="CASCADE"))
    match_id = Column(UUID, ForeignKey("matches.match_id", ondelete="CASCADE"))
    team_id = Column(UUID, ForeignKey("teams.team_id", ondelete="CASCADE"))
    player_id = Column(UUID, ForeignKey("players.player_id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime, default=datetime.now(datetime.UTC))

class Tournament(Base):
    __tablename__ = "tournaments"

    squad_id = Column(UUID, ForeignKey("squads.squad_id", ondelete="CASCADE"))
    tournament_id = Column(UUID, primary_key=True, default=lambda: uuid.uuid4())
    created_at = Column(DateTime, default=datetime.now(datetime.UTC))

class TournamentMatch(Base):
    __tablename__ = "tournament_matches"

    squad_id = Column(UUID, ForeignKey("squads.squad_id", ondelete="CASCADE"))
    tournament_id = Column(UUID, ForeignKey("tournaments.tournament_id", ondelete="CASCADE"))
    match_id = Column(UUID, ForeignKey("matches.match_id", ondelete="CASCADE"))
    created_at = Column(DateTime, default=datetime.now(datetime.UTC))

class User(Base):
    __tablename__ = "users"

    user_id = Column(UUID, primary_key=True, default=lambda: uuid.uuid4())
    email = Column(String, nullable=False, unique=True)
    password_hash = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.now(datetime.UTC))

class UserPlayer(Base):
    __tablename__ = "user_players"

    user_id = Column(UUID, ForeignKey("users.user_id", ondelete="CASCADE"))
    player_id = Column(UUID, ForeignKey("players.player_id", ondelete="CASCADE"))
    squad_id = Column(UUID, ForeignKey("squads.squad_id", ondelete="CASCADE"))
    role = Column(String, nullable=False) # none, admin
    created_at = Column(DateTime, default=datetime.now(datetime.UTC))

    
