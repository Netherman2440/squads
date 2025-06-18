from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.models import SessionLocal
from app.services import SquadService, PlayerService, MatchService, TeamService
from app.schemas import *
from app.entities import PlayerData

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
    detail_squad = squad_service.create_squad(squad_data.name, squad_data.owner_id)
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

@router.post("/{squad_id}/matches", response_model=MatchDetailResponse)
async def create_match(squad_id: str, match_data: MatchCreate, match_service: MatchService = Depends(get_match_service)):
    detail_match = match_service.create_match(squad_id, match_data.team_a, match_data.team_b)
    if detail_match is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Failed to create match")
    return detail_match.to_response()


@router.get("/{squad_id}/matches/{match_id}")
async def get_match(squad_id: str, match_id: str, match_service: MatchService = Depends(get_match_service)):
    detail_match = match_service.get_match_detail(match_id)
    if detail_match is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Match not found")
    return detail_match.to_response()


@router.put("/{squad_id}/matches/{match_id}", response_model=MatchDetailResponse)
async def update_match(squad_id: str, match_id: str, match_data: MatchUpdate, match_service: MatchService = Depends(get_match_service)):
    detail_match = match_service.update_match(match_id, match_data.team_a, match_data.team_b, match_data.score)
    if detail_match is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Match not found")
    return detail_match.to_response()

@router.delete("/{squad_id}/matches/{match_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_match(squad_id: str, match_id: str, match_service: MatchService = Depends(get_match_service)):
    success = match_service.delete_match(match_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Match not found")
    
@router.post("/{squad_id}/matches/draw", response_model=DraftListResponse)
async def draw_match(draft_data: DraftCreate, match_service: MatchService = Depends(get_match_service)):
    players = [PlayerData(
        squad_id=player.squad_id,
        player_id=player.player_id, 
        name=player.name, 
        base_score=player.base_score,
        _score=player.score, 
        position=player.position
    ) for player in draft_data.players]

    drafts = match_service.draw_teams(players)
    if drafts is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Match not found")
    
    draft_responses = []
    for draft in drafts:
        team_a = [player.to_response() for player in draft.team_a]
        team_b = [player.to_response() for player in draft.team_b]
        draft_response = DraftResponse(team_a=team_a, team_b=team_b)
        draft_responses.append(draft_response)
    

    return DraftListResponse(drafts=draft_responses)
