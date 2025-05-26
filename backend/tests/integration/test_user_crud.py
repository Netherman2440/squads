import uuid
from app.db import User, Base, engine, SessionLocal
import pytest

@pytest.fixture(scope="function")
def db_session():
    # Create all tables
    Base.metadata.create_all(bind=engine)
    session = SessionLocal()
    yield session
    session.close()

def test_create_user(db_session):
    # Test creating a user
    user = User(
        email="test@example.com",
        password_hash="hashedpassword"
    )
    db_session.add(user)
    db_session.commit()
    assert user.user_id is not None

def test_get_user_by_id(db_session):
    # Test retrieving a user by user_id
    user = User(
        email="get@example.com",
        password_hash="hashedpassword"
    )
    db_session.add(user)
    db_session.commit()
    user_from_db = db_session.query(User).filter_by(user_id=user.user_id).first()
    assert user_from_db is not None
    assert user_from_db.email == "get@example.com"

def test_update_user_email(db_session):
    # Test updating user's email
    user = User(
        email="old@example.com",
        password_hash="hashedpassword"
    )
    db_session.add(user)
    db_session.commit()
    user.email = "new@example.com"
    db_session.commit()
    user_from_db = db_session.query(User).filter_by(user_id=user.user_id).first()
    assert user_from_db.email == "new@example.com"

def test_delete_user(db_session):
    # Test deleting a user
    user = User(
        email="delete@example.com",
        password_hash="hashedpassword"
    )
    db_session.add(user)
    db_session.commit()
    user_id = user.user_id
    db_session.delete(user)
    db_session.commit()
    user_from_db = db_session.query(User).filter_by(user_id=user_id).first()
    assert user_from_db is None
