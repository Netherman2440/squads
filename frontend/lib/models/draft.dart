import 'player.dart';

class Draft {

  final List<Player> teamA;
  final List<Player> teamB;


  Draft({

    required this.teamA,
    required this.teamB,
  });

  factory Draft.fromJson(Map<String, dynamic> json) {
    return Draft(
      teamA: (json['team_a'] as List)
          .map((playerJson) => Player.fromJson(playerJson))
          .toList(),
      teamB: (json['team_b'] as List)
          .map((playerJson) => Player.fromJson(playerJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team_a': teamA.map((player) => player.toJson()).toList(),
      'team_b': teamB.map((player) => player.toJson()).toList(),
    };
  }
}

class DraftCreate {
  final List<String> players_ids;

  DraftCreate({
    required this.players_ids,
  });

  factory DraftCreate.fromJson(Map<String, dynamic> json) {
    return DraftCreate(
      players_ids: (json['players_ids'] as List)
          .map((playerJson) => playerJson.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'players_ids': players_ids,
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