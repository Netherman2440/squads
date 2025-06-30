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

  String get displayName {
    switch (this) {
      case Position.none:
        return 'Brak';
      case Position.goalie:
        return 'Bramkarz';
      case Position.field:
        return 'Pole';
      case Position.defender:
        return 'Obrońca';
      case Position.midfielder:
        return 'Pomocnik';
      case Position.forward:
        return 'Napastnik';
    }
  }
} 