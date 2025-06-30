import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/player.dart';

class DraftState {
  final List<Player> allPlayers;
  final List<Player> selectedPlayers;

  const DraftState({
    this.allPlayers = const [],
    this.selectedPlayers = const [],
  });

  DraftState copyWith({
    List<Player>? allPlayers,
    List<Player>? selectedPlayers,
  }) {
    return DraftState(
      allPlayers: allPlayers ?? this.allPlayers,
      selectedPlayers: selectedPlayers ?? this.selectedPlayers,
    );
  }

  bool isPlayerSelected(Player player) {
    return selectedPlayers.any((p) => p.playerId == player.playerId);
  }

  List<Player> get availablePlayers {
    return allPlayers.where((player) => !isPlayerSelected(player)).toList();
  }
}

class DraftNotifier extends Notifier<DraftState> {
  @override
  DraftState build() {
    return const DraftState();
  }

  void setAllPlayers(List<Player> players) {
    state = state.copyWith(allPlayers: players);
  }

  void addPlayer(Player player) {
    if (!state.isPlayerSelected(player)) {
      final newSelectedPlayers = [...state.selectedPlayers, player];
      state = state.copyWith(selectedPlayers: newSelectedPlayers);
    }
  }

  void removePlayer(Player player) {
    final newSelectedPlayers = state.selectedPlayers
        .where((p) => p.playerId != player.playerId)
        .toList();
    state = state.copyWith(selectedPlayers: newSelectedPlayers);
  }

  void togglePlayer(Player player) {
    if (state.isPlayerSelected(player)) {
      removePlayer(player);
    } else {
      addPlayer(player);
    }
  }

  void clearSelectedPlayers() {
    state = state.copyWith(selectedPlayers: []);
  }
}

final draftProvider = NotifierProvider<DraftNotifier, DraftState>(
  () => DraftNotifier(),
); 