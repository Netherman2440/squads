import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String _envFile = '.env.prod';
  
  // API Configuration
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  static String get apiVersion => dotenv.env['API_VERSION'] ?? 'v1';
  static String get apiUrl => '$apiBaseUrl/api/$apiVersion';
  
  // App Configuration
  static String get appName =>  'Squads App';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  
  // Environment flags
  static bool get isDebug => dotenv.env['IS_DEBUG'] == 'true';
  
  // Initialize configuration
  static Future<void> initialize() async {
    await dotenv.load(fileName: _envFile);
  }
} 