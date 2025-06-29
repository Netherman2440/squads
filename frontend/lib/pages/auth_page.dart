import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/message_service.dart';
import '../state/user_state.dart';
import '../models/models.dart';
import 'squad_list_page.dart';

class AuthPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final AuthService _authService = AuthService.instance;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final authResponse = await _authService.login(
          _usernameController.text,
          _passwordController.text,
        );
        
        // Update user state
        ref.read(userSessionProvider.notifier).setToken(authResponse.accessToken);
        if (authResponse.user != null) {
          ref.read(userSessionProvider.notifier).setUser(authResponse.user!);
        }
        
        // Show success message
        MessageService.showSuccess(context, 'Login successful!');
        
        // Navigate to squad list page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SquadListPage()),
        );
        
      } catch (e) {
        MessageService.showError(context, e.toString().replaceAll('Exception: ', ''));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleGuestLogin() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authResponse = await _authService.guest();
      
      // Update user state
      ref.read(userSessionProvider.notifier).setToken(authResponse.accessToken);
      if (authResponse.user != null) {
        ref.read(userSessionProvider.notifier).setUser(authResponse.user!);
      }
      
      // Show success message
      MessageService.showSuccess(context, 'Welcome as guest!');
      
      // Navigate to squad list page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SquadListPage()),
      );
      
    } catch (e) {
      MessageService.showError(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_soccer,
                size: 100,
                color: Colors.blue,
              ),
              SizedBox(height: 20),
              Text(
                'Squads App',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 40),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter username';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Login'),
                ),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading ? null : _handleGuestLogin,
                child: Text(
                  'Continue as Guest',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600]!,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


