import 'player.dart';

class Draft {
  final String draftId;
  final String squadId;
  final DateTime createdAt;
  final List<Player> teamA;
  final List<Player> teamB;
  final double teamAScore;
  final double teamBScore;

  Draft({
    required this.draftId,
    required this.squadId,
    required this.createdAt,
    required this.teamA,
    required this.teamB,
    required this.teamAScore,
    required this.teamBScore,
  });

  factory Draft.fromJson(Map<String, dynamic> json) {
    return Draft(
      draftId: json['draft_id'],
      squadId: json['squad_id'],
      createdAt: DateTime.parse(json['created_at']),
      teamA: (json['team_a'] as List)
          .map((playerJson) => Player.fromJson(playerJson))
          .toList(),
      teamB: (json['team_b'] as List)
          .map((playerJson) => Player.fromJson(playerJson))
          .toList(),
      teamAScore: json['team_a_score'].toDouble(),
      teamBScore: json['team_b_score'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'draft_id': draftId,
      'squad_id': squadId,
      'created_at': createdAt.toIso8601String(),
      'team_a': teamA.map((player) => player.toJson()).toList(),
      'team_b': teamB.map((player) => player.toJson()).toList(),
      'team_a_score': teamAScore,
      'team_b_score': teamBScore,
    };
  }
}

class DraftCreate {
  final int teamSize;
  final bool balanceTeams;

  DraftCreate({
    required this.teamSize,
    required this.balanceTeams,
  });

  factory DraftCreate.fromJson(Map<String, dynamic> json) {
    return DraftCreate(
      teamSize: json['team_size'],
      balanceTeams: json['balance_teams'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team_size': teamSize,
      'balance_teams': balanceTeams,
    };
  }
}

class DraftListResponse {
  final List<Draft> drafts;

  DraftListResponse({required this.drafts});

  factory DraftListResponse.fromJson(Map<String, dynamic> json) {
    return DraftListResponse(
      drafts: (json['drafts'] as List)
          .map((draftJson) => Draft.fromJson(draftJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'drafts': drafts.map((draft) => draft.toJson()).toList(),
    };
  }
} 