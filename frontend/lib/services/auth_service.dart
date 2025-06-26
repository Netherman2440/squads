import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class AuthService {
  static const String _baseUrl = 'http://localhost:8000'; // FastAPI default port
  static const String _apiPath = '/api/v1/auth';

  // Login with email and password
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_apiPath/login'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'username': email, // FastAPI OAuth2 uses 'username' field
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return AuthResponse.fromJson(jsonData);
      } else {
        throw Exception('Login failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error during login: $e');
    }
  }

  // Register new user
  Future<AuthResponse> register(String email, String password) async {
    try {
      final userData = UserRegister(email: email, password: password);
      
      final response = await http.post(
        Uri.parse('$_baseUrl$_apiPath/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(userData.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return AuthResponse.fromJson(jsonData);
      } else {
        throw Exception('Registration failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error during registration: $e');
    }
  }

  // Get guest token for anonymous access
  Future<AuthResponse> getGuestToken() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_apiPath/guest'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return AuthResponse.fromJson(jsonData);
      } else {
        throw Exception('Guest token request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error during guest token request: $e');
    }
  }

  // Validate token (optional helper method)
  bool isTokenValid(String token) {
    if (token.isEmpty) return false;
    
    // Basic validation - you might want to add JWT expiration check
    return token.startsWith('eyJ') && token.length > 50;
  }

  // Logout (client-side only since backend doesn't have logout endpoint)
  void logout() {
    // Clear stored token and user data
    // This would typically involve clearing SharedPreferences or similar
  }
}