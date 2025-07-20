from app.entities.stats_data import CarouselData, PlayerStatsData, ScoreHistoryData, SquadStatsData, Teammate_Ref
from app.models import Player, Squad, ScoreHistory, Match
from app.services.match_service import MatchService
from app.constants import CarouselType
from app.entities import MatchData

from typing import TYPE_CHECKING
if TYPE_CHECKING:
    from app.services.player_service import PlayerService


class StatService:
    teammates: list[Teammate_Ref] = []
    def __init__(self, session):
        self.session = session
        # Removed: self.player_service = PlayerService(session) - using lazy import instead
        self.match_service = MatchService(session)

    def _get_player_service(self):
        """Lazy import to avoid circular dependency"""
        from app.services.player_service import PlayerService
        return PlayerService(self.session)

    def get_squad_stats(self, squad_id: str) -> SquadStatsData:
        squad = self.session.query(Squad).filter(Squad.squad_id == squad_id).first()
        total_goals = 0
        avg_player_score = 0
        match_datas = []
        player_datas = []
        for match in squad.matches:
            match_data = self.match_service.get_match_detail(match.match_id)
            match_datas.append(match_data)
        for player in squad.players:
            player_data = self._get_player_service().get_player(player.player_id)
            player_datas.append(player_data)

        total_matches = len(match_datas)

        white_goals = 0
        black_goals = 0
        for match_data in match_datas:
            if match_data.team_a.score is None or match_data.team_b.score is None:
                continue
            total_goals += match_data.team_a.score + match_data.team_b.score
            white_goals += match_data.team_a.score if match_data.team_a.score is not None else 0
            black_goals += match_data.team_b.score if match_data.team_b.score is not None else 0

        total_players = len(player_datas)
        for player_data in player_datas:
            avg_player_score += player_data.score

        avg_player_score /= total_players
        avg_goals_per_match = total_goals / total_matches

        return SquadStatsData(
            squad_id=squad.squad_id,
            created_at=squad.created_at,
            total_players=total_players,
            total_matches=total_matches,
            total_goals=total_goals,
            avg_player_score=avg_player_score,
            avg_goals_per_match=avg_goals_per_match,
            avg_score=(round(white_goals / total_matches, 2), round(black_goals / total_matches, 2))
        )

    def get_player_stats(self, player_id: str) -> PlayerStatsData:
        player = self.session.query(Player).filter(Player.player_id == player_id).first()
        matches = sorted(player.matches, key=lambda x: x.created_at, reverse=True)
        carousel_stats: list[CarouselData] = []
        self.teammates = self.get_teammates(player)
        print(self.teammates)
        player_service = self._get_player_service()
        match_service = MatchService(self.session)

        matches_data : list[MatchData] = []
        if matches:
            for match in matches:
                match_data = self.match_service.get_match_detail(match.match_id)
                matches_data.append(match_data)

        biggest_win_match_id = None
        biggest_loss_match_id = None
        biggest_win = 0
        biggest_loss = 0
        biggest_win_streak = 0
        total_wins = 0
        total_losses = 0
        biggest_loss_streak = 0
        win_streak = 0
        loss_streak = 0
        goals_scored = 0
        goals_conceded = 0

        total_matches = len(matches_data)
        total_draws = 0

        temp_win_streak = 0
        temp_loss_streak = 0

        is_win_streak = True
        is_loss_streak = True

        #print(matches_data)
        for match in matches_data:

            player_team = match.team_a if any(player.player_id == player_id for player in match.team_a.players) else match.team_b
            opponent_team = match.team_b if player_team == match.team_a else match.team_a
            #print(player_team.score, opponent_team.score)

            if player_team.score is None or opponent_team.score is None:
                continue

            goals_scored += player_team.score
            goals_conceded += opponent_team.score
            

            diff = player_team.score - opponent_team.score
            if diff > biggest_win:
                biggest_win = diff
                biggest_win_match_id = match.match_id
            if diff < biggest_loss:
                biggest_loss = diff
                biggest_loss_match_id = match.match_id

            if diff > 0:
                
                is_loss_streak = False
                total_wins += 1
                temp_win_streak += 1
                temp_loss_streak = 0
                if is_win_streak:
                    win_streak += 1

            elif diff < 0:
                is_win_streak = False
                total_losses += 1
                temp_loss_streak += 1
                temp_win_streak = 0
                if is_loss_streak:
                    loss_streak += 1
            else:
                total_draws += 1

            if temp_win_streak > biggest_win_streak:
                biggest_win_streak = temp_win_streak

            if temp_loss_streak > biggest_loss_streak:
                biggest_loss_streak = temp_loss_streak

        avg_goals_per_match = (goals_scored + goals_conceded) / total_matches if total_matches > 0 else 0
        avg_score = (goals_scored / total_matches, goals_conceded / total_matches) if total_matches > 0 else (0, 0)

        #score history
        score_history = player.score_history
        score_history = sorted(score_history, key=lambda x: x.created_at)

        score_history_data = []
        score_history_data.append(ScoreHistoryData(score=player.base_score, created_at=player.created_at, match_ref=None))

        for change in score_history:
            if change.match_id:
                match_data = self.match_service.get_match(change.match_id)
                score_history_data.append(ScoreHistoryData(score=round(change.new_score, 2), created_at=change.created_at, match_ref=match_data.to_ref()))
            else:
                score_history_data.append(ScoreHistoryData(score=round(change.new_score, 2), created_at=change.created_at, match_ref=None))

        #carousel stats

        #biggest win
        if biggest_win_match_id:
            match_data = match_service.get_match(biggest_win_match_id)
            biggest_win_statdata = CarouselData(CarouselType.BIGGEST_WIN, value=biggest_win, ref=match_data.to_ref())
            carousel_stats.append(biggest_win_statdata)

        #biggest loss
        if biggest_loss_match_id:
            match_data = match_service.get_match(biggest_loss_match_id)
            biggest_loss_statdata = CarouselData(CarouselType.BIGGEST_LOSS, value=biggest_loss, ref=match_data.to_ref())
            carousel_stats.append(biggest_loss_statdata)

        #win ratio

        if total_matches > 0:
            win_ratio_percentage = total_wins / total_matches
            draw_ratio_percentage = total_draws / total_matches
            loss_ratio_percentage = total_losses / total_matches

            win_ratio_statdata = CarouselData(CarouselType.WIN_RATIO, value=[str(int(win_ratio_percentage * 100)), str(int(draw_ratio_percentage * 100)), str(int(loss_ratio_percentage * 100))])
            carousel_stats.append(win_ratio_statdata)

        #top teammate
        if self.teammates and any(x.games_together > 0 for x in self.teammates):
            top_teammate = None
            top_teammate_value = 0
            for teammate in self.teammates:
                if teammate.games_together > 0:
                    if teammate.games_together > top_teammate_value:
                        top_teammate = teammate
                        top_teammate_value = teammate.games_together

            top_teammate_player_data = self._get_player_service().get_player(top_teammate.player_id)
            top_teammate_statdata = CarouselData(CarouselType.TOP_TEAMMATE, value=top_teammate_value, ref=top_teammate_player_data.to_ref())
            carousel_stats.append(top_teammate_statdata)

        #win teammate
        if self.teammates and any(x.games_together > 0 for x in self.teammates):
            win_teammate = None
            win_teammate_value = 0
            for teammate in self.teammates:
                if teammate.games_together > 0 and teammate.wins_together > 0:
                    if teammate.wins_together / teammate.games_together > win_teammate_value:
                        win_teammate = teammate
                        win_teammate_value = teammate.wins_together / teammate.games_together
            if win_teammate:
                win_teammate_player_data = self._get_player_service().get_player(win_teammate.player_id)
                win_teammate_statdata = CarouselData(CarouselType.WIN_TEAMMATE, value= int(win_teammate_value * 100), ref=win_teammate_player_data.to_ref())
                carousel_stats.append(win_teammate_statdata)

        #worst teammate 
        if self.teammates and any(x.games_together > 0 for x in self.teammates):
            worst_teammate = None
            worst_teammate_value = 0
            for teammate in self.teammates:
                if teammate.games_together > 0 and teammate.losses_together > 0:
                    if teammate.losses_together / teammate.games_together > worst_teammate_value:
                        worst_teammate = teammate
                        worst_teammate_value = teammate.losses_together / teammate.games_together

            if worst_teammate:
                worst_teammate_player_data = self._get_player_service().get_player(worst_teammate.player_id)
                worst_teammate_statdata = CarouselData(CarouselType.WORST_TEAMMATE, value= int(worst_teammate_value * 100), ref=worst_teammate_player_data.to_ref())
                carousel_stats.append(worst_teammate_statdata)

        #nemezis
        if self.teammates and any(x.games_against > 0 for x in self.teammates):
            nemezis = None
            nemezis_value = 0
            for teammate in self.teammates:
                if teammate.games_against > 0 and teammate.losses_against_him > 0:
                    if teammate.losses_against_him / teammate.games_against > nemezis_value:
                        nemezis = teammate
                        nemezis_value = teammate.losses_against_him / teammate.games_against

            #nemezis = max(self.teammates, key=lambda x: (x.losses_against_him / x.games_against ) if x.games_against > 0 else 0)
            #losses_against_him = int(nemezis.losses_against_him / nemezis.games_against * 100)
            if nemezis:

                nemezis_value = [nemezis.wins_against_him, nemezis.losses_against_him]
                nemezis_player_data = self._get_player_service().get_player(nemezis.player_id)
                nemezis_statdata = CarouselData(CarouselType.NEMEZIS, value= nemezis_value, ref=nemezis_player_data.to_ref())
                carousel_stats.append(nemezis_statdata)

        #worst rival
        if self.teammates and any(x.games_against > 0 for x in self.teammates):
            worst_rival = None
            worst_rival_value = 0
            for teammate in self.teammates:
                if teammate.games_against > 0 and teammate.wins_against_him > 0:
                    if teammate.wins_against_him / teammate.games_against > worst_rival_value:
                        worst_rival = teammate
                        worst_rival_value = teammate.wins_against_him / teammate.games_against

            #worst_rival = max(self.teammates, key=lambda x: x.wins_against_him / x.games_against if x.games_against > 0 else 0)
            #wins_against_him = int(worst_rival.wins_against_him / worst_rival.games_against * 100)
            if worst_rival:
                worst_rival_value = [worst_rival.wins_against_him, worst_rival.losses_against_him]
                worst_rival_player_data = self._get_player_service().get_player(worst_rival.player_id)
                worst_rival_statdata = CarouselData(CarouselType.WORST_RIVAL, value= worst_rival_value, ref=worst_rival_player_data.to_ref())
                carousel_stats.append(worst_rival_statdata)

        #h2h
        if self.teammates and any(x.games_against > 0 for x in self.teammates):
            h2h = None
            h2h_value = 0
            for teammate in self.teammates:
                if teammate.games_against > 0:
                    if teammate.games_against > h2h_value:
                        h2h = teammate
                        h2h_value = teammate.games_against
            h2h_value = self.get_h2h_value(player, h2h.player_id)
            h2h_player_data = self._get_player_service().get_player(h2h.player_id)
            h2h_statdata = CarouselData(CarouselType.H2H, value=h2h_value, ref=h2h_player_data.to_ref())
            carousel_stats.append(h2h_statdata)



        return PlayerStatsData(
            player_id=player.player_id,
            base_score=player.base_score,
            score=player.score,
            win_streak=win_streak,
            loss_streak=loss_streak,
            biggest_win_streak=biggest_win_streak,
            biggest_loss_streak=biggest_loss_streak,
            goals_scored=goals_scored,
            goals_conceded=goals_conceded,
            avg_goals_per_match=avg_goals_per_match,
            avg_score=avg_score,
            total_matches=total_matches,
            total_wins=total_wins,
            total_losses=total_losses,
            total_draws=total_draws,
            score_history=score_history_data,
            carousel_stats=carousel_stats
        )
    
    
    def get_h2h_value(self, player_model: Player, opponent_id: str) -> list[str]:
        results: list[str] = []
        matches = player_model.matches
        matches_data: list[MatchData] = []
        for match in matches:
            match_data = self.match_service.get_match_detail(match.match_id)
            matches_data.append(match_data)
        
        matches_data.sort(key=lambda x: x.created_at, reverse=True)
        for match in matches_data:
            player_team = match.team_a if any(player.player_id == player_model.player_id for player in match.team_a.players) else match.team_b
            opponent_team = match.team_b if player_team == match.team_a else match.team_a

            if(opponent_id not in [player.player_id for player in opponent_team.players]):
                continue

            if player_team.score > opponent_team.score:
                results.append("W")
            elif player_team.score < opponent_team.score:
                results.append("L")
            else:
                results.append("D")

        # Pad results with 'X' to ensure minimum length of 5
        while len(results) < 5:
            results.append("X")
        return results

    def get_teammate_ref(self, player_id: str) -> Teammate_Ref:
            teammate_ref = next((t for t in self.teammates if t.player_id == player_id), None)
            if not teammate_ref:
                teammate_ref = Teammate_Ref(player_id)
                self.teammates.append(teammate_ref)
            return teammate_ref

    def get_teammates(self, player_model: Player) -> list[Teammate_Ref]:
        self.teammates = []

        match_details = []
        for match in player_model.matches:
            match_data = MatchService(self.session).get_match_detail(match.match_id)
            match_details.append(match_data)

        print(player_model.player_id)
        for match_data in match_details:
            #print(match_data)
            player_team = match_data.team_a if any(player.player_id == player_model.player_id for player in match_data.team_a.players) else match_data.team_b
            opponent_team = match_data.team_b if player_team == match_data.team_a else match_data.team_a
            print('player_team', player_team.score)
            print('opponent_team', opponent_team.score)
            if player_team.score is None or opponent_team.score is None:
                continue
            print('hello')
            for teammate in player_team.players:
                if teammate.player_id != player_model.player_id:
                    teammate_ref = self.get_teammate_ref(teammate.player_id)
                    teammate_ref.games_together += 1
                    if player_team.score > opponent_team.score:
                        teammate_ref.wins_together += 1
                    elif player_team.score < opponent_team.score:
                        teammate_ref.losses_together += 1

            for teammate in opponent_team.players:
                if teammate.player_id != player_model.player_id:
                    teammate_ref = self.get_teammate_ref(teammate.player_id)
                    teammate_ref.games_against += 1
                    if player_team.score > opponent_team.score:
                        teammate_ref.wins_against_him += 1
                    elif player_team.score < opponent_team.score:
                        teammate_ref.losses_against_him += 1


        return self.teammates
