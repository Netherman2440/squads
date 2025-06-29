import '../state/user_state.dart';

class PermissionUtils {
  // Check if user is owner of the current squad
  static bool isOwner(UserSessionState userState, String squadId) {
    return userState.user?.userId == squadId;
  }

  // Check if user can edit the squad
  static bool canEdit(UserSessionState userState, String squadId) {
    return isOwner(userState, squadId);
  }

  // Check if user can manage players
  static bool canManagePlayers(UserSessionState userState, String squadId) {
    return isOwner(userState, squadId);
  }

  // Check if user can manage matches
  static bool canManageMatches(UserSessionState userState, String squadId) {
    return isOwner(userState, squadId);
  }

  // Check if user can view the squad
  static bool canView(UserSessionState userState, String squadId) {
    return squadId != null;
  }
} 