from typing import Optional
from app.models import Match, ScoreHistory

from app.entities import MatchData, PlayerData, MatchDetailData, DraftData


class MatchService:
    def __init__(self, session):
        self.session = session

    def match_to_data(self, match: Match) -> MatchData:
        from app.services import TeamService
        team_service = TeamService(self.session)
        
        # Get teams safely
        teams = match.teams

        # Check if teams exist before accessing them
        if len(teams) >= 2:
            team_a = team_service.get_team(teams[0].team_id)
            team_b = team_service.get_team(teams[1].team_id)
            # Check if score is actually set (not default 0-0)
            if team_a.score is None or team_b.score is None:
                score = None
            else:
                score = (team_a.score, team_b.score)
        else:
            # Return None if teams don't exist
            score = None

        return MatchData(
            squad_id=match.squad_id,
            match_id=str(match.match_id),
            created_at=match.created_at,
            score=score,
        )
    
    def match_to_detail_data(self, match: Match) -> MatchDetailData:
        from app.services import TeamService
        team_service = TeamService(self.session)

        if len(match.teams) >= 2:
            team_a = team_service.get_team_details(match.teams[0].team_id)
            team_b = team_service.get_team_details(match.teams[1].team_id)
        else:
            raise ValueError("Team not found")
        if not team_a or not team_b:
            raise ValueError("Team not found")

        return MatchDetailData(
            squad_id=match.squad_id,
            match_id=str(match.match_id),
            created_at=match.created_at,
            team_a=team_a,
            team_b=team_b,
        )

    def get_matches(self, squad_id: str) -> list[MatchData]:
        matches = self.session.query(Match).filter(Match.squad_id == squad_id).all()

        match_data = []
        for match in matches:
            match_data.append(self.match_to_data(match))
        return match_data

    def create_match(self, squad_id: str, team_a_players: list[PlayerData], team_b_players: list[PlayerData]) -> MatchDetailData:

        from app.services import TeamService
        team_service = TeamService(self.session)
        # Create match and add to session
        match = Match(squad_id=squad_id)
        self.session.add(match)
        self.session.commit()  # Commit to generate match_id

        # Create teams and add to session
        team_a = team_service.create_team(squad_id=squad_id, match_id=match.match_id, players=team_a_players, color="white")
        team_b = team_service.create_team(squad_id=squad_id, match_id=match.match_id, players=team_b_players, color="black")

        # Create score history entries for all players with delta = 0
        all_players = team_a_players + team_b_players
        for player in all_players:
            score_history = ScoreHistory(
                match_id=match.match_id,
                player_id=player.player_id,
                previous_score=player.score,
                new_score=player.score,
                delta=0.0
            )
            self.session.add(score_history)
        
        self.session.commit()

        return self.get_match_detail(match.match_id)

    def get_match(self, match_id: str) -> MatchData | None:
        match = self.session.query(Match).filter(Match.match_id == match_id).first()
        if not match:
            return None
        
        return self.match_to_data(match)
    
    def get_match_detail(self, match_id: str) -> MatchDetailData:
        match = self.session.query(Match).filter(Match.match_id == match_id).first()
        if not match:
            return None
        team_a = match.teams[0]
        team_b = match.teams[1]
        if not team_a or not team_b:
            raise ValueError("Team not found")

        return self.match_to_detail_data(match)

    def draw_teams(self, players: list[PlayerData]) -> list[DraftData]:
        # Check if players list is empty
        if not players:
            return []
            
        players.sort(key=lambda x: x._score, reverse=True)
        from app.services import DrawTeamsService
        draw_teams_service = DrawTeamsService(players, 2)
        drafts = draw_teams_service.draw_teams()

        draft_data = []

        for draft in drafts:
            team_a, team_b = draft
            draft_data.append(DraftData(team_a=team_a, team_b=team_b))
            
        return draft_data
    
    def update_match(self, match_id: str, 
                     team_a_players: Optional[list[PlayerData]], 
                     team_b_players: Optional[list[PlayerData]], 
                     score: Optional[tuple[int, int]]) -> MatchDetailData | None:
        if team_a_players and team_b_players:
            self.update_match_players(match_id, team_a_players, team_b_players)
        if score:
            self.update_match_score(match_id, score[0], score[1])
        return self.get_match_detail(match_id)
    
    def update_match_score(self, match_id: str, team_a_score: int, team_b_score: int) -> MatchDetailData | None:
        match = self.session.query(Match).filter(Match.match_id == match_id).first()
        if not match:
            return None
        
        from app.services import TeamService, PlayerService
        team_service = TeamService(self.session)
        player_service = PlayerService(self.session)
        
        # Update team scores
        team_a = team_service.update_team_score(match.teams[0].team_id, team_a_score)
        team_b = team_service.update_team_score(match.teams[1].team_id, team_b_score)

        # Update score history for each player
        all_players = match.teams[0].players + match.teams[1].players
        for player in all_players:
            # Get existing score history to get the previous score
            score_history = self.session.query(ScoreHistory).filter(
                ScoreHistory.player_id == player.player_id,
                ScoreHistory.match_id == match_id
            ).first()
            
            if score_history:
                # Calculate new delta based on updated match scores
                player_team = next((team for team in match.teams if any(p.player_id == player.player_id for p in team.players)), None)
                opponent_team = next((team for team in match.teams if team != player_team), None)
                
                if player_team and opponent_team:
                    # Get match index for this player (count of previous matches)
                    player_matches = sorted(player.matches, key=lambda x: x.created_at)
                    match_index = next((i for i, m in enumerate(player_matches) if m.match_id == match_id), 0)
                    
                    # Calculate new delta
                    factor = match_index * 0.2 + 1
                    new_delta = (player_team.score - opponent_team.score) / factor
                    
                    # Calculate new score based on previous score + new delta
                    new_score = score_history.previous_score + new_delta
                    
                    # Use update_player_score to handle both ScoreHistory and Player updates
                    player_service.update_player_score(player.player_id, new_score, match_id)
        
        # No need for additional commit since update_player_score already commits

        return self.match_to_detail_data(match)
    
    def update_match_players(self, match_id: str, team_a_players: list[PlayerData], team_b_players: list[PlayerData]) -> MatchDetailData | None:
        match = self.session.query(Match).filter(Match.match_id == match_id).first()
        if not match:
            return None
        
        from app.services import TeamService
        team_service = TeamService(self.session)
        
        # Get current players in the match
        current_players = set()
        for team in match.teams:
            for player in team.players:
                current_players.add(player.player_id)
        
        # Get new players
        new_players = set()
        all_new_players = team_a_players + team_b_players
        for player in all_new_players:
            new_players.add(player.player_id)
        
        # Remove score history for players who are no longer in the match
        removed_players = current_players - new_players
        for player_id in removed_players:
            score_history = self.session.query(ScoreHistory).filter(
                ScoreHistory.player_id == player_id,
                ScoreHistory.match_id == match_id
            ).first()
            if score_history:
                self.session.delete(score_history)
        
        # Create score history for new players
        added_players = new_players - current_players
        for player_id in added_players:
            player_data = next((p for p in all_new_players if p.player_id == player_id), None)
            if player_data:
                score_history = ScoreHistory(
                    match_id=match_id,
                    player_id=player_id,
                    previous_score=player_data.score,
                    new_score=player_data.score,
                    delta=0.0
                )
                self.session.add(score_history)
        
        # Update team players
        team_a = team_service.update_team_players(match.teams[0].team_id, team_a_players)
        team_b = team_service.update_team_players(match.teams[1].team_id, team_b_players)

        self.session.commit()

        return self.match_to_detail_data(match)
    
    def delete_match(self, match_id: str) -> bool:
        """Delete a match and all associated data"""
        match = self.session.query(Match).filter(Match.match_id == match_id).first()
        if not match:
            return False
            
        # Delete the match (cascade should handle teams and score history)
        self.session.delete(match)
        self.session.commit()
        
        return True
        