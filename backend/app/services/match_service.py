from sqlalchemy.orm import Session
from app.db import Match, Team, TeamPlayer

import uuid
from app.entities import MatchData, TeamData, PlayerData
from app.services import TeamService, DrawTeamsService

class MatchService:
    def __init__(self, session):
        self.session = session

    def create_match(self, squad_id: str, team_a_players: list[PlayerData], team_b_players: list[PlayerData]) -> MatchData:

        team_service = TeamService(self.session)
        # Create match and add to session
        match = Match(squad_id=squad_id)
        self.session.add(match)
        self.session.commit()  # Commit to generate match_id

        # Create teams and add to session
        team_a = team_service.create_team(squad_id=squad_id, match_id=match.match_id, players=team_a_players, color="white")
        team_b = team_service.create_team(squad_id=squad_id, match_id=match.match_id, players=team_b_players, color="black")


        return MatchData(
            match_id=str(match.match_id),
            team_a=team_a,
            team_b=team_b,
            created_at=match.created_at
        )

    def get_match(self, match_id: uuid.UUID) -> MatchData | None:
        match = self.session.query(Match).filter(Match.match_id == match_id).first()
        if not match:
            return None
        team_service = TeamService(self.session)
        team_a = team_service.get_team(match.team_a)
        team_b = team_service.get_team(match.team_b)
        # Convert ORM Match to MatchData
        return MatchData(
            match_id=str(match.match_id),
            team_a=team_a,
            created_at=match.created_at
        )


    def draw_teams(self, players: list[PlayerData], amount_of_teams: int = 2) -> tuple[list[PlayerData], list[int]]:
        
        players.sort(key=lambda x: x.score, reverse=True)
        draw_teams_service = DrawTeamsService(players, amount_of_teams)
        list_of_teams = draw_teams_service.draw_teams()
        print(len(list_of_teams))
        return players, list_of_teams



