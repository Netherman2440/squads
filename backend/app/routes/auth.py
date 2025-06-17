from fastapi import APIRouter
from fastapi.params import Depends
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.services import UserService

router = APIRouter()

def get_db() -> Session:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_user_service(db = Depends(get_db)):
    return UserService(db)
@router.post("/login")
def login():
    return {"message": "Login successful"}

@router.post("/register", response_model=UserData)
def register():
    return {"message": "Register successful"}

@router.post("/logout")
def logout():
    return {"message": "Logout successful"}
