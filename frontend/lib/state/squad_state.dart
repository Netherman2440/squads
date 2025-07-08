import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squads/models/squad.dart';

class SquadState {
  final Squad? squad;



  const SquadState({
    this.squad,

  });

  SquadState copyWith({
    Squad? squad,

  }) {
    return SquadState(
      squad: squad ?? this.squad,

    );
  }

  bool isOwner(String userId) {
    return squad?.ownerId == userId;
  }

}

class SquadNotifier extends Notifier<SquadState> {
  @override
  SquadState build() {
    return const SquadState();
  }

  void setSquad(Squad squad) {
    state = state.copyWith(squad: squad);
  }

  void updateSquad(Squad squad) {
    state = state.copyWith(squad: squad);
  }

  void clearSquad() {
    state = state.copyWith(squad: null);
  }
}

final squadProvider = NotifierProvider<SquadNotifier, SquadState>(SquadNotifier.new);