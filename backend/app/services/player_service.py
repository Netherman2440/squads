from app.models import Player, Match, ScoreHistory
from app.entities import PlayerData, PlayerDetailData, MatchData
from app.constants import Position
from app.schemas.player_schemas import PlayerResponse, PlayerListResponse
from app.services.match_service import MatchService
from app.services.stat_service import StatService

class PlayerService:
    def __init__(self, session):
        self.session = session

    def player_to_data(self, player: Player) -> PlayerData:
        return PlayerData(
            squad_id=player.squad_id,
            player_id=player.player_id,
            name=player.name,
            position=Position(player.position) if player.position else Position.NONE,
            base_score=player.base_score,
            _score=round(player.score, 2),
            matches_played=len(player.matches),
            created_at=player.created_at
        )
    
    def player_to_detail_data(self, player: Player) -> PlayerDetailData:
        match_service = MatchService(self.session)

        stats_service = StatService(self.session)
        stats = stats_service.get_player_stats(player.player_id)

        return PlayerDetailData(
            squad_id=player.squad_id,
            player_id=player.player_id,
            name=player.name,
            position=Position(player.position) if player.position else Position.NONE,
            base_score=player.base_score,
            _score=round(player.score, 2),
            matches_played=len(player.matches),
            created_at=player.created_at,
            #matches=[match_service.match_to_data(match) for match in player.matches],
            stats=stats,
        )

    def get_players(self, squad_id: str) -> list[PlayerData]:
        """Get all players for a squad and return as list of PlayerData"""
        players = self.session.query(Player).filter(Player.squad_id == squad_id).all()
        player_data_list = [self.player_to_data(player) for player in players]
        
        return player_data_list

    def get_player(self, player_id: str) -> PlayerData | None:
        player = self.session.query(Player).filter(Player.player_id == player_id).first()
        if not player:
            return None
        # Convert ORM Player to PlayerData
        return self.player_to_data(player)
    
    def get_player_data_for_match(self, player_id: str, match_id: str) -> PlayerData | None:
        """Get player data with score adjusted for specific match - if score history exists for this match, return previous_score"""
        player = self.session.query(Player).filter(Player.player_id == player_id).first()
        if not player:
            return None
        
        # Check if there's a score history for this player and match
        score_history = self.session.query(ScoreHistory).filter(
            ScoreHistory.player_id == player_id,
            ScoreHistory.match_id == match_id
        ).first()
        
        # If score history exists, use previous_score, otherwise use current score
        score_to_use = score_history.previous_score if score_history else player.score
        
        return self.player_to_data(player)
    
    def get_player_details(self, player_id: str) -> PlayerDetailData | None:
        player = self.session.query(Player).filter(Player.player_id == player_id).first()
        if not player:
            return None
        return self.player_to_detail_data(player)

    def create_player(self, squad_id: str, name: str, base_score: int, position: Position = Position.NONE) -> PlayerDetailData:
        # Create a new Player ORM object
        player = Player(
            squad_id=squad_id,
            name=name,
            position=position.value if hasattr(position, "value") else position,
            base_score=base_score,
            score=base_score,
        )
        self.session.add(player)
        self.session.commit()
    
        return self.get_player_details(player.player_id)
    
    def delete_player(self, player_id: str) -> None:
        player = self.session.query(Player).filter(Player.player_id == player_id).first()
        if player:
            self.session.delete(player)
            self.session.commit()

    def update_player_name(self, player_id: str, name: str) -> PlayerData | None:
        player = self.session.query(Player).filter(Player.player_id == player_id).first()
        if not player:
            return None
        player.name = name
        self.session.commit()
        return self.get_player(player_id)
    
    def update_player_base_score(self, player_id: str, base_score: int) -> PlayerData | None:
        player = self.session.query(Player).filter(Player.player_id == player_id).first()
        if not player:
            return None
        player.base_score = base_score
        self.session.commit()

        self.recalculate_and_update_score(player_id)
        
        return self.get_player(player_id)
    
    def update_player_score(self, player_id: str, score: float, match_id: str = None) -> PlayerData | None:
        """Manually update player's current score"""
        player = self.session.query(Player).filter(Player.player_id == player_id).first()
        if not player:
            return None

        # Update score history for this player
        score_history = None
        if match_id:
            score_history = self.session.query(ScoreHistory).filter(
                ScoreHistory.player_id == player_id,
                ScoreHistory.match_id == match_id
            ).first()
        if not score_history:
            score_history = ScoreHistory(
                player_id=player_id,
                match_id=match_id,
                previous_score=round(player.score, 2),
                new_score=round(score, 2),
                delta=round(score - player.score, 2)
            )
            self.session.add(score_history)
        else:
            score_history.new_score = round(score, 2)
            score_history.delta = round(score - score_history.previous_score, 2)

        # Don't directly set player.score - instead recalculate from all matches
        # This handles the case where we're updating an old match and need to 
        # preserve deltas from subsequent matches
        self.session.commit()  # Commit the score history changes first
        
        # Recalculate total score from all matches including the updated one
        return self.recalculate_and_update_score(player_id)
    
    def update_player_position(self, player_id: str, position: Position) -> PlayerData | None:
        player = self.session.query(Player).filter(Player.player_id == player_id).first()
        if not player:
            return None
        player.position = position.value if hasattr(position, "value") else position
        self.session.commit()
        return self.get_player(player_id)
    
    def recalculate_and_update_score(self, player_id: str) -> PlayerData | None:
        """Recalculate player score by going through score history to check for changes. Clamp score to [0, 100]."""
        player = self.session.query(Player).filter(Player.player_id == player_id).first()
        if not player:
            return None

        # Start with base_score
        current_score = player.base_score

        # Get all score history records for this player, sorted by match creation date
        score_histories = player.score_history

        # Go through each score history record and apply deltas
        for score_history in score_histories:
            current_score += score_history.delta

        # Clamp score to [0, 100]
        current_score = max(0, min(100, current_score))

        # Update player's score if it has changed
        if player.score != current_score:
            print(f"Updating player {player.name} score from {player.score} to {current_score}")
            player.score = current_score

            #format score to 2 decimal places
            player.score = round(player.score, 2)
            self.session.commit()

        # Return updated PlayerData
        return self.player_to_data(player)

    def calculate_score_delta(self, player: Player, match: Match, match_index: int) -> float:
        # Find the match in which the player played
        player_team = next((team for team in match.teams if any(p.player_id == player.player_id for p in team.players)), None)
        if not player_team:
            return 0
        # Find the opposing team
        opponent_team = next((team for team in match.teams if team != player_team), None)
        if not opponent_team:
            return 0
        
        factor = match_index * 0.2 + 1
        # Calculate how much the player gained/lost in this match
        return (player_team.score - opponent_team.score) / factor

    

