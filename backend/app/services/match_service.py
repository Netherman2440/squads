from app.db import Match

from app.entities import MatchData, PlayerData, MatchDetailData, TeamDetailData


class MatchService:
    def __init__(self, session):
        self.session = session

    def create_match(self, squad_id: str, team_a_players: list[PlayerData], team_b_players: list[PlayerData]) -> MatchData:

        from app.services import TeamService
        team_service = TeamService(self.session)
        # Create match and add to session
        match = Match(squad_id=squad_id)
        self.session.add(match)
        self.session.commit()  # Commit to generate match_id

        # Create teams and add to session
        team_a = team_service.create_team(squad_id=squad_id, match_id=match.match_id, players=team_a_players, color="white")
        team_b = team_service.create_team(squad_id=squad_id, match_id=match.match_id, players=team_b_players, color="black")


        return MatchData(
            squad_id=squad_id,
            match_id=str(match.match_id),
            created_at=match.created_at,
            score=(0, 0),
        )

    def get_match(self, match_id: str) -> MatchData | None:
        match = self.session.query(Match).filter(Match.match_id == match_id).first()
        if not match:
            return None
        from app.services import TeamService
        team_service = TeamService(self.session)
        team_a = team_service.get_team(match.teams[0].team_id)
        team_b = team_service.get_team(match.teams[1].team_id)
        # Convert ORM Match to MatchData
        return MatchData(
            squad_id=match.squad_id,
            match_id=str(match.match_id),
            created_at=match.created_at,
            score=(team_a.score, team_b.score),
        )
    
    def get_match_detail(self, match_id: str) -> MatchDetailData:
        match = self.session.query(Match).filter(Match.match_id == match_id).first()
        if not match:
            return None
        team_a = match.teams[0]
        team_b = match.teams[1]
        if not team_a or not team_b:
            raise ValueError("Team not found")
        from app.services import TeamService
        team_service = TeamService(self.session)

        

        team_a_data = team_service.get_team_details(team_a.team_id)
        team_b_data = team_service.get_team_details(team_b.team_id)

        return MatchDetailData(
            squad_id=match.squad_id,
            match_id=str(match.match_id),
            team_a=team_a_data,
            team_b=team_b_data,
            created_at=match.created_at,

        )  

    def draw_teams(self, match_id: str) -> tuple[list[PlayerData], list[int]]:
        match = self.session.query(Match).filter(Match.match_id == match_id).first()
        if not match:
            return None

        match_players = match.teams[0].players + match.teams[1].players

        players = [PlayerData(
            player_id=player.player_id, 
            name=player.name, 
            _score=player.score, 
            base_score=player.base_score,
            position=player.position,
            squad_id=player.squad_id,
            ) for player in match_players]
        players.sort(key=lambda x: x._score, reverse=True)
        from app.services import DrawTeamsService
        draw_teams_service = DrawTeamsService(players, 2)
        list_of_teams = draw_teams_service.draw_teams()
        print(len(list_of_teams))
        return players, list_of_teams

    def update_match_score(self, match_id: str, team_a_score: int, team_b_score: int) -> MatchDetailData | None:
        match = self.session.query(Match).filter(Match.match_id == match_id).first()
        if not match:
            return None
        
        from app.services import TeamService
        team_service = TeamService(self.session)
        team_a = team_service.update_team_score(match.teams[0].team_id, team_a_score)
        team_b = team_service.update_team_score(match.teams[1].team_id, team_b_score)

        return MatchDetailData(
            squad_id=match.squad_id,
            match_id=str(match.match_id),
            team_a=team_a,
            team_b=team_b,
            created_at=match.created_at
        )
    
    def update_match_players(self, match_id: str, team_a_players: list[PlayerData], team_b_players: list[PlayerData]) -> MatchDetailData | None:
        match = self.session.query(Match).filter(Match.match_id == match_id).first()
        if not match:
            return None
        
        from app.services import TeamService
        team_service = TeamService(self.session)
        team_a = team_service.update_team_players(match.teams[0].team_id, team_a_players)
        team_b = team_service.update_team_players(match.teams[1].team_id, team_b_players)

        return MatchDetailData(
            squad_id=match.squad_id,
            match_id=str(match.match_id),
            team_a=team_a,
            team_b=team_b,
            created_at=match.created_at
        )
        