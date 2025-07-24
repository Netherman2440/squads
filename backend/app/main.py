import os

import dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import auth
from app.routes import squads

#.\.venv\Scripts\activate
#pip freeze > requirements.txt
#pip install -r requirements.txt
#uvicorn app.main:app --reload  
#alembic init migrations
#alembic upgrade head
#alembic revision --autogenerate -m "Add ScoreHistory table"
#docker-compose exec backend bash



app = FastAPI(
    title="Squads API",
    description="API for managing football squads, players, and matches",
    version="1.0.0",
    openapi_tags=[
        {"name": "auth", "description": "Authentication operations"},
        {"name": "squads", "description": "Operations with squads"}
    ]
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1")
#app.include_router(players.router, prefix="/api/v1/")
app.include_router(squads.router, prefix="/api/v1")
dotenv.load_dotenv()

@app.get("/")
def read_root():
    return {"message": "Squads API is running", "version": "1.0.0"}






