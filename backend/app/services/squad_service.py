from re import Match
from pytest import Session
from app.models import Squad, UserSquad
from app.entities import SquadData, SquadDetailData, MatchData, PlayerData
from app.constants import UserRole


from app.services import PlayerService, MatchService


class SquadService:
    def __init__(self, session: Session):
        self.session = session

    def squad_to_data(self, squad: Squad) -> SquadData:
        return SquadData(
            squad_id=squad.squad_id,
            name=squad.name,
            created_at=squad.created_at,
            players_count=len(squad.players),
            owner_id=squad.owner_id,
        )
    
    def squad_to_detail_data(self, squad: Squad) -> SquadDetailData:
        player_service = PlayerService(self.session)
        match_service = MatchService(self.session)

        return SquadDetailData(
            squad_id=squad.squad_id,
            name=squad.name,
            created_at=squad.created_at,
            players_count=len(squad.players),
            owner_id=squad.owner_id,
            players=[player_service.player_to_data(player) for player in squad.players],
            matches=[match_service.match_to_data(match) for match in squad.matches],
        )

    def list_squads(self) -> list[SquadData]:
        squads = self.session.query(Squad).all()
        return [self.squad_to_data(squad) for squad in squads]

    def get_squad(self, squad_id: str) -> SquadData:
        squad = self.session.query(Squad).filter(Squad.squad_id == squad_id).first()
        if not squad:
            raise ValueError("Squad not found")
        return self.squad_to_data(squad)

    def create_squad(self, name: str, owner_id: str) -> SquadDetailData:
        squad = Squad(name=name, owner_id=owner_id)
        self.session.add(squad)
        self.session.commit()  # Commit first to generate squad_id

        user_squad = UserSquad(user_id=owner_id, squad_id=squad.squad_id, role=UserRole.OWNER.value)
        self.session.add(user_squad)
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
        
        return self.squad_to_detail_data(squad)
    
    def update_squad_name(self, squad_id: str, name: str) -> SquadDetailData:
            
        squad = self.session.query(Squad).filter(Squad.squad_id == squad_id).first()
        if not squad:
            raise ValueError("Squad not found")
            
        squad.name = name
        self.session.commit()
        return self.get_squad_detail(squad_id)
    
    def update_squad_owner(self, squad_id: str, owner_id: str) -> SquadDetailData:
        squad = self.session.query(Squad).filter(Squad.squad_id == squad_id).first()
        if not squad:
            raise ValueError("Squad not found")
            
        squad.owner_id = owner_id
        self.session.commit()
        return self.get_squad_detail(squad_id)
    