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

    def delete_squad(self, squad_id: str) -> bool:
        squad = self.session.query(Squad).filter(Squad.squad_id == squad_id).first()
        if not squad:
            return False
        
        self.session.delete(squad)
        self.session.commit()
        return True

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
    
    def update_squad_owner(self, squad_id: str, new_owner_id: str) -> SquadDetailData:
        squad = self.session.query(Squad).filter(Squad.squad_id == squad_id).first()
        if not squad:
            raise ValueError("Squad not found")
        
        previous_owner = self.session.query(UserSquad).filter(UserSquad.squad_id == squad_id, UserSquad.role == UserRole.OWNER.value).first()
        if not previous_owner:
            raise ValueError("Previous owner not found in the squad")
        
        new_owner = self.session.query(UserSquad).filter(UserSquad.squad_id == squad_id, UserSquad.user_id == new_owner_id).first()
        if not new_owner:
            raise ValueError("New owner not found in the squad")
        
        previous_owner.role = UserRole.MEMBER.value
        new_owner.role = UserRole.OWNER.value
            
        squad.owner_id = new_owner_id

        #todo: update user_squad role

        self.session.commit()
        return self.get_squad_detail(squad_id)
    
    def add_user_to_squad(self, squad_id: str, user_id: str, role: UserRole = UserRole.MEMBER) -> SquadDetailData:
        user_squad = UserSquad(user_id=user_id, squad_id=squad_id, role=role.value)
        self.session.add(user_squad)
        self.session.commit()
        return self.get_squad_detail(squad_id)
    
    def remove_user_from_squad(self, squad_id: str, user_id: str) -> SquadDetailData:
        user_squad = self.session.query(UserSquad).filter(UserSquad.squad_id == squad_id, UserSquad.user_id == user_id).first()
        if not user_squad:
            raise ValueError("User not found in the squad")
        self.session.delete(user_squad)
        self.session.commit()
        return self.get_squad_detail(squad_id)
    
    def update_user_role(self, squad_id: str, user_id: str, new_role: UserRole) -> SquadDetailData:
        if new_role == UserRole.OWNER:
            raise ValueError("Owner role cannot be updated, use update_squad_owner instead")

        
        user_squad = self.session.query(UserSquad).filter(UserSquad.squad_id == squad_id, UserSquad.user_id == user_id).first()
        if not user_squad:
            raise ValueError("User not found in the squad")
        user_squad.role = new_role.value
        self.session.commit()
        return self.get_squad_detail(squad_id)
    
    #todo connect player with user
    

    
