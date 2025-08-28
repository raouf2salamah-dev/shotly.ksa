import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// Example class demonstrating the usage of the Logger utility
class LoggerExample extends StatefulWidget {
  const LoggerExample({Key? key}) : super(key: key);

  @override
  State<LoggerExample> createState() => _LoggerExampleState();
}

class _LoggerExampleState extends State<LoggerExample> {
  // Create a logger instance with a tag
  final Logger _logger = Logger('LoggerExample');
  
  // Text controllers for input fields
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cardController = TextEditingController();
  
  // Selected log level
  LogLevel _selectedLevel = LogLevel.info;
  
  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cardController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logger Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Log level selector
            const Text(
              'Select Log Level:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<LogLevel>(
              value: _selectedLevel,
              onChanged: (LogLevel? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLevel = newValue;
                  });
                }
              },
              items: LogLevel.values.map<DropdownMenuItem<LogLevel>>((LogLevel level) {
                return DropdownMenuItem<LogLevel>(
                  value: level,
                  child: Text(level.toString().split('.').last.toUpperCase()),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            // Regular logging section
            const Text(
              'Regular Logging:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter message to log',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _logMessage,
              child: const Text('Log Message'),
            ),
            const SizedBox(height: 16),
            
            // Sensitive data logging section
            const Text(
              'Sensitive Data Logging:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Email address',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Phone number',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _cardController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Credit card number',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _logSensitiveData,
              child: const Text('Log With Sensitive Data'),
            ),
            const SizedBox(height: 16),
            
            // Log level demo buttons
            const Text(
              'Log Level Demo:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _logger.d('This is a debug message'),
                  child: const Text('Debug'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                ),
                ElevatedButton(
                  onPressed: () => _logger.i('This is an info message'),
                  child: const Text('Info'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                ElevatedButton(
                  onPressed: () => _logger.w('This is a warning message'),
                  child: const Text('Warning'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
                ElevatedButton(
                  onPressed: () => _logger.e('This is an error message', 
                      error: Exception('Test error'), 
                      stackTrace: StackTrace.current),
                  child: const Text('Error'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                ElevatedButton(
                  onPressed: () => _logger.c('This is a critical message', 
                      error: Exception('Critical test error'), 
                      stackTrace: StackTrace.current),
                  child: const Text('Critical'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Min log level setting
            const Text(
              'Set Minimum Log Level:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: LogLevel.values.map((level) {
                return ElevatedButton(
                  onPressed: () {
                    Logger.setMinLogLevel(level);
                    _logger.i('Set minimum log level to ${level.toString().split('.').last.toUpperCase()}');
                  },
                  child: Text(level.toString().split('.').last.toUpperCase()),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Log a regular message with the selected level
  void _logMessage() {
    final message = _messageController.text;
    if (message.isEmpty) return;
    
    switch (_selectedLevel) {
      case LogLevel.debug:
        _logger.d(message);
        break;
      case LogLevel.info:
        _logger.i(message);
        break;
      case LogLevel.warning:
        _logger.w(message);
        break;
      case LogLevel.error:
        _logger.e(message, error: 'Sample error', stackTrace: StackTrace.current);
        break;
      case LogLevel.critical:
        _logger.c(message, error: 'Sample critical error', stackTrace: StackTrace.current);
        break;
    }
    
    _messageController.clear();
  }
  
  /// Log a message containing sensitive data
  void _logSensitiveData() {
    final email = _emailController.text;
    final phone = _phoneController.text;
    final card = _cardController.text;
    
    if (email.isEmpty && phone.isEmpty && card.isEmpty) return;
    
    // Create a message that includes the sensitive data
    final message = 'User data - Email: $email, Phone: $phone, Card: $card';
    
    // Log with sensitive data redaction
    _logger.logSensitive(
      _selectedLevel,
      message,
      sensitiveData: {
        'email': email,
        'phone': phone,
        'card': card,
      },
    );
    
    // Clear the input fields
    _emailController.clear();
    _phoneController.clear();
    _cardController.clear();
  }
}