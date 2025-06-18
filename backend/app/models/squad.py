from datetime import datetime, timezone
import uuid
from sqlalchemy import UUID, Column, ForeignKey, String, DateTime
from sqlalchemy.orm import relationship
from ..database import Base

class Squad(Base):
    __tablename__ = "squads"

    squad_id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(255), nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    
    owner_id = Column(String(36), ForeignKey("users.user_id"), nullable=False)
    
    # List of players in the squad - automatically filtered by squad_id
    players = relationship("Player", 
                         foreign_keys="Player.squad_id",
                         primaryjoin="Squad.squad_id==Player.squad_id")
    
    # List of matches in the squad - automatically filtered by squad_id
    matches = relationship("Match", 
                         foreign_keys="Match.squad_id",
                         primaryjoin="Squad.squad_id==Match.squad_id")

    owner = relationship("User", back_populates="owned_squads")

    # Users associated with this squad through UserSquad table
    users = relationship("UserSquad", 
                             foreign_keys="UserSquad.squad_id",
                             primaryjoin="Squad.squad_id==UserSquad.squad_id",
                             viewonly=True)
