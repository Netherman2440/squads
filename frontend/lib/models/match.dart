import 'player.dart';

class Match {
  final String matchId;
  final String squadId;
  final DateTime createdAt;
  final List<int>? score;

  Match({
    required this.matchId,
    required this.squadId,
    required this.createdAt,
    this.score,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      matchId: json['match_id'],
      squadId: json['squad_id'],
      createdAt: DateTime.parse(json['created_at']),
      score: json['score'] != null ? List<int>.from(json['score']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'match_id': matchId,
      'squad_id': squadId,
      'created_at': createdAt.toIso8601String(),
      'score': score,
    };
  }
}

class MatchCreate {
  final List<String> teamA;
  final List<String> teamB;

  MatchCreate({
    required this.teamA,
    required this.teamB,
  });

  factory MatchCreate.fromJson(Map<String, dynamic> json) {
    return MatchCreate(
      teamA: List<String>.from(json['team_a']),
      teamB: List<String>.from(json['team_b']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team_a': teamA,
      'team_b': teamB,
    };
  }
}

class TeamUpdate {
  final String teamId;
  final List<String>? players;
  final int? score;

  TeamUpdate({
    required this.teamId,
    this.players,
    this.score,
  });

  factory TeamUpdate.fromJson(Map<String, dynamic> json) {
    return TeamUpdate(
      teamId: json['team_id'],
      players: json['players'] != null ? List<String>.from(json['players']) : null,
      score: json['score'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'team_id': teamId,
    };
    if (players != null) data['players'] = players;
    if (score != null) data['score'] = score;
    return data;
  }
}

class MatchUpdate {
  final TeamUpdate teamA;
  final TeamUpdate teamB;

  MatchUpdate({
    required this.teamA,
    required this.teamB,
  });

  factory MatchUpdate.fromJson(Map<String, dynamic> json) {
    return MatchUpdate(
      teamA: TeamUpdate.fromJson(json['team_a']),
      teamB: TeamUpdate.fromJson(json['team_b']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team_a': teamA.toJson(),
      'team_b': teamB.toJson(),
    };
  }
}

class MatchListResponse {
  final List<Match> matches;

  MatchListResponse({required this.matches});

  factory MatchListResponse.fromJson(Map<String, dynamic> json) {
    return MatchListResponse(
      matches: (json['matches'] as List)
          .map((matchJson) => Match.fromJson(matchJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matches': matches.map((match) => match.toJson()).toList(),
    };
  }
}

class TeamDetailData {
  final String squadId;
  final String matchId;
  final String teamId;
  final int? score;
  final String? name;
  final String? color;
  final int playersCount;
  final List<Player> players;

  TeamDetailData({
    required this.squadId,
    required this.matchId,
    required this.teamId,
    required this.score,
    required this.name,
    required this.color,
    required this.playersCount,
    required this.players,
  });

  factory TeamDetailData.fromJson(Map<String, dynamic> json) {
    return TeamDetailData(
      squadId: json['squad_id'],
      matchId: json['match_id'],
      teamId: json['team_id'],
      score: json['score'],
      name: json['name'],
      color: json['color'],
      playersCount: json['players_count'],
      players: (json['players'] as List)
          .map((playerJson) => Player.fromJson(playerJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'squad_id': squadId,
      'match_id': matchId,
      'team_id': teamId,
      'score': score,
      'name': name,
      'color': color,
      'players_count': playersCount,
      'players': players.map((player) => player.toJson()).toList(),
    };
  }
}

class MatchDetailResponse {
  final String squadId;
  final String matchId;
  final DateTime createdAt;
  final TeamDetailData teamA;
  final TeamDetailData teamB;

  MatchDetailResponse({
    required this.squadId,
    required this.matchId,
    required this.createdAt,
    required this.teamA,
    required this.teamB,
  });

  factory MatchDetailResponse.fromJson(Map<String, dynamic> json) {
    return MatchDetailResponse(
      squadId: json['squad_id'],
      matchId: json['match_id'],
      createdAt: DateTime.parse(json['created_at']),
      teamA: TeamDetailData.fromJson(json['team_a']),
      teamB: TeamDetailData.fromJson(json['team_b']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'squad_id': squadId,
      'match_id': matchId,
      'created_at': createdAt.toIso8601String(),
      'team_a': teamA.toJson(),
      'team_b': teamB.toJson(),
    };
  }
} 