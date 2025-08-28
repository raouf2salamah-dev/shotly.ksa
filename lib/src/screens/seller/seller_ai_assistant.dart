import 'package:flutter/material.dart'; 
import 'package:flutter/services.dart';
import '../../services/ai_service.dart'; 
import '../../widgets/prompt_dropdown.dart';
import '../../l10n/app_localizations.dart';
 
class SellerAIAssistant extends StatefulWidget { 
  const SellerAIAssistant({Key? key}) : super(key: key); 
 
  @override 
  State<SellerAIAssistant> createState() => _SellerAIAssistantState(); 
} 
 
class _SellerAIAssistantState extends State<SellerAIAssistant> { 
  final _aiService = AIService(); 
  final _controller = TextEditingController(); 
  String _result = ""; 
  bool _loading = false;
  String? _selectedPrompt;
 
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _runAI() async { 
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description or select a prompt')),
      );
      return;
    }
    
    setState(() => _loading = true); 
    try {
      var reply = await _aiService.getAIResponse(_controller.text); 
      setState(() { 
        _result = reply; 
        _loading = false; 
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } 
  } 
 
  @override 
  Widget build(BuildContext context) { 
    return Scaffold( 
      appBar: AppBar(title: const Text("AI Seller Assistant")), 
      body: Padding( 
        padding: const EdgeInsets.all(16.0), 
        child: Column( 
          children: [ 
            PromptDropdown(
              onPromptSelected: (prompt) {
                setState(() {
                  _selectedPrompt = prompt;
                  if (prompt != null) {
                    _controller.text = prompt;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            TextField( 
              controller: _controller, 
              decoration: const InputDecoration( 
                labelText: "Describe your product or question", 
                border: OutlineInputBorder(),
              ),
              maxLines: 3, 
            ), 
            const SizedBox(height: 16), 
            ElevatedButton.icon( 
              onPressed: _loading ? null : _runAI, 
              icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.smart_toy), 
              label: Text(_loading ? "Generating..." : "Generate with AI"), 
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ), 
            const SizedBox(height: 20),
            Expanded(
              child: _result.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.smart_toy_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Select a prompt or enter your question above',
                          style: TextStyle(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.smart_toy, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'AI Response',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                tooltip: 'Copy to clipboard',
                                onPressed: () {
                                  // Copy text to clipboard
                                  if (_result.isNotEmpty) {
                                    Clipboard.setData(ClipboardData(text: _result));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Copied to clipboard')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(_result, style: Theme.of(context).textTheme.bodyLarge),
                        ],
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