from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db import SessionLocal
from app.services import SquadService, PlayerService, MatchService, TeamService
from app.schemas import SquadListResponse, SquadDetailResponse, SquadCreate, PlayerListResponse, PlayerDetailResponse, PlayerCreate, MatchListResponse


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


@router.get("/", response_model=SquadListResponse)
async def get_all_squads(squad_service: SquadService = Depends(get_squad_service)):
    squads = squad_service.list_squads()
    squads_response = [squad.to_response() for squad in squads]
    return SquadListResponse(squads=squads_response)

@router.post("/", response_model=SquadDetailResponse)
async def create_squad(squad_data: SquadCreate, squad_service: SquadService = Depends(get_squad_service)):
    """Create a new squad"""
    detail_squad = squad_service.create_squad(squad_data.name)
    if detail_squad is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Failed to create squad")
    return detail_squad.to_response()

@router.get("/{squad_id}", response_model=SquadDetailResponse)
async def get_squad(squad_id: str, squad_service: SquadService = Depends(get_squad_service)):
    """Get a specific squad by ID"""
    detail_squad = squad_service.get_squad(squad_id)
    if detail_squad is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Squad not found")
    return detail_squad.to_response()

@router.delete("/{squad_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_squad(squad_id: str, squad_service: SquadService = Depends(get_squad_service)):
    """Delete a squad by ID"""
    success = squad_service.delete_squad(squad_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Squad not found")


@router.get("/{squad_id}/players", response_model=PlayerListResponse)
async def get_players(squad_id: str, player_service: PlayerService = Depends(get_player_service)):
    players = player_service.get_players(squad_id)
    players_response = [player.to_response() for player in players]
    return PlayerListResponse(players=players_response)

@router.post("/{squad_id}/players", response_model=PlayerDetailResponse)
async def add_player(squad_id: str, player_data: PlayerCreate, player_service: PlayerService = Depends(get_player_service)):
    detail_player = player_service.create_player(squad_id, player_data.name, player_data.base_score, player_data.position)
    if detail_player is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Failed to create player")
    return detail_player.to_response()

@router.get("/{squad_id}/players/{player_id}", response_model=PlayerDetailResponse)
async def get_player(squad_id: str, player_id: str, player_service: PlayerService = Depends(get_player_service)):
    detail_player = player_service.get_player_details(player_id)
    if detail_player is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Player not found")
    return detail_player.to_response()

@router.get("/{squad_id}/matches", response_model=MatchListResponse)
async def get_matches(squad_id: str, match_service: MatchService = Depends(get_match_service)):
    matches = match_service.get_matches(squad_id)
    matches_response = [match.to_response() for match in matches]
    return MatchListResponse(matches=matches_response)

@router.get("/{squad_id}/matches/{match_id}")
async def get_match(squad_id: str, match_id: str, match_service: MatchService = Depends(get_match_service)):
    detail_match = match_service.get_match_detail(match_id)
    if detail_match is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Match not found")
    return detail_match.to_response()



