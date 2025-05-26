import os
import dotenv
from sqlalchemy import create_engine, inspect
from sqlalchemy.orm import declarative_base, sessionmaker



dotenv.load_dotenv()
engine = create_engine(os.getenv("DATABASE_URL"))
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def check_tables():
    inspector = inspect(engine)
    tables = inspector.get_table_names()
    print("Tables in the database:", tables)

if __name__ == "__main__":
    check_tables()

