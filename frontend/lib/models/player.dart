import 'position.dart';

class Player {
  final String playerId;
  final String squadId;
  final String name;
  final int baseScore;
  final double score;
  final Position position;
  final int matchesPlayed;
  final DateTime createdAt; // Add createdAt

  Player({
    required this.playerId,
    required this.squadId,
    required this.name,
    required this.baseScore,
    required this.score,
    required this.position,
    required this.matchesPlayed,
    required this.createdAt,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      playerId: json['player_id'],
      squadId: json['squad_id'],
      name: json['name'],
      baseScore: json['base_score'],
      score: json['score'] != null ? json['score'].toDouble() : 0.0,
      position: Position.fromString(json['position']),
      matchesPlayed: json['matches_played'],
      createdAt: DateTime.tryParse(json['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'player_id': playerId,
      'squad_id': squadId,
      'name': name,
      'base_score': baseScore,
      'score': score,
      'position': position.toJson(),
      'matches_played': matchesPlayed,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class PlayerCreate {
  final String name;
  final int baseScore;
  final Position? position;

  PlayerCreate({
    required this.name,
    required this.baseScore,
    this.position,
  });

  factory PlayerCreate.fromJson(Map<String, dynamic> json) {
    return PlayerCreate(
      name: json['name'],
      baseScore: json['base_score'],
      position: json['position'] != null 
          ? Position.fromString(json['position']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'base_score': baseScore,
      if (position != null) 'position': position!.toJson(),
    };
  }
}

class PlayerUpdate {
  final String playerId;
  final String? name;
  final int? baseScore;
  final Position? position;
  final double? score;

  PlayerUpdate({
    required this.playerId,
    this.name,
    this.baseScore,
    this.position,
    this.score,
  });

  factory PlayerUpdate.fromJson(Map<String, dynamic> json) {
    return PlayerUpdate(
      playerId: json['player_id'],
      name: json['name'],
      baseScore: json['base_score'],
      position: json['position'] != null 
          ? Position.fromString(json['position']) 
          : null,
      score: json['score']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'player_id': playerId};
    if (name != null) data['name'] = name;
    if (baseScore != null) data['base_score'] = baseScore;
    if (position != null) data['position'] = position!.toJson();
    if (score != null) data['score'] = score;
    return data;
  }
}

class PlayerListResponse {
  final List<Player> players;

  PlayerListResponse({required this.players});

  factory PlayerListResponse.fromJson(Map<String, dynamic> json) {
    return PlayerListResponse(
      players: (json['players'] as List)
          .map((playerJson) => Player.fromJson(playerJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'players': players.map((player) => player.toJson()).toList(),
    };
  }
}

class PlayerDetailResponse extends Player {
  final List<dynamic> matches; // Using dynamic to avoid circular dependency

  PlayerDetailResponse({
    required super.playerId,
    required super.squadId,
    required super.name,
    required super.baseScore,
    required super.score,
    required super.position,
    required super.matchesPlayed,
    required this.matches,
    required super.createdAt,
  });

  factory PlayerDetailResponse.fromJson(Map<String, dynamic> json) {
    return PlayerDetailResponse(
      playerId: json['player_id'],
      squadId: json['squad_id'],
      name: json['name'],
      baseScore: json['base_score'],
      score: json['score'] != null ? json['score'].toDouble() : 0.0,
      position: Position.fromString(json['position']),
      matchesPlayed: json['matches_played'],
      matches: json['matches'] as List,
      createdAt: DateTime.tryParse(json['created_at']) ?? DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['matches'] = matches;
    return data;
  }
} 