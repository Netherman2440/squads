import 'player.dart';

class Match {
  final String matchId;
  final String squadId;
  final DateTime createdAt;
  final List<int> score;

  Match({
    required this.matchId,
    required this.squadId,
    required this.createdAt,
    required this.score,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      matchId: json['match_id'],
      squadId: json['squad_id'],
      createdAt: DateTime.parse(json['created_at']),
      score: List<int>.from(json['score']),
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

class MatchUpdate {
  final List<String>? teamA;
  final List<String>? teamB;
  final List<int>? score;

  MatchUpdate({
    this.teamA,
    this.teamB,
    this.score,
  });

  factory MatchUpdate.fromJson(Map<String, dynamic> json) {
    return MatchUpdate(
      teamA: json['team_a'] != null ? List<String>.from(json['team_a']) : null,
      teamB: json['team_b'] != null ? List<String>.from(json['team_b']) : null,
      score: json['score'] != null ? List<int>.from(json['score']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (teamA != null) data['team_a'] = teamA;
    if (teamB != null) data['team_b'] = teamB;
    if (score != null) data['score'] = score;
    return data;
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
  final List<Player> players;
  final double totalScore;
  final int playerCount;

  TeamDetailData({
    required this.players,
    required this.totalScore,
    required this.playerCount,
  });

  factory TeamDetailData.fromJson(Map<String, dynamic> json) {
    return TeamDetailData(
      players: (json['players'] as List)
          .map((playerJson) => Player.fromJson(playerJson))
          .toList(),
      totalScore: json['total_score'].toDouble(),
      playerCount: json['player_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'players': players.map((player) => player.toJson()).toList(),
      'total_score': totalScore,
      'player_count': playerCount,
    };
  }
}

class MatchDetailResponse extends Match {
  final TeamDetailData teamA;
  final TeamDetailData teamB;

  MatchDetailResponse({
    required super.matchId,
    required super.squadId,
    required super.createdAt,
    required super.score,
    required this.teamA,
    required this.teamB,
  });

  factory MatchDetailResponse.fromJson(Map<String, dynamic> json) {
    return MatchDetailResponse(
      matchId: json['match_id'],
      squadId: json['squad_id'],
      createdAt: DateTime.parse(json['created_at']),
      score: List<int>.from(json['score']),
      teamA: TeamDetailData.fromJson(json['team_a']),
      teamB: TeamDetailData.fromJson(json['team_b']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['team_a'] = teamA.toJson();
    data['team_b'] = teamB.toJson();
    return data;
  }
} 