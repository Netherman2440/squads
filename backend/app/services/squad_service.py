
from re import Match
from pytest import Session
from app.db import Squad, Player, Match
from app.entities import SquadData, SquadDetailData, MatchData, PlayerData


class SquadService:
    def __init__(self, session: Session):
        self.session = session

    def list_squads(self) -> list[SquadData]:
        squads = self.session.query(Squad).all()
        return [SquadData(
            squad_id=squad.squad_id,
            name=squad.name,
            created_at=squad.created_at,
            players_count=len(squad.players),
        ) for squad in squads]

    def get_squad(self, squad_id: str) -> SquadData:
        squad = self.session.query(Squad).filter(Squad.squad_id == squad_id).first()
        if not squad:
            raise ValueError("Squad not found")
        return SquadData(
            squad_id=squad.squad_id,
            name=squad.name,
            created_at=squad.created_at,
            players_count=len(squad.players),
        )

    def create_squad(self, name: str) -> SquadDetailData:
        squad = Squad(name=name)
        self.session.add(squad)
        self.session.commit()
        return self.get_squad_detail(squad.squad_id)
        

    def delete_squad(self, squad_id: str):
        squad = self.session.query(Squad).filter(Squad.squad_id == squad_id).first()
        if not squad:
            raise ValueError("Squad not found")
        
        self.session.delete(squad)
        self.session.commit()

    def get_squad_detail(self, squad_id: str) -> SquadDetailData:
        squad = self.session.query(Squad).filter(Squad.squad_id == squad_id).first()
        if not squad:
            raise ValueError("Squad not found")
        
        

        players_data = [PlayerData(
            squad_id=squad.squad_id,
            player_id=player.player_id,
            name=player.name,
            position=player.position,
            base_score=player.base_score,
            _score=player.score,
        ) for player in squad.players]

        

        matches_data = [MatchData(
            squad_id=squad.squad_id,
            match_id=match.match_id,
            created_at=match.created_at,
            score=(0, 0),
        ) for match in squad.matches]

        return SquadDetailData(
            squad_id=squad.squad_id,
            name=squad.name,
            created_at=squad.created_at,
            players_count=len(squad.players),
            players=players_data,
            matches=matches_data,
        )

    #todo: update squad admin or name, connect player with users