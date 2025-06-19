from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.services import UserService
from app.schemas import UserRegister, UserLogin, UserResponse
from app.utils.jwt import create_access_token, get_guest_token
from datetime import timedelta

router = APIRouter(
    prefix="/auth",
    tags=["auth"]
)

def get_db() -> Session:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_user_service(db = Depends(get_db)):
    return UserService(db)

@router.post("/login")
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    user_service: UserService = Depends(get_user_service)
):
    user = user_service.login(form_data.username, form_data.password)
    access_token = create_access_token(
        data={"sub": user.user_id},
        expires_delta=timedelta(minutes=30)
    )
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user.to_response()
    }

@router.post("/register", response_model=UserResponse)
async def register(
    user_data: UserRegister,
    user_service: UserService = Depends(get_user_service)
):
    user = user_service.register(user_data.email, user_data.password)
    return user.to_response()

@router.post("/guest")
async def guest_login():
    """Get a guest token for anonymous access"""
    guest_token = get_guest_token()
    return {
        "access_token": guest_token,
        "token_type": "bearer",
    }

