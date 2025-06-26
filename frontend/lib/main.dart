import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'config/app_config.dart';
import 'pages/auth_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize app configuration
  await AppConfig.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: AppTheme.darkTheme,
      home: AuthPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
