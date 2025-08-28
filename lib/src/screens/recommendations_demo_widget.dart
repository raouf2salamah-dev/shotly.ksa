import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../widgets/chip_list.dart';

class RecommendationsDemoWidget extends StatefulWidget {
  const RecommendationsDemoWidget({Key? key}) : super(key: key);

  @override
  State<RecommendationsDemoWidget> createState() => _RecommendationsDemoWidgetState();
}

class _RecommendationsDemoWidgetState extends State<RecommendationsDemoWidget> {
  final AIService _aiService = AIService();
  final TextEditingController _preferenceController = TextEditingController(text: 'red cars');
  String _currentPreference = 'red cars';

  @override
  void dispose() {
    _preferenceController.dispose();
    super.dispose();
  }

  Future<String> getRecommendations(String preference) {
    return _aiService.getRecommendations(preference);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendations Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _preferenceController,
              decoration: InputDecoration(
                labelText: 'Enter your preference',
                hintText: 'e.g., red cars, nature photography',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _currentPreference = _preferenceController.text;
                    });
                  },
                ),
              ),
              onSubmitted: (value) {
                setState(() {
                  _currentPreference = value;
                });
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Recommendations for "$_currentPreference":',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: buildRecommendations(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRecommendations(BuildContext context) {
    return FutureBuilder<String>(
      future: getRecommendations(_currentPreference),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        } else if (snapshot.hasData) {
          // Split the comma-separated string into a list of keywords
          final keywords = snapshot.data!.split(',').map((e) => e.trim()).toList();
          return ChipList(keywords); // A custom widget to display the chips
        }
        return const SizedBox.shrink();
      },
    );
  }
}