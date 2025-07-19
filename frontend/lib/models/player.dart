import 'position.dart';
import 'carousel_type.dart';

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

class PlayerRef {
  final String playerId;
  final String playerName;

  PlayerRef({
    required this.playerId,
    required this.playerName,
  });

  factory PlayerRef.fromJson(Map<String, dynamic> json) {
    return PlayerRef(
      playerId: json['playerId'],
      playerName: json['playerName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'playerName': playerName,
    };
  }
}

class MatchRef {
  final String matchId;
  final DateTime matchDate;
  final List<int>? score; // tuple[int, int] -> List<int>

  MatchRef({
    required this.matchId,
    required this.matchDate,
    this.score,
  });

  factory MatchRef.fromJson(Map<String, dynamic> json) {
    return MatchRef(
      matchId: json['matchId'],
      matchDate: DateTime.parse(json['matchDate']),
      score: json['score'] != null ? List<int>.from(json['score']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'matchDate': matchDate.toIso8601String(),
      if (score != null) 'score': score,
    };
  }
}

class ScoreHistory {
  final double score;
  final DateTime createdAt;
  final MatchRef? matchRef;

  ScoreHistory({
    required this.score,
    required this.createdAt,
    this.matchRef,
  });

  factory ScoreHistory.fromJson(Map<String, dynamic> json) {
    return ScoreHistory(
      score: json['score'],
      createdAt: DateTime.parse(json['created_at']),
      matchRef: json['match_ref'] != null 
          ? MatchRef.fromJson(json['match_ref']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'created_at': createdAt.toIso8601String(),
      if (matchRef != null) 'match_ref': matchRef!.toJson(),
    };
  }
}

class CarouselStat {
  final String type; // CarouselType
  final dynamic value; // Can be string, list of strings, or dict
  final dynamic ref; // Can be PlayerRef or MatchRef

  CarouselStat({
    required this.type,
    required this.value,
    this.ref,
  });

  factory CarouselStat.fromJson(Map<String, dynamic> json) {
    dynamic parsedRef;
    if (json['ref'] != null) {
      // Try to determine if it's PlayerRef or MatchRef based on keys
      if (json['ref']['playerId'] != null) {
        parsedRef = PlayerRef.fromJson(json['ref']);
      } else if (json['ref']['matchId'] != null) {
        parsedRef = MatchRef.fromJson(json['ref']);
      }
    }

    return CarouselStat(
      type: json['type'],
      value: json['value'],
      ref: parsedRef,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
      if (ref != null) 'ref': ref is PlayerRef || ref is MatchRef ? ref.toJson() : ref,
    };
  }
}

class PlayerStats {
  final String playerId;
  final int baseScore;
  final double score;
  final int winStreak;
  final int lossStreak;
  final int biggestWinStreak;
  final int biggestLossStreak;
  final int goalsScored;
  final int goalsConceded;
  final double avgGoalsPerMatch;
  final List<double> avgScore; // tuple[float, float] -> List<double>
  final int totalMatches;
  final int totalWins;
  final int totalLosses;
  final int totalDraws;
  final List<ScoreHistory> scoreHistory;
  final List<CarouselStat> carouselStats;

  PlayerStats({
    required this.playerId,
    required this.baseScore,
    required this.score,
    required this.winStreak,
    required this.lossStreak,
    required this.biggestWinStreak,
    required this.biggestLossStreak,
    required this.goalsScored,
    required this.goalsConceded,
    required this.avgGoalsPerMatch,
    required this.avgScore,
    required this.totalMatches,
    required this.totalWins,
    required this.totalLosses,
    required this.totalDraws,
    required this.scoreHistory,
    required this.carouselStats,
  });

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      playerId: json['player_id'],
      baseScore: json['base_score'],
      score: json['score'] ,
      winStreak: json['win_streak'],
      lossStreak: json['loss_streak'],
      biggestWinStreak: json['biggest_win_streak'],
      biggestLossStreak: json['biggest_loss_streak'],
      goalsScored: json['goals_scored'],
      goalsConceded: json['goals_conceded'],
      avgGoalsPerMatch: json['avg_goals_per_match'].toDouble(),
      avgScore: List<double>.from(json['avg_score'].map((x) => x.toDouble())),
      totalMatches: json['total_matches'],
      totalWins: json['total_wins'],
      totalLosses: json['total_losses'],
      totalDraws: json['total_draws'],
      scoreHistory: (json['score_history'] as List)
          .map((x) => ScoreHistory.fromJson(x))
          .toList(),
      carouselStats: (json['carousel_stats'] as List)
          .map((x) => CarouselStat.fromJson(x))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'player_id': playerId,
      'base_score': baseScore,
      'score': score,
      'win_streak': winStreak,
      'loss_streak': lossStreak,
      'biggest_win_streak': biggestWinStreak,
      'biggest_loss_streak': biggestLossStreak,
      'goals_scored': goalsScored,
      'goals_conceded': goalsConceded,
      'avg_goals_per_match': avgGoalsPerMatch,
      'avg_score': avgScore,
      'total_matches': totalMatches,
      'total_wins': totalWins,
      'total_losses': totalLosses,
      'total_draws': totalDraws,
      'score_history': scoreHistory.map((x) => x.toJson()).toList(),
      'carousel_stats': carouselStats.map((x) => x.toJson()).toList(),
    };
  }
}

class PlayerDetailResponse extends Player {
  final PlayerStats stats;

  PlayerDetailResponse({
    required super.playerId,
    required super.squadId,
    required super.name,
    required super.baseScore,
    required super.score,
    required super.position,
    required super.matchesPlayed,
    required super.createdAt,
    required this.stats,
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
      createdAt: DateTime.tryParse(json['created_at']) ?? DateTime.now(),
      stats: PlayerStats.fromJson(json['stats']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['stats'] = stats.toJson();
    return data;
  }
} 