from app.entities.stats_data import SquadStats, PlayerStats


class StatService:
    def __init__(self):
        pass

    def get_squad_stats(self, squad_id: int) -> SquadStats:
        pass

    def get_player_stats(self, player_id: int) -> PlayerStats:
        pass