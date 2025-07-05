import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/match.dart';

class MatchesState {
  final List<Match> matches;

  const MatchesState({this.matches = const []});

  MatchesState copyWith({List<Match>? matches}) {
    return MatchesState(matches: matches ?? this.matches);
  }
}

class MatchesNotifier extends Notifier<MatchesState> {
  @override
  MatchesState build() {
    return const MatchesState();
  }

  void setMatches(List<Match> matches) {
    state = state.copyWith(matches: matches);
  }

  void addMatch(Match match) {
    state = state.copyWith(matches: [...state.matches, match]);
  }

  void removeMatch(String matchId) {
    state = state.copyWith(matches: state.matches.where((m) => m.matchId != matchId).toList());
  }

  void updateMatch(Match match) {
    state = state.copyWith(matches: state.matches.map((m) => m.matchId == match.matchId ? match : m).toList());
  }

  void clearMatches() {
    state = const MatchesState();
  }
}

final matchesProvider = NotifierProvider<MatchesNotifier, MatchesState>(MatchesNotifier.new); 