import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squads/models/user.dart';
import 'package:squads/services/auth_service.dart';

class UserSessionState {
  final User? user;
  final String? token;
  
  const UserSessionState({this.user, this.token});
  
  UserSessionState copyWith({User? user, String? token, bool clearUser = false, bool clearToken = false}) {
    return UserSessionState(
      user: clearUser ? null : (user ?? this.user),
      token: clearToken ? null : (token ?? this.token),
    );
  }
}

class UserSessionNotifier extends Notifier<UserSessionState> {
  @override
  UserSessionState build() {
    return const UserSessionState();
  }
  
  void setUser(User user) {
    state = state.copyWith(user: user);
  }
  
  void setToken(String token) {
    state = state.copyWith(token: token);
    // Synchronize with AuthService
    AuthService.instance.updateToken(token);
  }
  
  void clearUser() {
    state = state.copyWith(clearUser: true, clearToken: true);
    // Don't call AuthService here - let logout handle it
  }
  
  void clearToken() {
    state = state.copyWith(clearToken: true);
    // Don't call AuthService here - let logout handle it
  }
  
  void logout() {
    // Clear the state first
    clearUser();
    // Then clear AuthService tokens (redundant but safe)
    AuthService.instance.logout();
  }
}

final userSessionProvider = NotifierProvider<UserSessionNotifier, UserSessionState>(
  () => UserSessionNotifier(),
);