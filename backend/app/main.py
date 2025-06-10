import os

import dotenv
from fastapi import FastAPI
from app.routes import auth
from app.routes import squads
#.\.venv\Scripts\activate
#uvicorn app.main:app --reload  
app = FastAPI(
    title="Squads API",
    description="API for managing football squads, players, and matches",
    version="1.0.0"
)

app.include_router(auth.router, prefix="/api/v1")
#app.include_router(players.router, prefix="/api/v1/")
app.include_router(squads.router, prefix="/api/v1")
dotenv.load_dotenv()

@app.get("/")
def read_root():
    return {"message": "Squads API is running", "version": "1.0.0"}






