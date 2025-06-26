enum Position {
  none,
  goalie,
  field,
  defender,
  midfielder,
  forward;

  static Position fromString(String value) {
    return Position.values.firstWhere(
      (position) => position.name == value,
      orElse: () => Position.none,
    );
  }

  String toJson() => name;
} 