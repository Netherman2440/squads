from enum import Enum
from app.entities import PlayerData
from itertools import combinations

class Relation(Enum):
    FRIEND = 1
    ENEMY = 2

class Relation:
    def __init__(self, player_1: PlayerData, player_2: PlayerData, relation: int):
        self.player_1 = player_1
        self.player_2 = player_2
        self.relation = relation

#players are sorted by score from highest to lowest
class DrawTeamsService:
    def __init__(self, players: list[PlayerData], amount_of_teams: int = 2, amount_of_draws: int = 20, allow_substitutions: bool = True):
        self.players = sorted(players, key=lambda x: x.score, reverse=True)
        self.amount_of_teams = amount_of_teams
        self.amount_of_draws = amount_of_draws
        self.allow_substitutions = allow_substitutions

    def draw_teams(self) -> list[tuple[list[PlayerData], list[PlayerData]]]:
        if self.amount_of_teams == 2:
            combos = self.draw_teams_2()
            return combos
        elif self.amount_of_teams == 3:
            combos = self.draw_teams_3()
            return combos
        else:
            raise ValueError("Invalid amount of teams")

    def draw_teams_2(self) -> list[tuple[list[PlayerData], list[PlayerData]]]:
        team_size = len(self.players) // self.amount_of_teams
        players_amount = len(self.players)
        total_score = sum(player.score for player in self.players)
        
        combos = []
        for combo in combinations(range(players_amount), team_size):
            # Filter out duplicate team combinations by ensuring the first player 
            # (lowest index) is in the first half of all players
            if min(combo) < players_amount // 2:
                combos.append(combo)

        # Sort combos by how close their score is to half of the total score
        combos = sorted(
            combos,
            key=lambda x: (
                abs(self._get_effective_combo_score(x) - self._get_effective_total_score() / 2),  # First: team balance
                self._calculate_squared_differences_for_combo(x)                                   # Second: squared differences
            )
        )

        combos = combos[0:self.amount_of_draws]

        draft_data = []

        for combo in combos:
            team_a = [self.players[i] for i in combo]
            team_b = [player for player in self.players if player not in team_a]
            draft_data.append((team_a, team_b))

        return draft_data
    
    def _get_effective_total_score(self) -> float:
        """Get total score of all players considering substitutions"""
        if not self.allow_substitutions:
            return sum(player.score for player in self.players)
        
        # If substitutions allowed and odd number of players, exclude the weakest
        total_players = len(self.players)
        expected_smaller_team_size = total_players // self.amount_of_teams
        
        if total_players % self.amount_of_teams != 0:
            # Odd number - exclude the weakest player
            return sum(player.score for player in self.players[:-1])
        else:
            return sum(player.score for player in self.players)
    
    def _get_effective_combo_score(self, combo: tuple) -> float:
        """Get effective score for a combo considering substitutions"""
        team_a = [self.players[i] for i in combo]
        team_b = [self.players[i] for i in range(len(self.players)) if i not in combo]
        
        return self._get_effective_team_score(team_a, team_b)
    
    def _get_effective_team_score(self, team_a: list[PlayerData], team_b: list[PlayerData]) -> float:
        """Get team A score considering substitutions option"""
        if not self.allow_substitutions:
            return sum(player.score for player in team_a)
        
        # If team sizes are different, exclude weakest player from larger team
        if len(team_a) > len(team_b):
            # team_a is larger, exclude its weakest player
            team_a_sorted = sorted(team_a, key=lambda x: x.score, reverse=True)
            return sum(player.score for player in team_a_sorted[:-1])
        else:
            return sum(player.score for player in team_a)
    
    def _calculate_squared_differences_for_combo(self, combo: tuple) -> float:
        """Calculate sum of squared differences for a specific combination of player indices"""
        # Create teams from the combo
        team_a = [self.players[i] for i in combo]
        team_b = [self.players[i] for i in range(len(self.players)) if i not in combo]
        
        # Sort both teams by score (highest to lowest)
        team_a_sorted = sorted(team_a, key=lambda x: x.score, reverse=True)
        team_b_sorted = sorted(team_b, key=lambda x: x.score, reverse=True)
        
        # Handle substitutions - exclude weakest player from larger team
        if self.allow_substitutions and len(team_a_sorted) != len(team_b_sorted):
            if len(team_a_sorted) > len(team_b_sorted):
                # team_a is larger, exclude its weakest player
                team_a_sorted = team_a_sorted[:-1]
            else:
                # team_b is larger, exclude its weakest player
                team_b_sorted = team_b_sorted[:-1]
        
        # Calculate sum of squared differences between corresponding players
        squared_sum = 0
        for i in range(min(len(team_a_sorted), len(team_b_sorted))):
            diff = team_a_sorted[i].score - team_b_sorted[i].score
            squared_sum += diff * diff
        
        return squared_sum

    def draw_teams_3(self) -> list[int]:
        team_size = len(self.players) // self.amount_of_teams
        players_amount = len(self.players)
        all_teams = []
        # Generate all possible combinations for the first team
        for first_team in combinations(range(players_amount), team_size):
            remaining_players = [i for i in range(players_amount) if i not in first_team]
            # Generate all possible combinations for the second team from remaining players
            for second_team in combinations(remaining_players, team_size):
                third_team = [i for i in remaining_players if i not in second_team]
                all_teams.append([list(first_team), list(second_team), third_team])
        return all_teams
    
#cd backend
#python -m app.services.draw_teams_service
if __name__ == "__main__":
    from datetime import datetime
    
    players = [
        PlayerData(squad_id="squad-1", player_id="1", name="John", base_score=100, created_at=datetime.now()),
        PlayerData(squad_id="squad-1", player_id="2", name="Jane", base_score=90, created_at=datetime.now()),
        PlayerData(squad_id="squad-1", player_id="3", name="Jim", base_score=80, created_at=datetime.now()),
        PlayerData(squad_id="squad-1", player_id="4", name="Jill", base_score=70, created_at=datetime.now()),
        PlayerData(squad_id="squad-1", player_id="5", name="Jack", base_score=60, created_at=datetime.now()),
    ]
    draw_teams_service = DrawTeamsService(players, 2, amount_of_draws=5)
    teams = draw_teams_service.draw_teams()

    print("Team combinations (5 players with substitutions):")
    for i, (team_a, team_b) in enumerate(teams):
        team_a_score = draw_teams_service._get_effective_team_score(team_a, team_b)
        team_b_score = draw_teams_service._get_effective_team_score(team_b, team_a)
        score_diff = abs(team_a_score - team_b_score)
        
        print(f"Combination {i+1}:")
        print(f"  Team A ({len(team_a)} players, effective score: {team_a_score}): {[p.name for p in team_a]}")
        print(f"  Team B ({len(team_b)} players, effective score: {team_b_score}): {[p.name for p in team_b]}")
        print(f"  Score difference: {score_diff}")
        print()
