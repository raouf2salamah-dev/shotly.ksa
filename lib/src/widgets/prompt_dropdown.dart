import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';

class PromptDropdown extends StatefulWidget {
  final Function(String?) onPromptSelected;

  const PromptDropdown({Key? key, required this.onPromptSelected}) : super(key: key);

  @override
  State<PromptDropdown> createState() => _PromptDropdownState();
}

class _PromptDropdownState extends State<PromptDropdown> {
  late Future<List<String>> _promptsFuture;
  String? _selectedPrompt;

  @override
  void initState() {
    super.initState();
    _promptsFuture = _loadPrompts();
  }

  Future<List<String>> _loadPrompts() async {
    // This would typically come from an API or Firestore
    // For now, we'll use a static list
    return Future.value([
      'Describe your digital product in detail',
      'Create a compelling marketing description',
      'List the key features of your product',
      'Write a product description targeting beginners',
      'Create a technical description for advanced users'
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return FutureBuilder<List<String>>(
      future: _promptsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return DropdownButtonFormField<String>(
            value: _selectedPrompt,
            hint: Text(localizations.translate('selectPrompt') ?? 'Select a prompt'),
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Description Prompts',
            ),
            items: snapshot.data!.map((String prompt) {
              return DropdownMenuItem<String>(
                value: prompt,
                child: Text(prompt),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedPrompt = newValue;
              });
              widget.onPromptSelected(newValue);
            },
          );
        } else {
          return const Center(child: Text('No prompts available.'));
        }
      },
    );
  }
}