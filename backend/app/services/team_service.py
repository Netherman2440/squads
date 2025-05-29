
from typing import Optional
from app.entities import TeamData, TeamDetailData, PlayerData
from app.db import Team, TeamPlayer


class TeamService:
    def __init__(self, session):
        self.session = session

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
        return TeamData(
            team_id=str(team.team_id),
            name=team.name,
            color=team.color,
            score=team.score,
            players_count=len(players)
        )

    def get_team(self, team_id: str) -> TeamData:
        team = self.session.query(Team).filter(Team.team_id == team_id).first()
        return TeamData(
            team_id=str(team.team_id),
            name=team.name,
            color=team.color,
            score=team.score,
            players_count=len(team.players)
        )

    def get_team_details(self, team_id: str) -> TeamDetailData:
        from app.services.player_service import PlayerService
        player_service = PlayerService(self.session)
        team = self.session.query(Team).filter(Team.team_id == team_id).first()
        players = []
        for player in team.players:
            players.append(player_service.get_player(player.player_id))
        return TeamDetailData(
            team_id=str(team.team_id),
            name=team.name,
            color=team.color,
            score=team.score,
            players_count=len(team.players),
            players=players
        )
