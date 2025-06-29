import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match.dart';
import '../models/player.dart';
import '../models/draft.dart';
import '../state/user_state.dart';
import '../config/app_config.dart';

class MatchService {
  static MatchService? _instance;
  static String? _token;
  
  final http.Client _client = http.Client();
  static final String _baseUrl = AppConfig.apiBaseUrl;

  MatchService._();

  static MatchService get instance {
    _instance ??= MatchService._();
    return _instance!;
  }

  static void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Get match by ID - returns MatchDetailResponse
  Future<MatchDetailResponse> getMatch(String squadId, String matchId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/squads/$squadId/matches/$matchId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MatchDetailResponse.fromJson(data);
      } else {
        throw Exception('Failed to load match: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load match: $e');
    }
  }

  // Update match - returns MatchDetailResponse
  Future<MatchDetailResponse> updateMatch(String squadId, String matchId, {
    List<Player>? teamAPlayers,
    List<Player>? teamBPlayers,
    List<int>? score,
  }) async {
    try {
      final body = <String, dynamic>{};
      
      if (teamAPlayers != null) {
        body['team_a'] = teamAPlayers.map((p) => p.toJson()).toList();
      }
      if (teamBPlayers != null) {
        body['team_b'] = teamBPlayers.map((p) => p.toJson()).toList();
      }
      if (score != null) {
        body['score'] = score;
      }

      final response = await _client.put(
        Uri.parse('$_baseUrl/squads/$squadId/matches/$matchId'),
        headers: _headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MatchDetailResponse.fromJson(data);
      } else {
        throw Exception('Failed to update match: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update match: $e');
    }
  }

  // Delete match
  Future<void> deleteMatch(String squadId, String matchId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$_baseUrl/squads/$squadId/matches/$matchId'),
        headers: _headers,
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete match: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete match: $e');
    }
  }

  // Draw teams for a match
  Future<List<Draft>> drawTeams(String squadId, List<Player> players) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/squads/$squadId/matches/draw'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final draftsList = data['drafts'] as List;
        return draftsList.map((json) => Draft.fromJson(json)).toList();
      } else {
        throw Exception('Failed to draw teams: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to draw teams: $e');
    }
  }

  // Update match score - returns MatchDetailResponse
  Future<MatchDetailResponse> updateMatchScore(String squadId, String matchId, int teamAScore, int teamBScore) async {
    return updateMatch(squadId, matchId, score: [teamAScore, teamBScore]);
  }

  // Update match players - returns MatchDetailResponse
  Future<MatchDetailResponse> updateMatchPlayers(String squadId, String matchId, List<Player> teamAPlayers, List<Player> teamBPlayers) async {
    return updateMatch(squadId, matchId, teamAPlayers: teamAPlayers, teamBPlayers: teamBPlayers);
  }

  // Get match statistics
  Future<Map<String, dynamic>> getMatchStatistics(String squadId, String matchId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/squads/$squadId/matches/$matchId/statistics'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception('Failed to load match statistics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load match statistics: $e');
    }
  }

  // Get match history for a player
  Future<List<Match>> getPlayerMatchHistory(String playerId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/players/$playerId/matches'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final matchesList = data['matches'] as List;
        return matchesList.map((json) => Match.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load player match history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load player match history: $e');
    }
  }

  // Get matches for a squad
  Future<List<Match>> getSquadMatches(String squadId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/squads/$squadId/matches'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final matchesList = data['matches'] as List;
        return matchesList.map((json) => Match.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load squad matches: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load squad matches: $e');
    }
  }
}

