import os
import dotenv
from sqlalchemy import create_engine, inspect
from sqlalchemy.orm import declarative_base, sessionmaker



dotenv.load_dotenv()
engine = create_engine(os.getenv("DATABASE_URL"))
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def table_exists(table_name: str) -> bool:
    """Check if table exists in database"""
    inspector = inspect(engine)
    return table_name in inspector.get_table_names()

def create_tables_if_not_exist():
    """Create tables only if they don't exist"""
    inspector = inspect(engine)
    existing_tables = inspector.get_table_names()
    
    if not existing_tables:
        print("No tables found. Creating all tables...")
        Base.metadata.create_all(bind=engine)
        print("Tables created successfully")
    else:
        print(f"Tables already exist: {existing_tables}")


def check_tables():
    inspector = inspect(engine)
    tables = inspector.get_table_names()
    print("Tables in the database:", tables)

if __name__ == "__main__":
    check_tables()

