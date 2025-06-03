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
    def __init__(self, players: list[PlayerData], amount_of_teams: int = 2, amount_of_draws: int = 20):
        self.players = sorted(players, key=lambda x: x.score, reverse=True)
        self.amount_of_teams = amount_of_teams
        self.amount_of_draws = amount_of_draws

    def draw_teams(self) -> list[int]:
        if self.amount_of_teams == 2:
            return self.draw_teams_2()[0:self.amount_of_draws]
        elif self.amount_of_teams == 3:
            return self.draw_teams_3()[0:self.amount_of_draws]
        else:
            raise ValueError("Invalid amount of teams")

    def draw_teams_2(self) -> list[int]:
        team_size = len(self.players) // self.amount_of_teams
        players_amount = len(self.players)
        total_score = sum(player.score for player in self.players)
        #print(total_score)
        combos = []
        for combo in combinations(range(players_amount), team_size):
            combos.append(combo)

        # Sort combos by how close their score is to half of the total score
        combos = sorted(
            combos,
            key=lambda x: abs(sum(self.players[i].score for i in x) - total_score / 2)
        )

        return combos

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
    players = [
        PlayerData.create(name="John", base_score=100, squad_id="squad-1"),
        PlayerData.create(name="Jane", base_score=90, squad_id="squad-1"),
        PlayerData.create(name="Jim", base_score=80, squad_id="squad-1"),
        PlayerData.create(name="Jill", base_score=70, squad_id="squad-1"),
        PlayerData.create(name="Jack", base_score=60, squad_id="squad-1"),
        PlayerData.create(name="Jerry", base_score=95, squad_id="squad-2"),
        PlayerData.create(name="Janet", base_score=85, squad_id="squad-2"),
        PlayerData.create(name="Jacob", base_score=75, squad_id="squad-2"),
        PlayerData.create(name="Julia", base_score=65, squad_id="squad-2"),
        PlayerData.create(name="Jordan", base_score=55, squad_id="squad-2"),
        PlayerData.create(name="Jasper", base_score=92, squad_id="squad-3"),
        PlayerData.create(name="Jade", base_score=82, squad_id="squad-3"),
        PlayerData.create(name="Joan", base_score=72, squad_id="squad-3"),
        PlayerData.create(name="Jules", base_score=62, squad_id="squad-3"),
        PlayerData.create(name="Joy", base_score=52, squad_id="squad-3"),
        PlayerData.create(name="Jeff", base_score=88, squad_id="squad-4"),
        PlayerData.create(name="Josie", base_score=78, squad_id="squad-4"),
        PlayerData.create(name="Johan", base_score=68, squad_id="squad-4"),
        PlayerData.create(name="James", base_score=58, squad_id="squad-4"),
        PlayerData.create(name="Jocelyn", base_score=48, squad_id="squad-4"),
        PlayerData.create(name="Jeremy", base_score=77, squad_id="squad-5"),
        PlayerData.create(name="Jenna", base_score=67, squad_id="squad-5"),
    ]
    draw_teams_service = DrawTeamsService(players, 2)
    teams = draw_teams_service.draw_teams()

    print(teams)
    print(len(teams))
