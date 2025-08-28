import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';

class GeminiDemoScreen extends StatefulWidget {
  const GeminiDemoScreen({Key? key}) : super(key: key);

  @override
  State<GeminiDemoScreen> createState() => _GeminiDemoScreenState();
}

class _GeminiDemoScreenState extends State<GeminiDemoScreen> {
  final AIService _aiService = AIService();
  final TextEditingController _promptController = TextEditingController();
  String _response = '';
  bool _isLoading = false;
  bool _useGemini = true; // Default to Gemini

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _getAIResponse() async {
    if (_promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a prompt')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _response = '';
    });

    try {
      final response = await _aiService.getAIResponse(
        _promptController.text,
        useGemini: _useGemini,
      );

      setState(() {
        _response = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _response = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini AI Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.recommend),
            tooltip: 'VertexAI Recommendations',
            onPressed: () => Navigator.of(context).pushNamed('/vertex-recommendations'),
          ),
          IconButton(
            icon: const Icon(Icons.label),
            tooltip: 'Recommendations Demo',
            onPressed: () => Navigator.of(context).pushNamed('/recommendations-demo'),
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            tooltip: 'Gemini Chat Demo',
            onPressed: () => Navigator.of(context).pushNamed('/gemini-chat'),
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'AI Usage Dashboard',
            onPressed: () => Navigator.of(context).pushNamed('/ai-usage'),
          ),
          Switch(
            value: _useGemini,
            onChanged: (value) {
              setState(() {
                _useGemini = value;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text(_useGemini ? 'Gemini' : 'OpenAI'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _promptController,
              decoration: InputDecoration(
                hintText: 'Enter your prompt',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _getAIResponse,
                ),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _getAIResponse(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Text(
                          _response.isEmpty
                              ? 'AI response will appear here'
                              : _response,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}