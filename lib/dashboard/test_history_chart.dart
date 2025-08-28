import 'package:flutter/material.dart';

/// TestHistoryChart displays a visual representation of test pass/fail history
/// using a simple bar chart visualization.
class TestHistoryChart extends StatelessWidget {
  /// List of test history data points
  final List<Map<String, dynamic>> testHistory;
  
  /// Maximum number of builds to display
  final int maxBuilds;
  
  const TestHistoryChart({
    Key? key,
    required this.testHistory,
    this.maxBuilds = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sort test history by build number (descending)
    final sortedHistory = List<Map<String, dynamic>>.from(testHistory)
      ..sort((a, b) => int.parse(b['buildNumber'].toString())
          .compareTo(int.parse(a['buildNumber'].toString())));
    
    // Limit to maxBuilds
    final limitedHistory = sortedHistory.take(maxBuilds).toList();
    
    // Reverse for display (oldest on left)
    final displayHistory = limitedHistory.reversed.toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Test Pass/Fail History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: displayHistory.isEmpty
              ? const Center(child: Text('No test history available'))
              : _buildChart(displayHistory, context),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(Colors.green, 'Passed'),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.red, 'Failed'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> history, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Y-axis labels
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('100%', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            Text('75%', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            Text('50%', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            Text('25%', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            Text('0%', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
        const SizedBox(width: 8),
        // Chart bars
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: history.map((build) {
              final total = build['tests']['total'] as int;
              final passed = build['tests']['passed'] as int;
              final failed = build['tests']['failed'] as int;
              
              final passedPercentage = total > 0 ? passed / total : 0.0;
              final failedPercentage = total > 0 ? failed / total : 0.0;
              
              return Tooltip(
                message: 'Build ${build['buildNumber']}\n'
                    'Passed: $passed\n'
                    'Failed: $failed\n'
                    'Total: $total',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Chart bar
                    SizedBox(
                      width: 20,
                      height: 160,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Failed tests (red)
                          Container(
                            width: 20,
                            height: 160 * failedPercentage,
                            color: Colors.red,
                          ),
                          // Passed tests (green)
                          Container(
                            width: 20,
                            height: 160 * passedPercentage,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Build number label
                    Text(
                      build['buildNumber'].toString(),
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}