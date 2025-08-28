import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

import '../../models/content_model.dart';
import '../../services/content_service.dart';
import '../../widgets/custom_button.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _selectedPeriod = 'Week';
  List<String> _periods = ['Week', 'Month', 'Year'];
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update periods with translated values
    _periods = [
      AppLocalizations.of(context)!.translate('week'),
      AppLocalizations.of(context)!.translate('month'),
      AppLocalizations.of(context)!.translate('year')
    ];
    
    // Update selected period with translated value if needed
    if (_selectedPeriod == 'Week') {
      _selectedPeriod = AppLocalizations.of(context)!.translate('week');
    } else if (_selectedPeriod == 'Month') {
      _selectedPeriod = AppLocalizations.of(context)!.translate('month');
    } else if (_selectedPeriod == 'Year') {
      _selectedPeriod = AppLocalizations.of(context)!.translate('year');
    }
  }
  
  // Analytics data
  double _totalEarnings = 0;
  int _totalSales = 0;
  int _totalViews = 0;
  Map<ContentType, int> _salesByContentType = {};
  List<Map<String, dynamic>> _topSellingContent = [];
  List<Map<String, dynamic>> _revenueData = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAnalyticsData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final contentService = Provider.of<ContentService>(context, listen: false);
      
      // Fetch analytics data based on selected period
      final analyticsData = await contentService.getSellerAnalytics(period: _selectedPeriod.toLowerCase());
      
      setState(() {
        _totalEarnings = analyticsData['totalEarnings'] ?? 0;
        _totalSales = analyticsData['totalSales'] ?? 0;
        _totalViews = analyticsData['totalViews'] ?? 0;
        _salesByContentType = Map<ContentType, int>.from(analyticsData['salesByContentType'] ?? {});
        _topSellingContent = List<Map<String, dynamic>>.from(analyticsData['topSellingContent'] ?? []);
        _revenueData = List<Map<String, dynamic>>.from(analyticsData['revenueData'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load analytics: ${e.toString()}'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('analytics')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.translate('overview')),
            Tab(text: AppLocalizations.of(context)!.translate('sales')),
            Tab(text: AppLocalizations.of(context)!.translate('content')),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Period selector
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.translate('timePeriod'),
                        style: theme.textTheme.titleMedium,
                      ),
                      DropdownButton<String>(
                        value: _selectedPeriod,
                        items: _periods.map((period) {
                          return DropdownMenuItem<String>(
                            value: period,
                            child: Text(period),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null && value != _selectedPeriod) {
                            setState(() {
                              _selectedPeriod = value;
                            });
                            _fetchAnalyticsData();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildSalesTab(),
                      _buildContentTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildOverviewTab() {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: AppLocalizations.of(context)!.translate('totalProfit'),
                  value: currencyFormat.format(_totalEarnings),
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: _buildSummaryCard(
                  title: AppLocalizations.of(context)!.translate('totalSales'),
                  value: _totalSales.toString(),
                  icon: Icons.shopping_cart,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: AppLocalizations.of(context)!.translate('totalViews'),
                  value: _totalViews.toString(),
                  icon: Icons.visibility,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: _buildSummaryCard(
                  title: AppLocalizations.of(context)!.translate('conversionRate'),
                  value: _totalViews > 0
                      ? '${((_totalSales / _totalViews) * 100).toStringAsFixed(1)}%'
                      : '0%',
                  icon: Icons.trending_up,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          
          // Revenue chart
          const SizedBox(height: 32.0),
          Text(
            AppLocalizations.of(context)!.translate('revenueTrend'),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          SizedBox(
            height: 200.0,
            child: _revenueData.isEmpty
                ? Center(child: Text(AppLocalizations.of(context)!.translate('noRevenueDataAvailable') ?? 'No revenue data available'))
                : _buildRevenueChart(),
          ),
          
          // Content type breakdown
          const SizedBox(height: 32.0),
          Text(
            AppLocalizations.of(context)!.translate('salesByContentType') ?? 'Sales by Content Type',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          SizedBox(
            height: 200.0,
            child: _salesByContentType.isEmpty
                ? Center(child: Text(AppLocalizations.of(context)!.translate('noSalesDataAvailable') ?? 'No sales data available'))
                : _buildContentTypePieChart(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSalesTab() {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.translate('sales_performance'),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          SizedBox(
            height: 200.0,
            child: _revenueData.isEmpty
                ? Center(child: Text(AppLocalizations.of(context)!.translate('no_sales_data_available')))
                : _buildSalesBarChart(),
          ),
          
          const SizedBox(height: 32.0),
          Text(
            AppLocalizations.of(context)!.translate('top_selling_content'),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          _topSellingContent.isEmpty
              ? Center(child: Text(AppLocalizations.of(context)!.translate('no_top_selling_content_available')))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _topSellingContent.length,
                  itemBuilder: (context, index) {
                    final content = _topSellingContent[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          content['thumbnailUrl'] ?? '',
                          width: 50.0,
                          height: 50.0,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 50.0,
                              height: 50.0,
                              color: Colors.grey.shade300,
                              child: Icon(
                                _getContentTypeIcon(ContentType.values.firstWhere(
                                  (type) => type.name == content['contentType'],
                                  orElse: () => ContentType.image,
                                )),
                                color: Colors.grey.shade700,
                              ),
                            );
                          },
                        ),
                      ),
                      title: Text(content['title'] ?? AppLocalizations.of(context)!.translate('untitled')),
                      subtitle: Text(
                        '${content['sales'] ?? 0} ${AppLocalizations.of(context)!.translate('sales').toLowerCase()} · ${currencyFormat.format(content['revenue'] ?? 0)}',
                      ),
                      trailing: Icon(
                        _getContentTypeIcon(ContentType.values.firstWhere(
                          (type) => type.name == content['contentType'],
                          orElse: () => ContentType.image,
                        )),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
  
  Widget _buildContentTab() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.translate('content_performance'),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          _buildContentPerformanceTable(),
          
          const SizedBox(height: 32.0),
          CustomButton(
            text: AppLocalizations.of(context)!.translate('download_analytics_report'),
            icon: Icons.download,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.translate('report_download_feature_coming_soon')))
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? Colors.white
            : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 24.0,
              ),
              const SizedBox(width: 8.0),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRevenueChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= _revenueData.length || value.toInt() < 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _revenueData[value.toInt()]['label'] ?? '',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toInt()}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1),
        ),
        minX: 0,
        maxX: _revenueData.length.toDouble() - 1,
        minY: 0,
        maxY: _revenueData.isEmpty
            ? 10
            : (_revenueData.map((data) => data['value'] as double).reduce((a, b) => a > b ? a : b) * 1.2),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(_revenueData.length, (index) {
              return FlSpot(index.toDouble(), _revenueData[index]['value'] as double);
            }),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContentTypePieChart() {
    final List<Color> colors = [Colors.blue, Colors.red, Colors.green];
    final totalSales = _salesByContentType.values.fold(0, (sum, sales) => sum + sales);
    
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: List.generate(_salesByContentType.length, (index) {
          final entry = _salesByContentType.entries.elementAt(index);
          final contentType = entry.key;
          final sales = entry.value;
          final percentage = totalSales > 0 ? (sales / totalSales) * 100 : 0;
          
          return PieChartSectionData(
            color: colors[index % colors.length],
            value: sales.toDouble(),
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildSalesBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _revenueData.isEmpty
            ? 10
            : (_revenueData.map((data) => data['value'] as double).reduce((a, b) => a > b ? a : b) * 1.2),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '\$${rod.toY.toStringAsFixed(2)}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= _revenueData.length || value.toInt() < 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _revenueData[value.toInt()]['label'] ?? '',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
              reservedSize: 38,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toInt()}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(_revenueData.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: _revenueData[index]['value'] as double,
                color: Colors.blue,
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
  
  Widget _buildContentPerformanceTable() {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return _topSellingContent.isEmpty
        ? Center(child: Text(AppLocalizations.of(context)!.translate('no_content_performance_data_available')))
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text(AppLocalizations.of(context)!.translate('content'))),
                DataColumn(label: Text(AppLocalizations.of(context)!.translate('type'))),
                DataColumn(label: Text(AppLocalizations.of(context)!.translate('views'))),
                DataColumn(label: Text(AppLocalizations.of(context)!.translate('sales'))),
                DataColumn(label: Text(AppLocalizations.of(context)!.translate('revenue'))),
                DataColumn(label: Text(AppLocalizations.of(context)!.translate('conversion'))),
              ],
              rows: _topSellingContent.map((content) {
                final views = content['views'] ?? 0;
                final sales = content['sales'] ?? 0;
                final conversionRate = views > 0 ? (sales / views) * 100 : 0;
                
                return DataRow(
                  cells: [
                    DataCell(Text(
                      content['title'] ?? AppLocalizations.of(context)!.translate('untitled'),
                      overflow: TextOverflow.ellipsis,
                    )),
                    DataCell(Icon(_getContentTypeIcon(ContentType.values.firstWhere(
                      (type) => type.name == content['contentType'],
                      orElse: () => ContentType.image,
                    )))),
                    DataCell(Text(views.toString())),
                    DataCell(Text(sales.toString())),
                    DataCell(Text(currencyFormat.format(content['revenue'] ?? 0))),
                    DataCell(Text('${conversionRate.toStringAsFixed(1)}%')),
                  ],
                );
              }).toList(),
            ),
          );
  }
  
  IconData _getContentTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.image:
        return Icons.image;
      case ContentType.gif:
        return Icons.gif;
      case ContentType.video:
        return Icons.videocam;
    }
  }
}