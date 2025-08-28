import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';
import '../services/token_service.dart';

/// Example screen demonstrating AuthApiService with TokenService
class AuthApiExample extends StatefulWidget {
  const AuthApiExample({Key? key}) : super(key: key);

  @override
  State<AuthApiExample> createState() => _AuthApiExampleState();
}

class _AuthApiExampleState extends State<AuthApiExample> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoggedIn = false;
  String _accessTokenStatus = 'Not checked';
  String _refreshTokenStatus = 'Not checked';
  String _apiResponseStatus = 'Not requested';
  
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _checkLoginStatus() async {
    final hasAccessToken = await TokenService.hasValidAccessToken();
    final hasRefreshToken = await TokenService.hasValidRefreshToken();
    
    setState(() {
      _isLoggedIn = hasAccessToken || hasRefreshToken;
    });
    
    _updateTokenStatus();
  }
  
  Future<void> _updateTokenStatus() async {
    final accessToken = await TokenService.getAccessToken();
    final refreshToken = await TokenService.getRefreshToken();
    
    final accessTokenValid = await TokenService.hasValidAccessToken();
    final refreshTokenValid = await TokenService.hasValidRefreshToken();
    
    final accessTokenRemaining = await TokenService.getAccessTokenTimeRemaining();
    final refreshTokenRemaining = await TokenService.getRefreshTokenTimeRemaining();
    
    setState(() {
      _accessTokenStatus = accessToken != null 
          ? 'Valid: $accessTokenValid, Remaining: ${_formatDuration(accessTokenRemaining)}' 
          : 'No access token';
      
      _refreshTokenStatus = refreshToken != null 
          ? 'Valid: $refreshTokenValid, Remaining: ${_formatDuration(refreshTokenRemaining)}' 
          : 'No refresh token';
    });
  }
  
  String _formatDuration(Duration? duration) {
    if (duration == null) return 'N/A';
    
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
  
  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username and password')),
      );
      return;
    }
    
    final success = await AuthApiService.login(
      _usernameController.text,
      _passwordController.text,
    );
    
    setState(() {
      _isLoggedIn = success;
      if (success) {
        _apiResponseStatus = 'Login successful';
      } else {
        _apiResponseStatus = 'Login failed';
      }
    });
    
    _updateTokenStatus();
  }
  
  Future<void> _logout() async {
    final success = await AuthApiService.logout();
    
    setState(() {
      _isLoggedIn = !success;
      _apiResponseStatus = success ? 'Logout successful' : 'Logout failed';
    });
    
    _updateTokenStatus();
  }
  
  Future<void> _refreshToken() async {
    final success = await AuthApiService.refreshAccessToken();
    
    setState(() {
      _apiResponseStatus = success ? 'Token refresh successful' : 'Token refresh failed';
    });
    
    _updateTokenStatus();
  }
  
  Future<void> _makeApiRequest() async {
    final response = await AuthApiService.authenticatedRequest(
      'GET',
      '/api/user/profile',
    );
    
    setState(() {
      if (response != null) {
        _apiResponseStatus = 'API request successful: ${response.statusCode}';
      } else {
        _apiResponseStatus = 'API request failed';
      }
    });
    
    _updateTokenStatus();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth API Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isLoggedIn) ...[  
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _login,
                child: const Text('Login'),
              ),
            ] else ...[  
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Token Status', 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Access Token: $_accessTokenStatus'),
                      const SizedBox(height: 4),
                      Text('Refresh Token: $_refreshTokenStatus'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _refreshToken,
                      child: const Text('Refresh Token'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _makeApiRequest,
                      child: const Text('Make API Request'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout'),
              ),
            ],
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('API Response', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_apiResponseStatus),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateTokenStatus,
              child: const Text('Refresh Status'),
            ),
          ],
        ),
      ),
    );
  }
}