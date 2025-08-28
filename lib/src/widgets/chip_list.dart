import 'package:flutter/material.dart';

/// A widget that displays a list of keywords as chips
class ChipList extends StatelessWidget {
  final List<String> keywords;
  final EdgeInsets padding;
  final double spacing;
  final double runSpacing;
  
  const ChipList(
    this.keywords, {
    Key? key,
    this.padding = const EdgeInsets.all(8.0),
    this.spacing = 8.0,
    this.runSpacing = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: keywords.map((keyword) => _buildChip(context, keyword)).toList(),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String keyword) {
    return Chip(
      label: Text(keyword),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    );
  }
}