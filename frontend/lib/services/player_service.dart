import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/player.dart';
import '../models/position.dart';
import '../config/app_config.dart';

class PlayerService {
  static PlayerService? _instance;
  static String? _token;
  
  final http.Client _client = http.Client();

  PlayerService._();

  static PlayerService get instance {
    _instance ??= PlayerService._();
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

  // Get player by ID - returns PlayerDetailResponse
  Future<PlayerDetailResponse> getPlayer(String squadId, String playerId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_apiUrl/squads/$squadId/players/$playerId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PlayerDetailResponse.fromJson(data);
      } else {
        throw Exception('Failed to load player: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load player: $e');
    }
  }

  // Update player name - returns PlayerDetailResponse
  Future<PlayerDetailResponse> updatePlayerName(String squadId, String playerId, String name) async {
    try {
      final response = await _client.put(
        Uri.parse('$_apiUrl/squads/$squadId/players/$playerId'),
        headers: _headers,
        body: json.encode({'name': name}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PlayerDetailResponse.fromJson(data);
      } else {
        throw Exception('Failed to update player name: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update player name: $e');
    }
  }

  // Update player base score - returns PlayerDetailResponse
  Future<PlayerDetailResponse> updatePlayerBaseScore(String squadId, String playerId, int baseScore) async {
    try {
      final response = await _client.put(
        Uri.parse('$_apiUrl/squads/$squadId/players/$playerId'),
        headers: _headers,
        body: json.encode({'base_score': baseScore}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PlayerDetailResponse.fromJson(data);
      } else {
        throw Exception('Failed to update player base score: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update player base score: $e');
    }
  }

  // Update player position - returns PlayerDetailResponse
  Future<PlayerDetailResponse> updatePlayerPosition(String squadId, String playerId, Position position) async {
    try {
      final response = await _client.put(
        Uri.parse('$_apiUrl/squads/$squadId/players/$playerId'),
        headers: _headers,
        body: json.encode({'position': position.name}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PlayerDetailResponse.fromJson(data);
      } else {
        throw Exception('Failed to update player position: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update player position: $e');
    }
  }

  // Delete player
  Future<void> deletePlayer(String squadId, String playerId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$_apiUrl/squads/$squadId/players/$playerId'),
        headers: _headers,
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete player: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete player: $e');
    }
  }

  // Get player score history
  Future<List<Map<String, dynamic>>> getPlayerScoreHistory(String playerId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_apiUrl/players/$playerId/score-history'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['score_history']);
      } else {
        throw Exception('Failed to load player score history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load player score history: $e');
    }
  }

  // Get players from squad
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

  // Create new player
  Future<Player> createPlayer(String squadId, PlayerCreate playerCreate) async {
    try {
      final response = await _client.post(
        Uri.parse('$_apiUrl/squads/$squadId/players'),
        headers: _headers,
        body: json.encode(playerCreate.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Player.fromJson(data);
      } else {
        throw Exception('Failed to create player: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create player: $e');
    }
  }
} 