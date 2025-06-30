from fastapi import APIRouter, Depends, HTTPException, status, Security
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session
from app.models import SessionLocal
from app.services import SquadService, PlayerService, MatchService, TeamService
from app.schemas import *
from app.entities import PlayerData

router = APIRouter(
    prefix="/squads",
    tags=["squads"],
    dependencies=[Depends(HTTPBearer())]
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

security = HTTPBearer()

def get_current_user(credentials: HTTPAuthorizationCredentials = Security(security)):
    """Extract user_id from JWT token"""
    from app.utils.jwt import verify_token
    from fastapi import HTTPException, status
    
    try:
        payload = verify_token(credentials.credentials)
        user_id = payload.get("sub")
        
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not validate credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        return user_id
        
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

def is_guest_user(user_id: str) -> bool:
    """Check if user is a guest"""
    return user_id == "guest"

def check_user_can_access_squad(user_id: str, squad_id: str, squad_service: SquadService) -> bool:
    """Check if user can access a specific squad (owner or member)"""
    if is_guest_user(user_id):
        return False  # Guest cannot access specific squads for modifications
    
    try:
        squad = squad_service.get_squad(squad_id)
        # For now, only owner can access. In future, check user role in squad
        return squad.owner_id == user_id
    except:
        return False

def check_user_can_create_squad(user_id: str) -> bool:
    """Check if user can create squads"""
    return not is_guest_user(user_id)

@router.get("/", response_model=SquadListResponse)
async def get_all_squads(
    user_id: str = Depends(get_current_user),
    squad_service: SquadService = Depends(get_squad_service)
):
    """Get all squads - accessible to all authenticated users"""
    squads = squad_service.list_squads()
    squads_response = [squad.to_response() for squad in squads]
    return SquadListResponse(squads=squads_response)

@router.post("/", response_model=SquadDetailResponse)
async def create_squad(
    squad_data: SquadCreate, 
    user_id: str = Depends(get_current_user),
    squad_service: SquadService = Depends(get_squad_service)
):
    """Create a new squad - only non-guest users can create squads"""
    if not check_user_can_create_squad(user_id):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Guest users cannot create squads")
    
    detail_squad = squad_service.create_squad(squad_data.name, user_id)
    if detail_squad is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Failed to create squad")
    return detail_squad.to_response()

@router.get("/{squad_id}", response_model=SquadDetailResponse)
async def get_squad(
    squad_id: str, 
    user_id: str = Depends(get_current_user),
    squad_service: SquadService = Depends(get_squad_service)
):
    """Get a specific squad by ID - accessible to all authenticated users"""
    try:
        detail_squad = squad_service.get_squad_detail(squad_id)
        if detail_squad is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Squad not found")
        return detail_squad.to_response()
    except ValueError as e:
        print(e)
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Squad not found")

@router.delete("/{squad_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_squad(
    squad_id: str, 
    user_id: str = Depends(get_current_user),
    squad_service: SquadService = Depends(get_squad_service)
):
    """Delete a squad by ID - only squad owner can delete"""
    if not check_user_can_access_squad(user_id, squad_id, squad_service):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only squad owner can delete the squad")
    
    success = squad_service.delete_squad(squad_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Squad not found")

@router.get("/{squad_id}/players", response_model=PlayerListResponse)
async def get_players(
    squad_id: str, 
    user_id: str = Depends(get_current_user),
    player_service: PlayerService = Depends(get_player_service)
):
    """Get players in a squad - accessible to all authenticated users"""
    players = player_service.get_players(squad_id)
    players_response = [player.to_response() for player in players]
    return PlayerListResponse(players=players_response)

@router.post("/{squad_id}/players", response_model=PlayerDetailResponse)
async def add_player(
    squad_id: str, 
    player_data: PlayerCreate, 
    user_id: str = Depends(get_current_user),
    player_service: PlayerService = Depends(get_player_service),
    squad_service: SquadService = Depends(get_squad_service)
):
    """Add a player to a squad - only squad owner can add players"""
    if not check_user_can_access_squad(user_id, squad_id, squad_service):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only squad owner can add players")
    
    detail_player = player_service.create_player(squad_id, player_data.name, player_data.base_score, player_data.position)
    if detail_player is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Failed to create player")
    return detail_player.to_response()

@router.get("/{squad_id}/players/{player_id}", response_model=PlayerDetailResponse)
async def get_player(
    squad_id: str, 
    player_id: str, 
    user_id: str = Depends(get_current_user),
    player_service: PlayerService = Depends(get_player_service)
):
    """Get a specific player - accessible to all authenticated users"""
    detail_player = player_service.get_player_details(player_id)
    if detail_player is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Player not found")
    return detail_player.to_response()

@router.put("/{squad_id}/players/{player_id}", response_model=PlayerDetailResponse)
async def update_player(
    squad_id: str, 
    player_id: str, 
    player_data: PlayerUpdate, 
    user_id: str = Depends(get_current_user),
    player_service: PlayerService = Depends(get_player_service),
    squad_service: SquadService = Depends(get_squad_service)
):
    """Update a player - only squad owner can update players"""
    if not check_user_can_access_squad(user_id, squad_id, squad_service):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only squad owner can update players")
    
    detail_player = player_service.update_player(player_id, player_data.name, player_data.base_score, player_data.position)
    if detail_player is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Player not found")
    return detail_player.to_response()

@router.get("/{squad_id}/matches", response_model=MatchListResponse)
async def get_matches(
    squad_id: str, 
    user_id: str = Depends(get_current_user),
    match_service: MatchService = Depends(get_match_service)
):
    """Get matches in a squad - accessible to all authenticated users"""
    matches = match_service.get_matches(squad_id)
    matches_response = [match.to_response() for match in matches]
    return MatchListResponse(matches=matches_response)

@router.post("/{squad_id}/matches", response_model=MatchDetailResponse)
async def create_match(
    squad_id: str, 
    match_data: MatchCreate, 
    user_id: str = Depends(get_current_user),
    match_service: MatchService = Depends(get_match_service),
    squad_service: SquadService = Depends(get_squad_service)
):
    """Create a match in a squad - only squad owner can create matches"""
    if not check_user_can_access_squad(user_id, squad_id, squad_service):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only squad owner can create matches")
    
    detail_match = match_service.create_match(squad_id, match_data.team_a, match_data.team_b)
    if detail_match is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Failed to create match")
    return detail_match.to_response()

@router.get("/{squad_id}/matches/{match_id}", response_model=MatchDetailResponse)
async def get_match(
    squad_id: str, 
    match_id: str, 
    user_id: str = Depends(get_current_user),
    match_service: MatchService = Depends(get_match_service)
):
    """Get a specific match - accessible to all authenticated users"""
    detail_match = match_service.get_match_detail(match_id)
    if detail_match is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Match not found")
    return detail_match.to_response()

@router.put("/{squad_id}/matches/{match_id}", response_model=MatchDetailResponse)
async def update_match(
    squad_id: str, 
    match_id: str, 
    match_data: MatchUpdate, 
    user_id: str = Depends(get_current_user),
    match_service: MatchService = Depends(get_match_service),
    squad_service: SquadService = Depends(get_squad_service)
):
    """Update a match - only squad owner can update matches"""
    if not check_user_can_access_squad(user_id, squad_id, squad_service):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only squad owner can update matches")
    
    detail_match = match_service.update_match(match_id, match_data.team_a, match_data.team_b, match_data.score)
    if detail_match is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Match not found")
    return detail_match.to_response()

@router.delete("/{squad_id}/matches/{match_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_match(
    squad_id: str, 
    match_id: str, 
    user_id: str = Depends(get_current_user),
    match_service: MatchService = Depends(get_match_service),
    squad_service: SquadService = Depends(get_squad_service)
):
    """Delete a match - only squad owner can delete matches"""
    if not check_user_can_access_squad(user_id, squad_id, squad_service):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only squad owner can delete matches")
    
    success = match_service.delete_match(match_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Match not found")

@router.post("/{squad_id}/matches/draw", response_model=DraftListResponse)
async def draw_match(
    squad_id: str,
    draft_data: DraftCreate, 
    user_id: str = Depends(get_current_user),
    match_service: MatchService = Depends(get_match_service)
):
    """Draw teams for a match - accessible to all authenticated users (but guest cannot use POST)"""

    drafts = match_service.draw_teams(draft_data.players_ids)
    if drafts is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Match not found")
    
    draft_responses = []
    for draft in drafts:
        team_a = [player.to_response() for player in draft.team_a]
        team_b = [player.to_response() for player in draft.team_b]
        draft_response = DraftResponse(team_a=team_a, team_b=team_b)
        draft_responses.append(draft_response)
    
    return DraftListResponse(drafts=draft_responses)

