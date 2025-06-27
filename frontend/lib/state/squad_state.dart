import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/squad.dart';

class SquadState {
  final Squad? squad;
  
  const SquadState({this.squad});

}

class SquadNotifier extends Notifier<SquadState> {
  @override
  SquadState build() {
    return const SquadState();
  }

  void setSquad(Squad squad) {
    state = SquadState(squad: squad);
  }

  void clearSquad() {
    state = const SquadState();
  }
}

final squadProvider = NotifierProvider<SquadNotifier, SquadState>(
  () => SquadNotifier(),
);

