import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/ai_usage_tracker.dart';

class AIUsageDashboard extends StatefulWidget {
  final String? userId;
  
  const AIUsageDashboard({Key? key, this.userId}) : super(key: key);

  @override
  State<AIUsageDashboard> createState() => _AIUsageDashboardState();
}

class _AIUsageDashboardState extends State<AIUsageDashboard> {
  final AIUsageTracker _usageTracker = AIUsageTracker();
  Map<String, dynamic> _monthlyStats = {};
  bool _isLoading = true;
  double _budgetLimit = 10.0; // Default $10 monthly budget
  bool _editingBudget = false;
  final TextEditingController _budgetController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadUsageData();
    _budgetController.text = _budgetLimit.toString();
  }
  
  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUsageData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (widget.userId != null) {
        _monthlyStats = await _usageTracker.getUserMonthStats(widget.userId!);
      } else {
        _monthlyStats = await _usageTracker.getCurrentMonthStats();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading usage data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _saveBudget() {
    try {
      final newBudget = double.parse(_budgetController.text);
      if (newBudget >= 0) {
        setState(() {
          _budgetLimit = newBudget;
          _editingBudget = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final totalCost = _monthlyStats['totalCost'] ?? 0.0;
    final totalTokens = _monthlyStats['totalTokens'] ?? 0;
    final totalRequests = _monthlyStats['totalRequests'] ?? 0;
    final models = _monthlyStats['models'] as Map<String, dynamic>? ?? {};
    
    // Format currency
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Usage Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsageData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Monthly summary card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Monthly Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                DateFormat('MMMM yyyy').format(DateTime.now()),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          // Budget progress
                          Row(
                            children: [
                              const Text('Budget: '),
                              _editingBudget
                                  ? Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _budgetController,
                                              keyboardType: TextInputType.number,
                                              decoration: const InputDecoration(
                                                prefixText: '\$',
                                                isDense: true,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.check),
                                            onPressed: _saveBudget,
                                            iconSize: 20,
                                          ),
                                        ],
                                      ),
                                    )
                                  : Row(
                                      children: [
                                        Text(
                                          currencyFormat.format(_budgetLimit),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () {
                                            setState(() {
                                              _editingBudget = true;
                                            });
                                          },
                                          iconSize: 16,
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _budgetLimit > 0 ? (totalCost / _budgetLimit).clamp(0.0, 1.0) : 0,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              totalCost > _budgetLimit ? Colors.red : Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Used: ${currencyFormat.format(totalCost)}',
                                style: TextStyle(
                                  color: totalCost > _budgetLimit ? Colors.red : null,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Remaining: ${currencyFormat.format(_budgetLimit - totalCost)}',
                                style: TextStyle(
                                  color: totalCost > _budgetLimit ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Usage stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statItem(
                                'Requests',
                                totalRequests.toString(),
                                Icons.sync,
                              ),
                              _statItem(
                                'Tokens',
                                NumberFormat.compact().format(totalTokens),
                                Icons.token,
                              ),
                              _statItem(
                                'Cost',
                                currencyFormat.format(totalCost),
                                Icons.attach_money,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text(
                    'Model Usage Breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  // Model breakdown cards
                  ...models.entries.map((entry) {
                    final modelName = entry.key;
                    final modelData = entry.value as Map<String, dynamic>;
                    final modelCost = modelData['cost'] ?? 0.0;
                    final modelRequests = modelData['requests'] ?? 0;
                    final modelTokens = modelData['totalTokens'] ?? 0;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  modelName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(modelCost),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Requests: $modelRequests'),
                                Text('Tokens: ${NumberFormat.compact().format(modelTokens)}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: totalCost > 0 ? (modelCost / totalCost) : 0,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getModelColor(modelName),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${((modelCost / totalCost) * 100).toStringAsFixed(1)}% of total cost',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  
                  // Cost-saving tips
                  if (totalCost > 0)
                    Card(
                      margin: const EdgeInsets.only(top: 16),
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lightbulb, color: Colors.amber),
                                SizedBox(width: 8),
                                Text(
                                  'Cost-Saving Tips',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text('• Use caching to avoid duplicate requests'),
                            const Text('• Keep prompts concise to reduce token usage'),
                            const Text('• Use Gemini for most tasks (lower cost than GPT)'),
                            const Text('• Set appropriate max token limits for responses'),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
  
  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
  
  Color _getModelColor(String modelName) {
    switch (modelName) {
      case 'gemini-pro':
        return Colors.green;
      case 'gpt-3.5-turbo':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}