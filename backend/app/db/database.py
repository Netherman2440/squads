import os
import dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker



dotenv.load_dotenv()
engine = create_engine(os.getenv("DATABASE_URL"))
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()