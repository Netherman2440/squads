import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squads/models/squad.dart';

class SquadState {
  final SquadDetailResponse? squad;



  const SquadState({
    this.squad,

  });

  SquadState copyWith({
    SquadDetailResponse? squad,

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

  void setSquad(SquadDetailResponse squad) {
    state = state.copyWith(squad: squad);
  }

  void updateSquad(SquadDetailResponse squad) {
    state = state.copyWith(squad: squad);
  }

  void clearSquad() {
    state = state.copyWith(squad: null);
  }
}

final squadProvider = NotifierProvider<SquadNotifier, SquadState>(SquadNotifier.new);