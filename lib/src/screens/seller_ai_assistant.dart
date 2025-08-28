import 'package:flutter/material.dart';
import '../services/ai_service.dart';

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

  _runAI() async {
    setState(() => _loading = true);
    var reply = await _aiService.getAIResponse(_controller.text);
    setState(() {
      _result = reply;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Seller Assistant")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Describe your product or question",
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loading ? null : _runAI,
              child: _loading ? CircularProgressIndicator() : Text("Ask AI"),
            ),
            const SizedBox(height: 20),
            Expanded(child: SingleChildScrollView(child: Text(_result))),
          ],
        ),
      ),
    );
  }
}