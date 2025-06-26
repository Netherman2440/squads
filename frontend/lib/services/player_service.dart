import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player.dart';
import '../models/position.dart';
import '../state/user_state.dart';
import '../config/app_config.dart';

class PlayerService {
  final http.Client _client;
  final Ref _ref;

  PlayerService(this._client, this._ref);

  String? get _token => _ref.read(userSessionProvider).token;
  String get _baseUrl => AppConfig.apiBaseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Get player by ID - returns PlayerDetailResponse
  Future<PlayerDetailResponse> getPlayer(String squadId, String playerId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/squads/$squadId/players/$playerId'),
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
        Uri.parse('$_baseUrl/squads/$squadId/players/$playerId'),
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
        Uri.parse('$_baseUrl/squads/$squadId/players/$playerId'),
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
        Uri.parse('$_baseUrl/squads/$squadId/players/$playerId'),
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
        Uri.parse('$_baseUrl/squads/$squadId/players/$playerId'),
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
        Uri.parse('$_baseUrl/players/$playerId/score-history'),
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
}

// Provider for PlayerService
final playerServiceProvider = Provider<PlayerService>((ref) {
  return PlayerService(http.Client(), ref);
}); 