import pytest
from app.db.database import Base, engine, SessionLocal
from app.db.models import Squad, Player

@pytest.fixture(scope="function")
def db_session():
    # Tworzy i czyści tabele na czas testu
    Base.metadata.create_all(bind=engine)
    session = SessionLocal()
    yield session
    session.close()
    Base.metadata.drop_all(bind=engine)

def test_create_and_get_squad(db_session):
    squad = Squad(name="Test Squad")
    db_session.add(squad)
    db_session.commit()

    squad_from_db = db_session.query(Squad).filter_by(name="Test Squad").first()
    assert squad_from_db is not None
    assert squad_from_db.name == "Test Squad"

def test_create_player(db_session):
    squad = Squad(name="With Player")
    db_session.add(squad)
    db_session.commit()

    player = Player(name="Test Player", position="goalie", base_score=100, squad_id=squad.squad_id)
    db_session.add(player)
    db_session.commit()

    player_from_db = db_session.query(Player).filter_by(name="Test Player").first()
    assert player_from_db is not None
    assert player_from_db.position == "goalie"