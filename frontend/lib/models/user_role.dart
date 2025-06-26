enum UserRole {
  none,
  owner,
  admin,
  moderator,
  member;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.none,
    );
  }

  String toJson() => name;
} 