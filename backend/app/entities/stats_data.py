

from app.constants import StatType
from app.models import Player, Match


class Squad_Stat: #base class for all squad stats
    stat_type: StatType
    value: int | float

    def __init__(self, stat_type: StatType, value: int | float):
        self.stat_type = stat_type
        self.value = value

class Player_Ref_Stat:

    def __init__(self, stat_type: StatType, value: int | float, player_ref: Player):
        self.stat_type = stat_type
        self.value = value
        self.player_ref = player_ref

class Head_to_Head_Stat:
    def __init__(self, stat_type: StatType, value: list[str], player_ref: Player):
        self.stat_type = stat_type
        self.value = value
        self.player_ref = player_ref

class Player_To_Player_Stat:
    def __init__(self, stat_type: StatType, value: int | float, player_a_ref: Player, player_b_ref: Player):
        self.stat_type = stat_type
        self.value = value
        self.player_a_ref = player_a_ref
        self.player_b_ref = player_b_ref

class Match_Ref_Stat:
    def __init__(self, stat_type: StatType, value: int | float, match_ref: Match):
        self.stat_type = stat_type
        self.value = value
        self.match_ref = match_ref

class Win_Ratio_Stat:

    def __init__(self,  win: float, lose: float, draw: float, player_ref: Player):
        self.stat_type = StatType.WIN_RATIO
        self.win = win
        self.lose = lose
        self.draw = draw
        self.player_ref = player_ref




class PlayerStats:
    player_ref_stats: list[Player_Ref_Stat] #worst_rival, , nemezis, top_rival, worst_teammate, win_teammate, top_teammate, 
    win_ratio: Win_Ratio_Stat #win_ratio
    head_to_head_stats: list[Head_to_Head_Stat] #h2h
    squad_stats: list[Squad_Stat] #Avg goals, avg_goals_against, avg_goals, win_streak,


class SquadStats:
    player_ref_stats: list[Player_Ref_Stat] #best_player, best_delta, win_streak, win_ratio, avg_goals
    player_to_player_stats: list[Player_To_Player_Stat] #teamwork, domination
    match_ref_stats: list[Match_Ref_Stat] #recent_match, next_match, biggest_win
        

