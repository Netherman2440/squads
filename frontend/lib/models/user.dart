import 'squad.dart';

class User {
  final String userId;
  final String email;
  final DateTime createdAt;
  final List<Squad> ownedSquads;
  final List<Squad> squads;

  User({
    required this.userId,
    required this.email,
    required this.createdAt,
    this.ownedSquads = const [],
    this.squads = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      email: json['email'],
      createdAt: DateTime.parse(json['created_at']),
      ownedSquads: json['owned_squads'] != null 
          ? (json['owned_squads'] as List).map((s) => Squad.fromJson(s)).toList()
          : [],
      squads: json['squads'] != null 
          ? (json['squads'] as List).map((s) => Squad.fromJson(s)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'owned_squads': ownedSquads.map((s) => s.toJson()).toList(),
      'squads': squads.map((s) => s.toJson()).toList(),
    };
  }
}

class UserRegister {
  final String email;
  final String password;

  UserRegister({
    required this.email,
    required this.password,
  });

  factory UserRegister.fromJson(Map<String, dynamic> json) {
    return UserRegister(
      email: json['email'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class UserLogin {
  final String email;
  final String password;

  UserLogin({
    required this.email,
    required this.password,
  });

  factory UserLogin.fromJson(Map<String, dynamic> json) {
    return UserLogin(
      email: json['email'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  } 
}

class AuthResponse {
  final String accessToken;
  final String tokenType;
  final User? user;

  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      tokenType: json['token_type'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'user': user?.toJson(),
    };
  }
} 