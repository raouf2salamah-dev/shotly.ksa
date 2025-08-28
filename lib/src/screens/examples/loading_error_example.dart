import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/loading_state.dart';
import '../../utils/network_utils.dart';
import '../../widgets/error_message.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/network_widget.dart';

/// A screen demonstrating the standardized loading and error handling components
class LoadingErrorExample extends StatefulWidget {
  const LoadingErrorExample({super.key});

  @override
  State<LoadingErrorExample> createState() => _LoadingErrorExampleState();
}

class _LoadingErrorExampleState extends State<LoadingErrorExample> {
  bool _isLoading = false;
  bool _isOverlayLoading = false;
  LoadingState<List<String>> _dataState = LoadingState.initial();
  final _random = math.Random();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loading & Error Handling'),
      ),
      body: LoadingOverlay(
        isLoading: _isOverlayLoading,
        loadingText: 'Loading overlay example...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                'LoadingIndicator',
                [
                  const Text('Standard loading indicator:'),
                  const SizedBox(height: 16),
                  const LoadingIndicator(message: 'Loading...'),
                  const SizedBox(height: 24),
                  const Text('Compact loading indicator:'),
                  const SizedBox(height: 16),
                  const LoadingIndicator(
                    message: 'Loading...',
                    compact: true,
                    size: 24,
                  ),
                ],
              ),
              _buildSection(
                'ErrorMessage',
                [
                  const Text('Standard error message:'),
                  const SizedBox(height: 16),
                  ErrorMessage(
                    message: 'Something went wrong',
                    onRetry: () => _showSnackBar('Retry pressed'),
                  ),
                  const SizedBox(height: 24),
                  const Text('Compact error message:'),
                  const SizedBox(height: 16),
                  ErrorMessage(
                    message: 'Something went wrong',
                    onRetry: () => _showSnackBar('Retry pressed'),
                    compact: true,
                    iconSize: 30,
                  ),
                ],
              ),
              _buildSection(
                'LoadingOverlay',
                [
                  const Text('Loading overlay example:'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _toggleOverlay,
                    child: Text(_isOverlayLoading ? 'Hide Overlay' : 'Show Overlay'),
                  ),
                ],
              ),
              _buildSection(
                'NetworkUtils',
                [
                  const Text('Network operation with error handling:'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _simulateNetworkOperation,
                    child: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simulate Network Call'),
                  ),
                ],
              ),
              _buildSection(
                'NetworkWidget',
                [
                  const Text('NetworkWidget example:'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Load Data'),
                      ),
                      ElevatedButton(
                        onPressed: _simulateError,
                        child: const Text('Simulate Error'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: NetworkWidget<List<String>>(
                      loadingState: _dataState,
                      loadingMessage: 'Loading data...',
                      onRetry: _loadData,
                      builder: (context, data) {
                        return ListView.builder(
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(data[index]),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              _buildSection(
                'NetworkStateWidget',
                [
                  const Text('NetworkStateWidget example:'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: NetworkStateWidget<List<String>>(
                      future: _fetchData,
                      loadingMessage: 'Fetching data...',
                      errorMessagePrefix: 'Data fetch error',
                      builder: (context, data) {
                        return ListView.builder(
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(data[index]),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
  
  void _toggleOverlay() {
    setState(() {
      _isOverlayLoading = !_isOverlayLoading;
    });
    
    if (_isOverlayLoading) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isOverlayLoading = false;
          });
        }
      });
    }
  }
  
  void _simulateNetworkOperation() {
    NetworkUtils.executeWithErrorHandling<String>(
      context,
      operation: () async {
        // Simulate network delay
        await Future.delayed(const Duration(seconds: 2));
        
        // Randomly succeed or fail
        if (_random.nextBool()) {
          return 'Operation successful';
        } else {
          throw Exception('Network operation failed');
        }
      },
      setLoading: (isLoading) {
        setState(() {
          _isLoading = isLoading;
        });
      },
      onSuccess: (result) {
        _showSnackBar(result);
      },
      errorMessage: 'Network error',
      showRetry: true,
      retryOperation: _simulateNetworkOperation,
    );
  }
  
  void _loadData() {
    setState(() {
      _dataState = LoadingState.loading();
    });
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _dataState = LoadingState.success(_generateDummyData());
        });
      }
    });
  }
  
  void _simulateError() {
    setState(() {
      _dataState = LoadingState.loading();
    });
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _dataState = LoadingState.error(
            Exception('Failed to load data'),
            'Could not load data. Please try again.',
          );
        });
      }
    });
  }
  
  Future<List<String>> _fetchData() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Randomly succeed or fail
    if (_random.nextBool()) {
      return _generateDummyData();
    } else {
      throw Exception('Failed to fetch data');
    }
  }
  
  List<String> _generateDummyData() {
    return List.generate(
      10,
      (index) => 'Item ${index + 1}',
    );
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}