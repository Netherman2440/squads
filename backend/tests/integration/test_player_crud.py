import uuid
from app.db import Player, Squad, Base, engine, SessionLocal
import pytest

@pytest.fixture(scope="function")
def db_session():
    # Create all tables
    Base.metadata.create_all(bind=engine)
    session = SessionLocal()
    # Create a squad for foreign key
    squad = Squad(name="Test Squad")
    session.add(squad)
    session.commit()
    yield session, squad
    session.close()

def test_create_player(db_session):
    session, squad = db_session
    # Test creating a player
    player = Player(
        squad_id=squad.squad_id,
        name="John Doe",
        position="field",
        base_score=10
    )
    session.add(player)
    session.commit()
    assert player.player_id is not None

def test_get_player_by_id(db_session):
    session, squad = db_session
    # Test retrieving a player by player_id
    player = Player(
        squad_id=squad.squad_id,
        name="Jane Smith",
        position="goalie",
        base_score=15
    )
    session.add(player)
    session.commit()
    player_from_db = session.query(Player).filter_by(player_id=player.player_id).first()
    assert player_from_db is not None
    assert player_from_db.name == "Jane Smith"

def test_update_player_name(db_session):
    session, squad = db_session
    # Test updating player's name
    player = Player(
        squad_id=squad.squad_id,
        name="Old Name",
        position="field",
        base_score=12
    )
    session.add(player)
    session.commit()
    player.name = "New Name"
    session.commit()
    player_from_db = session.query(Player).filter_by(player_id=player.player_id).first()
    assert player_from_db.name == "New Name"

def test_delete_player(db_session):
    session, squad = db_session
    # Test deleting a player
    player = Player(
        squad_id=squad.squad_id,
        name="To Delete",
        position="goalie",
        base_score=8
    )
    session.add(player)
    session.commit()
    player_id = player.player_id
    session.delete(player)
    session.commit()
    player_from_db = session.query(Player).filter_by(player_id=player_id).first()
    assert player_from_db is None
