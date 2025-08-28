import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class VertexRecommendationsScreen extends StatefulWidget {
  const VertexRecommendationsScreen({Key? key}) : super(key: key);

  @override
  State<VertexRecommendationsScreen> createState() => _VertexRecommendationsScreenState();
}

class _VertexRecommendationsScreenState extends State<VertexRecommendationsScreen> {
  final AIService _aiService = AIService();
  final TextEditingController _preferenceController = TextEditingController();
  String _recommendations = '';
  bool _isLoading = false;
  List<String> _keywordsList = [];

  @override
  void dispose() {
    _preferenceController.dispose();
    super.dispose();
  }

  Future<void> _getRecommendations() async {
    if (_preferenceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your preference')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _recommendations = '';
      _keywordsList = [];
    });

    try {
      final response = await _aiService.getRecommendations(
        _preferenceController.text,
      );

      setState(() {
        _recommendations = response;
        _keywordsList = response.split(',').map((e) => e.trim()).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _recommendations = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VertexAI Recommendations'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _preferenceController,
              decoration: InputDecoration(
                labelText: 'Enter your preference',
                hintText: 'e.g., nature photography, action movies, cute animals',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _getRecommendations,
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _getRecommendations(),
            ),
            const SizedBox(height: 24),
            Text(
              'Recommended Keywords',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _keywordsList.isEmpty
                      ? Center(
                          child: Text(
                            'Enter your preference to get recommendations',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _keywordsList.length,
                          itemBuilder: (context, index) {
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text('${index + 1}'),
                                ),
                                title: Text(_keywordsList[index]),
                                trailing: IconButton(
                                  icon: const Icon(Icons.content_copy),
                                  onPressed: () {
                                    // Copy to clipboard functionality would go here
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('"${_keywordsList[index]}" copied to clipboard')),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}