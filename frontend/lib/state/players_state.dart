import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/player.dart';

class PlayersState {
  final List<Player> players;

  const PlayersState({this.players = const []});

  PlayersState copyWith({List<Player>? players}) {
    return PlayersState(players: players ?? this.players);
  }
}

class PlayersNotifier extends Notifier<PlayersState> {
  @override
  PlayersState build() {
    return const PlayersState();
  }

  void setPlayers(List<Player> players) {
    state = state.copyWith(players: players);
  }

  void addPlayer(Player player) {
    state = state.copyWith(players: [...state.players, player]);
  }

  void removePlayer(String playerId) {
    state = state.copyWith(players: state.players.where((p) => p.playerId != playerId).toList());
  }

  void updatePlayer(Player player) {
    state = state.copyWith(players: state.players.map((p) => p.playerId == player.playerId ? player : p).toList());
  }

  void clearPlayers() {
    state = const PlayersState();
  }
}

final playersProvider = NotifierProvider<PlayersNotifier, PlayersState>(PlayersNotifier.new); 