from sqlalchemy.orm import Session

from app.models import User

class UserService:
    def __init__(self, db: Session):
        self.db = db

    def register(self, email: str, password: str):
        user = User(email=email, password=password)
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def login(self, email: str, password: str):
        pass

    def logout(self):
        pass
