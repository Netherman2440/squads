from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from datetime import datetime
import uuid
import json
from app.models import *
from app.database import engine, SessionLocal
from app.services.player_service import PlayerService
from app.services.squad_service import SquadService
import os

# Database connection

def load_seed_data():
    """Load seed data from JSON file"""
    try:
        seed_path = os.path.join(os.path.dirname(__file__), 'seed_data.json')
        with open(seed_path, 'r', encoding='utf-8') as file:
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

        squadService = SquadService(db)
        playerService = PlayerService(db)
        # Create squads and their players
        for squad_data in seed_data['squads']:
            # Create squad
            squad = squadService.create_squad(squad_data['name'], squad_data['owner_id'])

            # Create players for this squad
            for player_data in squad_data['players']:
                player = playerService.create_player(
                    squad_id=squad.squad_id,
                    name=player_data['name'],
                    base_score=player_data['base_score']
                )
        print("Database seeded successfully!")

    except Exception as e:
        db.rollback()
        print(f"Error seeding database: {str(e)}")
        raise
    finally:
        db.close()

if __name__ == "__main__":
    seed_database() 