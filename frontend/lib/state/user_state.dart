import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/user.dart';

class UserSessionState {
  final User? user;
  final String? token;
  
  const UserSessionState({this.user, this.token});
  
  UserSessionState copyWith({User? user, String? token}) {
    return UserSessionState(
      user: user ?? this.user,
      token: token ?? this.token,
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
    print('Token set: $token');
  }
  
  void clearUser() {
    state = state.copyWith(user: null, token: null);
  }
  
  void clearToken() {
    state = state.copyWith(token: null);
  }
}

final userSessionProvider = NotifierProvider<UserSessionNotifier, UserSessionState>(
  () => UserSessionNotifier(),
);