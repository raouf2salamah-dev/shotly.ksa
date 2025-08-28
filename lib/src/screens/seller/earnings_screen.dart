import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../../services/earnings_service.dart';
import '../../models/transaction_model.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import '../../l10n/app_localizations.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  late Future<Map<String, dynamic>> _earningsFuture;
  String _selectedPeriod = 'month';

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  void _loadEarnings() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user == null) {
      _earningsFuture = Future.value({
        'totalEarnings': 0.0,
        'transactions': <TransactionModel>[],
        'monthlySummary': <String, double>{},
      });
      return;
    }
    
    final earningsService = EarningsService();
    _earningsFuture = earningsService.getEarningsSummary(
      userId: user.uid,
      period: _selectedPeriod,
    );
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadEarnings();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Earnings'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('You need to be logged in to view earnings'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _earningsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          
          if (snapshot.hasError) {
            return ErrorMessage(
              message: 'Error loading earnings: ${snapshot.error}',
              onRetry: _loadEarnings,
            );
          }
          
          final data = snapshot.data!;
          final double totalEarnings = data['totalEarnings'] ?? 0.0;
          final List<TransactionModel> transactions = data['transactions'] ?? [];
          final Map<String, double> monthlySummary = data['monthlySummary'] ?? {};
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period selector
                _buildPeriodSelector(),
                
                const SizedBox(height: 24),
                
                // Total earnings card
                _buildTotalEarningsCard(totalEarnings),
                
                const SizedBox(height: 24),
                
                // Earnings chart
                _buildEarningsChart(monthlySummary),
                
                const SizedBox(height: 24),
                
                // Recent transactions
                _buildRecentTransactions(transactions),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Period',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPeriodButton('week', 'Week'),
                _buildPeriodButton('month', 'Month'),
                _buildPeriodButton('year', 'Year'),
                _buildPeriodButton('all', 'All Time'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return ElevatedButton(
      onPressed: () => _changePeriod(period),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceVariant,
        foregroundColor: isSelected
            ? Colors.white
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      child: Text(label),
    );
  }

  Widget _buildTotalEarningsCard(double totalEarnings) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    return Card(
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('totalProfit'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(totalEarnings),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'For selected period: $_selectedPeriod',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsChart(Map<String, double> monthlySummary) {
    // This is a placeholder for the chart
    // In a real app, you would use a charting library like fl_chart
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnings Trend',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Center(
                child: monthlySummary.isEmpty
                    ? const Text('No earnings data available')
                    : const Text('Chart will be displayed here'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(List<TransactionModel> transactions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            transactions.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No transactions yet'),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return _buildTransactionItem(transaction);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat.yMMMd().add_jm();
    
    return ListTile(
      title: Text(transaction.contentTitle),
      subtitle: Text(dateFormat.format(transaction.date)),
      trailing: Text(
        currencyFormat.format(transaction.amount),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}