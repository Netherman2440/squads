import '../state/user_state.dart';
import '../state/squad_state.dart';

class PermissionUtils {
  // Check if user is owner of the current squad
  static bool isOwner(UserSessionState userState, SquadState squadState) {
    return userState.user?.userId == squadState.squad?.ownerId;
  }

  // Check if user can edit the squad
  static bool canEdit(UserSessionState userState, SquadState squadState) {
    return isOwner(userState, squadState);
  }

  // Check if user can manage players
  static bool canManagePlayers(UserSessionState userState, SquadState squadState) {
    return isOwner(userState, squadState);
  }

  // Check if user can manage matches
  static bool canManageMatches(UserSessionState userState, SquadState squadState) {
    return isOwner(userState, squadState);
  }

  // Check if user can view the squad
  static bool canView(UserSessionState userState, SquadState squadState) {
    return squadState.squad != null;
  }
} 