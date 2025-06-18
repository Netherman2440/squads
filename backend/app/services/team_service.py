from typing import Optional
from app.entities import TeamData, TeamDetailData, PlayerData
from app.models import Team, TeamPlayer


class TeamService:
    def __init__(self, session):
        self.session = session

    def team_to_data(self, team: Team) -> TeamData:
        return TeamData(
            squad_id=team.squad_id,
            match_id=team.match_id,
            team_id=str(team.team_id),
            name=team.name,
            color=team.color,
            score=team.score,
            players_count=len(team.players)
        )


    def create_team(self,squad_id: str, match_id: str, players: list[PlayerData], color: str, name: Optional[str] = None) -> TeamData:

        team = Team(squad_id=squad_id, match_id=match_id, color=color, name=name)
        self.session.add(team)
        self.session.commit()
        for player in players:
            team_player = TeamPlayer(
                squad_id=squad_id,
                match_id=match_id,
                team_id=team.team_id,
                player_id=player.player_id
            )
            self.session.add(team_player)

        self.session.commit()
        return self.team_to_data(team)

    def get_team(self, team_id: str) -> TeamData:
        team = self.session.query(Team).filter(Team.team_id == team_id).first()
        return self.team_to_data(team)

    def get_team_details(self, team_id: str, match_id: str = None) -> TeamDetailData:
        from app.services.player_service import PlayerService
        player_service = PlayerService(self.session)
        team = self.session.query(Team).filter(Team.team_id == team_id).first()
        players = []
        for player in team.players:
            if match_id:
                # Use the method that considers score history for the specific match
                player_data = player_service.get_player_data_for_match(player.player_id, match_id)
            else:
                # Use regular method
                player_data = player_service.get_player(player.player_id)
            players.append(player_data)

        players.sort(key=lambda x: x.score, reverse=True)
        return TeamDetailData(
            squad_id=team.squad_id,
            match_id=team.match_id,
            team_id=str(team.team_id),
            name=team.name,
            color=team.color,
            score=team.score,
            players_count=len(team.players),
            players=players
        )

    def update_team_name(self, team_id: str, name: str) -> TeamDetailData | None:
        team = self.session.query(Team).filter(Team.team_id == team_id).first()
        if not team:
            return None
        team.name = name
        self.session.commit()
        return self.get_team_details(team_id)
    
    def update_team_color(self, team_id: str, color: str) -> TeamDetailData | None:
        team = self.session.query(Team).filter(Team.team_id == team_id).first()
        if not team:
            return None
        team.color = color
        self.session.commit()
        return self.get_team_details(team_id)
    
    def update_team_score(self, team_id: str, score: int) -> TeamDetailData | None:
        team = self.session.query(Team).filter(Team.team_id == team_id).first()
        if not team:
            return None
        team.score = score
        self.session.commit()
        return self.get_team_details(team_id)
        
    def update_team_players(self, team_id: str, players: list[PlayerData]) -> TeamDetailData | None:
        team = self.session.query(Team).filter(Team.team_id == team_id).first()
        if not team:
            return None
        team_players = self.session.query(TeamPlayer).filter(TeamPlayer.team_id == team_id).all()
        for player in team_players:
            self.session.delete(player)
        for player in players:
            team_player = TeamPlayer(
                squad_id=team.squad_id,
                match_id=team.match_id,
                team_id=team_id,
                player_id=player.player_id
            )
            self.session.add(team_player)
        self.session.commit()
        return self.get_team_details(team_id)
