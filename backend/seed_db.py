from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from datetime import datetime
import uuid
import json
from app.models import *
from app.database import engine, SessionLocal

# Database connection

def load_seed_data():
    """Load seed data from JSON file"""
    try:
        with open('backend/seed_data.json', 'r') as file:
            return json.load(file)
    except FileNotFoundError:
        print("Error: seed_data.json file not found")
        return None
    except json.JSONDecodeError:
        print("Error: Invalid JSON format in seed_data.json")
        return None

def seed_database():
    """Seed the database with initial data from JSON"""
    db = SessionLocal()
    try:
        # Check if data already exists
        existing_squads = db.query(Squad).first()
        if existing_squads:
            print("Database already seeded. Skipping...")
            return

        # Load seed data from JSON
        seed_data = load_seed_data()
        if not seed_data:
            return

        # Create squads and their players
        for squad_data in seed_data['squads']:
            # Create squad
            squad = Squad(
                squad_id=str(uuid.uuid4()),
                name=squad_data['name'],
                created_at=datetime.utcnow()
            )
            db.add(squad)
            db.flush()

            # Create players for this squad
            for player_data in squad_data['players']:
                player = Player(
                    player_id=str(uuid.uuid4()),
                    squad_id=squad.squad_id,
                    name=player_data['name'],
                    position=player_data['position'],
                    base_score=player_data['base_score'],
                    score=float(player_data['base_score']),
                    created_at=datetime.utcnow()
                )
                db.add(player)

        db.flush()

        db.commit()
        print("Database seeded successfully!")

    except Exception as e:
        db.rollback()
        print(f"Error seeding database: {str(e)}")
        raise
    finally:
        db.close()

if __name__ == "__main__":
    seed_database() 