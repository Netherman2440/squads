import 'dart:convert';
import 'package:frontend/models/user.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'squad_service.dart';
import 'match_service.dart';
import 'player_service.dart';

class AuthService {
  static AuthService? _instance;
  static String? _token;
  
  final http.Client _client = http.Client();

  AuthService._();

  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  String get _apiUrl => AppConfig.apiUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Login user
  Future<AuthResponse> login(String username, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$_apiUrl/auth/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['access_token'];
        
        // Update tokens in all services
        _updateAllServiceTokens(_token);
        
        return AuthResponse.fromJson(data);
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Login failed: $e' + stackTrace.toString());
      throw Exception('Login failed: $e');
    }
  }

  // Register user
  Future<Map<String, dynamic>> register(String username, String password, String name) async {
    try {
      final response = await _client.post(
        Uri.parse('$_apiUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['access_token'];
        
        // Update tokens in all services
        _updateAllServiceTokens(_token);
        
        return data;
      } else {
        throw Exception('Registration failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<AuthResponse> guest() async {
    try {
      final response = await _client.post(
        Uri.parse('$_apiUrl/auth/guest'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['access_token'];
        
        // Update tokens in all services
        _updateAllServiceTokens(_token);

        return AuthResponse.fromJson(data);
      } else {
        throw Exception('Guest login failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Guest login failed: $e');
    }
  }

  // Logout user
  void logout() {
    _token = null;
    
    // Clear tokens in all services
    _updateAllServiceTokens(null);
  }

  // Get current token
  String? get token => _token;

  // Check if user is logged in
  bool get isLoggedIn => _token != null;

  // Update token (useful for token refresh)
  void updateToken(String? newToken) {
    _token = newToken;
    _updateAllServiceTokens(_token);
  }

  // Private method to update tokens in all services
  void _updateAllServiceTokens(String? token) {
    SquadService.setToken(token);
    MatchService.setToken(token);
    PlayerService.setToken(token);
  }
}