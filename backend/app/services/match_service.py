from typing import Optional
from app.models import Match, ScoreHistory

from app.entities import MatchData, PlayerData, MatchDetailData, DraftData
from app.models.player import Player
from app.schemas.match_schemas import TeamUpdate


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
            team_b=team_b
        )

    def get_matches(self, squad_id: str) -> list[MatchData]:
        matches = self.session.query(Match).filter(Match.squad_id == squad_id).all()

        match_data = []
        for match in matches:
            match_data.append(self.match_to_data(match))
        return match_data

    def create_match(self, squad_id: str, team_a_players: list[PlayerData], team_b_players: list[PlayerData], team_a_name: str = None, team_b_name: str = None) -> MatchDetailData:
        from app.services import TeamService
        team_service = TeamService(self.session)
        # Create match and add to session
        match = Match(squad_id=squad_id)
        self.session.add(match)
        self.session.commit()  # Commit to generate match_id

        # Create teams and add to session
        team_a = team_service.create_team(squad_id=squad_id, match_id=match.match_id, players=team_a_players, color="white", name=team_a_name)
        team_b = team_service.create_team(squad_id=squad_id, match_id=match.match_id, players=team_b_players, color="black", name=team_b_name)

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

    def draw_teams(self, players_ids: list[str]) -> list[DraftData]:
        # Check if players list is empty
        if not players_ids:
            return []
        
        from app.services import PlayerService
        player_service = PlayerService(self.session)
        
        players = []
        for player_id in players_ids:
            player = player_service.get_player(player_id)
            if player:
                players.append(player)
            
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
                     team_a: TeamUpdate, 
                     team_b: TeamUpdate,
                     ) -> MatchDetailData | None:
        match = self.session.query(Match).filter(Match.match_id == match_id).first()
        if not match:
            return None

        from app.services import TeamService, PlayerService
        team_service = TeamService(self.session)
        player_service = PlayerService(self.session)

        def update_team(team_data):
            if not team_data:
                return
            team_id = team_data.team_id
            if team_data.players is not None:
                player_objs = [player_service.get_player(pid) for pid in team_data.players]
                team_service.update_team_players(team_id, player_objs)
            if team_data.score is not None:
                team_service.update_team_score(team_id, team_data.score)

        update_team(team_a)
        update_team(team_b)

        score = (team_a.score, team_b.score)


        if score is not None and score[0] is not None and score[1] is not None:
            self.update_score_history(match_id, team_a.team_id, team_b.team_id, score[0], score[1])

        self.session.commit()
        return self.get_match_detail(match_id)
    
    def update_score_history(self, match_id: str, team_a_id: str, team_b_id: str, team_a_score: int, team_b_score: int) -> MatchDetailData | None:
        """
        Update score history and player rankings for both teams in a match.
        Assumes team scores are already set in the database.
        """
        match = self.session.query(Match).filter(Match.match_id == match_id).first()
        if not match:
            return None
        from app.services import PlayerService
        player_service = PlayerService(self.session)

        # Get teams by id
        team_a = next((t for t in match.teams if t.team_id == team_a_id), None)
        team_b = next((t for t in match.teams if t.team_id == team_b_id), None)
        if not team_a or not team_b:
            raise ValueError("Team not found")

        # For each player, update score history and player score
        for team, score, opp_score in [
            (team_a, team_a_score, team_b_score),
            (team_b, team_b_score, team_a_score)
        ]:
            for player in team.players:
                # Get match index for this player (count of previous matches)
                player_matches = sorted(player.matches, key=lambda x: x.created_at)
                match_index = next((i for i, m in enumerate(player_matches) if m.match_id == match_id), 0)
                factor = match_index * 0.2 + 1
                delta = (score - opp_score) / factor
                # Get previous score from score history
                score_history = self.session.query(ScoreHistory).filter(
                    ScoreHistory.player_id == player.player_id,
                    ScoreHistory.match_id == match_id
                ).first()
                prev_score = score_history.previous_score if score_history else player.score
                new_score = prev_score + delta
                player_service.update_player_score(player.player_id, new_score, match_id)

        return self.match_to_detail_data(match)
    
    def update_match_players(self, match_id: str, team_a_players: list[str], team_b_players: list[str]) -> MatchDetailData | None:
        match = self.session.query(Match).filter(Match.match_id == match_id).first()
        if not match:
            return None
        
        from app.services import PlayerService
        player_service = PlayerService(self.session)

        team_a_players_data = []
        for player_id in team_a_players:
            player = player_service.get_player(player_id)
            if player:
                team_a_players_data.append(player)
        
        team_b_players_data = []
        
        for player_id in team_b_players:
            player = player_service.get_player(player_id)
            if player:
                team_b_players_data.append(player)
        
        from app.services import TeamService
        team_service = TeamService(self.session)
        
        # Get current players in the match
        current_players = set()
        for team in match.teams:
            for player in team.players:
                current_players.add(player.player_id)
        
        # Get new players

        all_new_players = team_a_players_data + team_b_players_data

        new_players = set()
        for player_id in team_a_players:
            new_players.add(player_id)
        
        for player_id in team_b_players:
            new_players.add(player_id)
        
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
        team_a = team_service.update_team_players(match.teams[0].team_id, team_a_players_data)
        team_b = team_service.update_team_players(match.teams[1].team_id, team_b_players_data)

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
        