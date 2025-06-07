from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db import SessionLocal
from app.services import SquadService, PlayerService, MatchService, TeamService


router = APIRouter(
    prefix ="/squads",
    tags=["squads"]
)

def get_db() -> Session:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_squad_service(db = Depends(get_db)):
    return SquadService(db)

def get_player_service(db = Depends(get_db)):
    return PlayerService(db)

def get_match_service(db = Depends(get_db)):
    return MatchService(db)

def get_team_service(db = Depends(get_db)):
    return TeamService(db)


@router.get("/")
async def get_all_squads():
    return {"message": "Squads retrieved successfully"}

@router.get("/{squad_id}")
async def get_squad(squad_id: str, squad_service: SquadService = Depends(get_squad_service)): #todo: response model
    #return {squad_service.get_squad(squad_id)}
    return {"message": f"Squad {squad_id} retrieved successfully"}

#@router.post("/")
#async def create_squad(squad_data: SquadCreate, squad_service: SquadService = Depends(get_squad_service)):
 #   return {"message": f"Squad created successfully"}

@router.get("/{squad_id}/players")
async def get_players(squad_id: str, player_service: PlayerService = Depends(get_player_service)):
    return {"message": f"Players for squad {squad_id} retrieved successfully"}

@router.get("/{squad_id}/players/{player_id}")
async def get_player(squad_id: str, player_id: str, player_service: PlayerService = Depends(get_player_service)):
    return {"message": f"Player {player_id} for squad {squad_id} retrieved successfully"}

@router.get("/{squad_id}/matches")
async def get_matches(squad_id: str, match_service: MatchService = Depends(get_match_service)):
    return {"message": f"Matches for squad {squad_id} retrieved successfully"}

@router.get("/{squad_id}/matches/{match_id}")
async def get_match(squad_id: str, match_id: str, match_service: MatchService = Depends(get_match_service)):
    return {"message": f"Match {match_id} for squad {squad_id} retrieved successfully"}



