from fastapi import HTTPException
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from app.models import User
from app.entities import UserData, SquadData
from app.services.squad_service import SquadService

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class UserService:
    def __init__(self, db: Session):
        self.db = db

    def user_to_data(self, user: User) -> UserData:
        squad_service = SquadService(self.db)
        return UserData(
            user_id=user.user_id,
            email=user.email,
            password_hash=user.password_hash,
            created_at=user.created_at,
            owned_squads=[squad_service.squad_to_data(squad) for squad in user.owned_squads],
            squads=[squad_service.squad_to_data(squad) for squad in user.squads]
        )

    def get_user_by_id(self, user_id: str) -> UserData:
        user = self.db.query(User).filter(User.user_id == user_id).first()
        if not user:
            return None
        
        return self.user_to_data(user)

    def register(self, email: str, password: str) -> UserData:
        # Check if user already exists
        existing_user = self.db.query(User).filter(User.email == email).first()
        if existing_user:
            raise HTTPException(status_code=400, detail="Email already registered")
        
        # Hash the password
        hashed_password = pwd_context.hash(password)
        
        user = User(email=email, password_hash=hashed_password)
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return self.user_to_data(user)

    def login(self, email: str, password: str) -> UserData:
        user = self.db.query(User).filter(User.email == email).first()
        if not user:
            raise HTTPException(status_code=401, detail="Invalid credentials")
        
        if not pwd_context.verify(password, user.password_hash):    
            raise HTTPException(status_code=401, detail="Invalid credentials")
        
        return self.user_to_data(user)

    def logout(self):
        pass
