
from app.db import Player, Match
from app.entities import PlayerData, PlayerDetailData, Position, MatchData

class PlayerService:
    def __init__(self, session):
        self.session = session

    def get_player(self, player_id: str) -> PlayerData | None:
        player = self.session.query(Player).filter(Player.player_id == player_id).first()
        if not player:
            return None
        # Convert ORM Player to PlayerData
        return PlayerData(
            player_id=player.player_id,
            name=player.name,
            position=Position(player.position) if player.position else Position.NONE,
            base_score=player.base_score,
            score=player.score,
            matches_played=len(player.matches)
        )
    
    def get_player_details(self, player_id: str) -> PlayerDetailData | None:
        player = self.session.query(Player).filter(Player.player_id == player_id).first()
        if not player:
            return None
        
        matches = []
        for match in player.matches:
            matches.append(MatchData(
                match_id=match.match_id,
                team_a=match.team_a,
                team_b=match.team_b
            ))
        return PlayerDetailData(
            player_id=player.player_id,
        )

    def create_player(self, squad_id: str, name: str, base_score: int, position: Position = Position.NONE, score: float = 0.0, matches_played: int = 0) -> PlayerData:
        # Create a new Player ORM object
        player = Player(
            squad_id=squad_id,
            name=name,
            position=position.value if hasattr(position, "value") else position,
            base_score=base_score,
            score=score,
            matches_played=matches_played
        )
        self.session.add(player)
        self.session.commit()
        # Return PlayerData with the generated player_id
        return PlayerData(
            squad_id=player.squad_id,
            player_id=player.player_id,
            name=player.name,
            position=Position(player.position) if player.position else Position.NONE,
            base_score=player.base_score,
            score=player.score,
            matches_played=len(player.matches)
        )

    def update_player(self, player_data: PlayerData) -> PlayerData | None:
        player = self.session.query(Player).filter(Player.player_id == player_data.player_id).first()
        if not player:
            return None
        player.squad_id = player_data.squad_id
        player.name = player_data.name
        player.position = player_data.position.value if hasattr(player_data.position, "value") else player_data.position
        player.base_score = player_data.base_score
        player.score = player_data.score
        player.matches_played = player_data.matches_played
        self.session.commit()
        return player_data

    def delete_player(self, player_id: str) -> None:
        player = self.session.query(Player).filter(Player.player_id == player_id).first()
        if player:
            self.session.delete(player)
            self.session.commit()
    
    def recalculate_and_update_score(self, player_id: str) -> PlayerData | None:
        player = self.session.query(Player).filter(Player.player_id == player_id).first()
        if not player:
            return None

        # Start with base_score
        score = player.base_score

        # Sort matches by date (oldest first)
        matches = sorted(player.matches, key=lambda x: x.created_at)
        for i, match in enumerate(matches):
            score += self.calculate_score_delta(player, match, i)

        # Update score in the database
        player.score = score
        self.session.commit()

        # Return updated PlayerData
        return PlayerData(
            squad_id=player.squad_id,
            player_id=player.player_id,
            name=player.name,
            position=Position(player.position) if player.position else Position.NONE,
            base_score=player.base_score,
            _score=player.score,
            matches_played=len(player.matches)
        )


    def calculate_score_delta(self, player: Player, match: Match, match_index: int) -> float:
        # znajdz mecz w którym grał gracz
        player_team = next((team for team in match.teams if any(p.player_id == player.player_id for p in team.players)), None)
        if not player_team:
            return 0
        # znajdz drużynę przeciwną
        opponent_team = next((team for team in match.teams if team != player_team), None)
        if not opponent_team:
            return 0
        
        factor = match_index * 0.2 + 1
        # policz ile gracz zyskał/stracił w tym meczu
        return (player_team.score - opponent_team.score) / factor

    

