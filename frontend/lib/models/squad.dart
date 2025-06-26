import 'player.dart';
import 'match.dart';

class Squad {
  final String squadId;
  final String name;
  final DateTime createdAt;
  final int playersCount;
  final String ownerId;

  Squad({
    required this.squadId,
    required this.name,
    required this.createdAt,
    required this.playersCount,
    required this.ownerId,
  });

  factory Squad.fromJson(Map<String, dynamic> json) {
    return Squad(
      squadId: json['squad_id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      playersCount: json['players_count'],
      ownerId: json['owner_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'squad_id': squadId,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'players_count': playersCount,
      'owner_id': ownerId,
    };
  }
}

class SquadCreate {
  final String name;

  SquadCreate({required this.name});

  factory SquadCreate.fromJson(Map<String, dynamic> json) {
    return SquadCreate(name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}

class SquadUpdate {
  final String name;

  SquadUpdate({required this.name});

  factory SquadUpdate.fromJson(Map<String, dynamic> json) {
    return SquadUpdate(name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}

class SquadListResponse {
  final List<Squad> squads;

  SquadListResponse({required this.squads});

  factory SquadListResponse.fromJson(Map<String, dynamic> json) {
    return SquadListResponse(
      squads: (json['squads'] as List)
          .map((squadJson) => Squad.fromJson(squadJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'squads': squads.map((squad) => squad.toJson()).toList(),
    };
  }
}

class SquadDetailResponse extends Squad {
  final List<Player> players;
  final List<Match> matches;

  SquadDetailResponse({
    required super.squadId,
    required super.name,
    required super.createdAt,
    required super.playersCount,
    required super.ownerId,
    required this.players,
    required this.matches,
  });

  factory SquadDetailResponse.fromJson(Map<String, dynamic> json) {
    return SquadDetailResponse(
      squadId: json['squad_id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      playersCount: json['players_count'],
      ownerId: json['owner_id'],
      players: (json['players'] as List)
          .map((playerJson) => Player.fromJson(playerJson))
          .toList(),
      matches: (json['matches'] as List)
          .map((matchJson) => Match.fromJson(matchJson))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['players'] = players.map((player) => player.toJson()).toList();
    data['matches'] = matches.map((match) => match.toJson()).toList();
    return data;
  }
}

