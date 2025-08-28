import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../security/device_integrity.dart';
import '../security/certificate_pinning_service.dart';
import '../security/secure_storage.dart';
import '../security/certificate_expiration_service.dart';
import '../bootstrap/security_bootstrap.dart';
import 'security_features_service.dart';
import 'build_metadata_service.dart';
import 'test_history_chart.dart';
import 'certificate_status_dashboard.dart';

/// SecurityDashboard displays the status of security features, build metadata,
/// and test history in a web dashboard format.
class SecurityDashboard extends StatefulWidget {
  const SecurityDashboard({Key? key}) : super(key: key);

  @override
  State<SecurityDashboard> createState() => _SecurityDashboardState();
}

class _SecurityDashboardState extends State<SecurityDashboard> {
  bool _isLoading = true;
  Map<String, bool> _securityFeatures = {};
  Map<String, dynamic> _buildMetadata = {};
  List<Map<String, dynamic>> _testHistory = [];
  Map<String, dynamic>? _selectedFeatureDetails;
  String? _selectedFeature;

  final SecurityFeaturesService _securityService = SecurityFeaturesService();
  final BuildMetadataService _buildService = BuildMetadataService();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.wait([
      _loadSecurityFeatures(),
      _loadBuildMetadata(),
      _loadTestHistory(),
    ]);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSecurityFeatures() async {
    final features = await _securityService.fetchSecurityFeatures();
    if (mounted) {
      setState(() {
        _securityFeatures = features;
      });
    }
  }

  Future<void> _loadBuildMetadata() async {
    final metadata = await _buildService.fetchLatestBuildMetadata();
    if (mounted) {
      setState(() {
        _buildMetadata = metadata;
      });
    }
  }

  Future<void> _loadTestHistory() async {
    final history = await _buildService.fetchBuildHistory();
    if (mounted) {
      setState(() {
        _testHistory = history;
      });
    }
  }

  Future<void> _loadFeatureDetails(String featureName) async {
    final details = await _securityService.fetchFeatureDetails(featureName);
    if (mounted) {
      setState(() {
        _selectedFeatureDetails = details;
        _selectedFeature = featureName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSecurityFeaturesCard(),
                const SizedBox(height: 16),
                if (_selectedFeatureDetails != null) _buildFeatureDetailsCard(),
                const SizedBox(height: 16),
                const CertificateStatusDashboard(),
                const SizedBox(height: 16),
                _buildBuildMetadataCard(),
                const SizedBox(height: 16),
                _buildTestHistoryCard(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadDashboardData,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildSecurityFeaturesCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security Features',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              children: _securityFeatures.entries.map((entry) {
                final isActive = entry.value;
                return InkWell(
                  onTap: () => _loadFeatureDetails(entry.key),
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: isActive ? Colors.green : Colors.red,
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? Icons.security : Icons.security_update_warning,
                          color: isActive ? Colors.green : Colors.red,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.key,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureDetailsCard() {
    if (_selectedFeatureDetails == null || _selectedFeature == null) {
      return const SizedBox.shrink();
    }

    final details = _selectedFeatureDetails!;
    final isEnabled = details['enabled'] as bool;
    final lastUpdated = details['lastUpdated'] != null
        ? _formatDate(details['lastUpdated'] as String)
        : 'Never';

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_selectedFeature Details',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedFeatureDetails = null;
                      _selectedFeature = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Status', isEnabled ? 'Active' : 'Inactive',
                valueColor: isEnabled ? Colors.green : Colors.red),
            _buildDetailRow('Description', details['description'] as String),
            _buildDetailRow('Implementation', details['implementation'] as String),
            _buildDetailRow('Last Updated', lastUpdated),
            if (details.containsKey('domains'))
              _buildDetailRow(
                  'Protected Domains', (details['domains'] as List<dynamic>).join(', ')),
          ],
        ),
      ),
    );
  }

  Widget _buildBuildMetadataCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Latest Build',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMetadataRow('Build Number', _buildMetadata['buildNumber']),
                      _buildMetadataRow('Build Date', _formatDate(_buildMetadata['buildDate'])),
                      _buildMetadataRow('Branch', _buildMetadata['branch']),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMetadataRow('Commit', _buildMetadata['commitHash']),
                      _buildMetadataRow('Duration', _buildMetadata['duration'] ?? 'N/A'),
                      _buildMetadataRow(
                        'Status',
                        _buildMetadata['buildStatus'],
                        valueColor: _buildMetadata['buildStatus'] == 'success'
                            ? Colors.green
                            : (_buildMetadata['buildStatus'] == 'partial_success'
                                ? Colors.orange
                                : Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            value,
            style: TextStyle(color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTestHistoryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TestHistoryChart(testHistory: _testHistory),
            const SizedBox(height: 16),
            const Text(
              'Recent Test Results',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Colors.grey),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Build', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Passed', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Failed', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                ..._testHistory.take(5).map((test) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(test['buildNumber']),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_formatDate(test['buildDate'])),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(test['tests']['total'].toString()),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          test['tests']['passed'].toString(),
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          test['tests']['failed'].toString(),
                          style: TextStyle(
                            color: test['tests']['failed'] > 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}