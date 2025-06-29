import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/squad.dart';

class SquadState {
  final SquadDetailResponse? squad;
  
  const SquadState({this.squad});

}

class SquadNotifier extends Notifier<SquadState> {
  @override
  SquadState build() {
    return const SquadState();
  }

  void setSquad(SquadDetailResponse squad) {
    state = SquadState(squad: squad);
  }

  void clearSquad() {
    state = const SquadState();
  }
}

final squadProvider = NotifierProvider<SquadNotifier, SquadState>(
  () => SquadNotifier(),
);

