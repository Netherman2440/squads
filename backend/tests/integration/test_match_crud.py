import uuid
import pytest
from app.db import Base, engine, SessionLocal, Match


@pytest.fixture(scope="function")
def db_session():
    Base.metadata.create_all(bind=engine)
    session = SessionLocal()
    yield session
    session.close()
    Base.metadata.drop_all(bind=engine)
    
def test_create_match(db_session):
    # Test creating a match
    match = Match()
    db_session.add(match)
    db_session.commit()
    assert match.match_id is not None

def test_get_match_by_id(db_session):
    # Test retrieving a match by match_id
    match = Match()
    db_session.add(match)
    db_session.commit()
    match_from_db = db_session.query(Match).filter_by(match_id=match.match_id).first()
    assert match_from_db is not None
    assert match_from_db.match_id == match.match_id

def test_delete_match(db_session):
    # Test deleting a match
    match = Match()
    db_session.add(match)
    db_session.commit()
    match_id = match.match_id
    db_session.delete(match)
    db_session.commit()
    match_from_db = db_session.query(Match).filter_by(match_id=match_id).first()
    assert match_from_db is None
    
