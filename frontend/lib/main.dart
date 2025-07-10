import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'config/app_config.dart';
import 'pages/auth_page.dart';

//flutter build apk --release
//flutter install 
//flutter build apk --debug

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize app configuration
  await AppConfig.initialize();
  
  runApp(const ProviderScope(child: MyApp()));
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
