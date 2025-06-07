from fastapi import APIRouter, HTTPException, Depends, status
from typing import List
from sqlalchemy.orm import Session
from app.schemas.player_schemas import (
    PlayerCreate, 
    PlayerUpdate, 
    PlayerResponse, 
    PlayerDetailResponse
)
from app.services.player_service import PlayerService
from app.db import SessionLocal

router = APIRouter(
    prefix="/players",
    tags=["players"],
    responses={404: {"description": "Not found"}},
)

# Database dependency
def get_db() -> Session:
    """Create database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Service dependency
def get_player_service(db: Session = Depends(get_db)) -> PlayerService:
    """Create PlayerService with database session"""
    return PlayerService(db)


@router.post("/", response_model=PlayerResponse, status_code=status.HTTP_201_CREATED)
async def create_player(
    player_data: PlayerCreate,
    player_service: PlayerService = Depends(get_player_service)
):
    """Create a new player"""
    try:
        player = await player_service.create_player(player_data)
        return player
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")


@router.get("/", response_model=List[PlayerResponse])
async def get_all_players(
    player_service: PlayerService = Depends(get_player_service)
):
    """Get all players"""
    try:
        players = await player_service.get_all_players()
        return players
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")


@router.get("/{player_id}", response_model=PlayerDetailResponse)
async def get_player(
    player_id: str,
    player_service: PlayerService = Depends(get_player_service)
):
    """Get a specific player by ID"""
    try:
        player = await player_service.get_player(player_id)
        if not player:
            raise HTTPException(status_code=404, detail="Player not found")
        return player
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")


@router.put("/{player_id}", response_model=PlayerResponse)
async def update_player(
    player_id: str,
    player_data: PlayerUpdate,
    player_service: PlayerService = Depends(get_player_service)
):
    """Update a player"""
    try:
        player = await player_service.update_player(player_id, player_data)
        if not player:
            raise HTTPException(status_code=404, detail="Player not found")
        return player
    except HTTPException:
        raise
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")


@router.delete("/{player_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_player(
    player_id: str,
    player_service: PlayerService = Depends(get_player_service)
):
    """Delete a player"""
    try:
        success = await player_service.delete_player(player_id)
        if not success:
            raise HTTPException(status_code=404, detail="Player not found")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error") 