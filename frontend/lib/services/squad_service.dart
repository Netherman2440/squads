import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/squad.dart';
import '../models/player.dart';
import '../models/match.dart';
import '../models/position.dart';
import '../state/user_state.dart';
import '../config/app_config.dart';

class SquadService {
  static SquadService? _instance;
  static String? _token;
  
  final http.Client _client = http.Client();
  
  SquadService._();

  static SquadService get instance {
    _instance ??= SquadService._();
    return _instance!;
  }

  static void setToken(String? token) {
    _token = token;
  }

  String get _apiUrl => AppConfig.apiUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Get all squads
  Future<List<Squad>> getAllSquads() async {
    try {
      final response = await _client.get(
        Uri.parse('$_apiUrl/squads'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final squadsList = data['squads'] as List;
        return squadsList.map((json) => Squad.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load squads: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load squads: $e');
    }
  }

  // Create a new squad - returns SquadDetailResponse
  Future<SquadDetailResponse> createSquad(String name) async {
    try {
      final response = await _client.post(
        Uri.parse('$_apiUrl/squads'),
        headers: _headers,
        body: json.encode({'name': name}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SquadDetailResponse.fromJson(data);
      } else {
        throw Exception('Failed to create squad: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create squad: $e');
    }
  }

  // Get squad by ID - returns SquadDetailResponse
  Future<SquadDetailResponse> getSquad(String squadId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_apiUrl/squads/$squadId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SquadDetailResponse.fromJson(data);
      } else {
        throw Exception('Failed to load squad: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load squad: $e');
    }
  }

  // Delete squad
  Future<void> deleteSquad(String squadId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$_apiUrl/squads/$squadId'),
        headers: _headers,
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete squad: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete squad: $e');
    }
  }

  // Get players in a squad
  Future<List<Player>> getPlayers(String squadId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_apiUrl/squads/$squadId/players'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final playersList = data['players'] as List;
        return playersList.map((json) => Player.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load players: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load players: $e');
    }
  }

  // Add player to squad - returns PlayerDetailResponse
  Future<PlayerDetailResponse> addPlayer(String squadId, String name, int baseScore, Position position) async {
    try {
      final response = await _client.post(
        Uri.parse('$_apiUrl/squads/$squadId/players'),
        headers: _headers,
        body: json.encode({
          'name': name,
          'base_score': baseScore,
          'position': position.name,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PlayerDetailResponse.fromJson(data);
      } else {
        throw Exception('Failed to add player: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to add player: $e');
    }
  }

  // Get matches in a squad
  Future<List<Match>> getMatches(String squadId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_apiUrl/squads/$squadId/matches'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final matchesList = data['matches'] as List;
        return matchesList.map((json) => Match.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load matches: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load matches: $e');
    }
  }

  // Create match in a squad - returns MatchDetailResponse
  Future<MatchDetailResponse> createMatch(String squadId, List<Player> teamAPlayers, List<Player> teamBPlayers) async {
    try {
      final response = await _client.post(
        Uri.parse('$_apiUrl/squads/$squadId/matches'),
        headers: _headers,
        body: json.encode({
          'team_a': teamAPlayers.map((p) => p.toJson()).toList(),
          'team_b': teamBPlayers.map((p) => p.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MatchDetailResponse.fromJson(data);
      } else {
        throw Exception('Failed to create match: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create match: $e');
    }
  }
}