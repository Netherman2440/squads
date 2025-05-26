import uuid
from app.db import Squad, Base, engine, SessionLocal
import pytest

@pytest.fixture(scope="function")
def db_session():
    # Create all tables
    Base.metadata.create_all(bind=engine)
    session = SessionLocal()
    yield session
    session.close()

def test_create_squad(db_session):
    # Test creating a squad
    squad = Squad(name="Alpha Squad")
    db_session.add(squad)
    db_session.commit()
    assert squad.squad_id is not None

def test_get_squad_by_id(db_session):
    # Test retrieving a squad by squad_id
    squad = Squad(name="Bravo Squad")
    db_session.add(squad)
    db_session.commit()
    squad_from_db = db_session.query(Squad).filter_by(squad_id=squad.squad_id).first()
    assert squad_from_db is not None
    assert squad_from_db.name == "Bravo Squad"

def test_update_squad_name(db_session):
    # Test updating squad's name
    squad = Squad(name="Old Name")
    db_session.add(squad)
    db_session.commit()
    squad.name = "New Name"
    db_session.commit()
    squad_from_db = db_session.query(Squad).filter_by(squad_id=squad.squad_id).first()
    assert squad_from_db.name == "New Name"

def test_delete_squad(db_session):
    # Test deleting a squad
    squad = Squad(name="To Delete")
    db_session.add(squad)
    db_session.commit()
    squad_id = squad.squad_id
    db_session.delete(squad)
    db_session.commit()
    squad_from_db = db_session.query(Squad).filter_by(squad_id=squad_id).first()
    assert squad_from_db is None
