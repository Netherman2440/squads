import '../state/user_state.dart';

class PermissionUtils {
  // Check if user is a guest (no user data in session)
  static bool isGuest(UserSessionState userState) {
    final isGuest = userState.user == null;
    return isGuest;
  }

  // Check if user can create squads (non-guest users only)
  static bool canCreateSquad(UserSessionState userState) {
    final canCreate = !isGuest(userState);
    return canCreate;
  }

  // Check if user is owner of the current squad
  static bool isOwner(UserSessionState userState, String ownerId) {
    return userState.user?.userId == ownerId;
  }

  // Check if user can edit the squad
  static bool canEdit(UserSessionState userState, String ownerId) {
    return isOwner(userState, ownerId);
  }

  // Check if user can manage players
  static bool canManagePlayers(UserSessionState userState, String ownerId) {
    return isOwner(userState, ownerId);
  }

  // Check if user can manage matches
  static bool canManageMatches(UserSessionState userState, String ownerId) {
    return isOwner(userState, ownerId);
  }

  // Check if user can view the squad
  static bool canView(UserSessionState userState, String squadId) {
    return squadId != null;
  }
} 