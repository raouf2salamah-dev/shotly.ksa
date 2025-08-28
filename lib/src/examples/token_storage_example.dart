import 'package:flutter/material.dart';
import '../services/token_service.dart';

/// Example demonstrating how to use TokenService for managing access and refresh tokens
class TokenStorageExample extends StatefulWidget {
  const TokenStorageExample({Key? key}) : super(key: key);

  @override
  State<TokenStorageExample> createState() => _TokenStorageExampleState();
}

class _TokenStorageExampleState extends State<TokenStorageExample> {
  String _accessTokenStatus = 'Not checked';
  String _refreshTokenStatus = 'Not checked';
  final TextEditingController _accessTokenController = TextEditingController();
  final TextEditingController _refreshTokenController = TextEditingController();

  @override
  void dispose() {
    _accessTokenController.dispose();
    _refreshTokenController.dispose();
    super.dispose();
  }

  // Store tokens with default expiration times
  Future<void> _storeTokens() async {
    final accessToken = _accessTokenController.text;
    final refreshToken = _refreshTokenController.text;

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both tokens')),
      );
      return;
    }

    // Store tokens with default expiration times
    await TokenService.storeAccessToken(accessToken);
    await TokenService.storeRefreshToken(refreshToken);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tokens stored successfully')),
    );

    // Update status
    _checkTokenStatus();
  }

  // Check token status and remaining time
  Future<void> _checkTokenStatus() async {
    // Check access token
    final hasAccessToken = await TokenService.hasValidAccessToken();
    final accessTokenRemaining = await TokenService.getAccessTokenTimeRemaining();
    
    // Check refresh token
    final hasRefreshToken = await TokenService.hasValidRefreshToken();
    final refreshTokenRemaining = await TokenService.getRefreshTokenTimeRemaining();

    setState(() {
      _accessTokenStatus = hasAccessToken 
          ? 'Valid (${_formatDuration(accessTokenRemaining)})'
          : 'Invalid or expired';
      
      _refreshTokenStatus = hasRefreshToken 
          ? 'Valid (${_formatDuration(refreshTokenRemaining)})'
          : 'Invalid or expired';
    });
  }

  // Clear all tokens
  Future<void> _clearTokens() async {
    await TokenService.clearTokens();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All tokens cleared')),
    );
    
    // Update status
    _checkTokenStatus();
  }

  // Format duration for display
  String _formatDuration(Duration? duration) {
    if (duration == null) return 'unknown';
    
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Token Storage Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Token input fields
            TextField(
              controller: _accessTokenController,
              decoration: const InputDecoration(
                labelText: 'Access Token',
                hintText: 'Enter access token',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _refreshTokenController,
              decoration: const InputDecoration(
                labelText: 'Refresh Token',
                hintText: 'Enter refresh token',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _storeTokens,
                    child: const Text('Store Tokens'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _checkTokenStatus,
                    child: const Text('Check Status'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearTokens,
                    child: const Text('Clear Tokens'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Token status
            const Text(
              'Token Status:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Access Token: $_accessTokenStatus'),
                    const SizedBox(height: 8),
                    Text('Refresh Token: $_refreshTokenStatus'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Usage instructions
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to use TokenService:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('1. Store tokens after successful authentication'),
                    Text('2. Check token validity before making API requests'),
                    Text('3. Use refresh token to get new access token when expired'),
                    Text('4. Clear tokens on logout'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}