import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';

class AdminSettingsScreenAr extends StatefulWidget {
  const AdminSettingsScreenAr({super.key});

  @override
  State<AdminSettingsScreenAr> createState() => _AdminSettingsScreenArState();
}

class _AdminSettingsScreenArState extends State<AdminSettingsScreenAr> {
  bool _isLoading = false;
  
  // Mock settings
  bool _enableUserRegistration = true;
  bool _enableContentUploads = true;
  bool _enablePurchases = true;
  bool _enableNotifications = true;
  bool _enableAnalytics = true;
  bool _enableDarkMode = false;
  bool _enableMaintenanceMode = false;
  String _selectedLanguage = 'العربية';
  String _selectedCurrency = 'SAR';
  double _commissionRate = 15.0; // 15%
  int _maxUploadSize = 50; // 50 MB
  
  final List<String> _languages = ['الإنجليزية', 'العربية', 'الفرنسية', 'الإسبانية', 'الألمانية'];
  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'SAR'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    
    // Check if user is admin
    if (!authService.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('إعدادات النظام'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('تحتاج إلى صلاحيات المسؤول للوصول إلى هذه الصفحة'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('العودة'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات النظام'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh settings (would fetch from backend in real app)
              setState(() {});
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('حالة النظام'),
                    _buildSystemStatusCard(),
                    const SizedBox(height: 24.0),
                    
                    _buildSectionHeader('الإعدادات العامة'),
                    _buildSettingsCard(
                      children: [
                        _buildSwitchSetting(
                          title: 'تمكين تسجيل المستخدمين',
                          subtitle: 'السماح للمستخدمين الجدد بالتسجيل',
                          value: _enableUserRegistration,
                          onChanged: (value) {
                            setState(() {
                              _enableUserRegistration = value;
                            });
                          },
                        ),
                        const Divider(),
                        _buildSwitchSetting(
                          title: 'تمكين تحميل المحتوى',
                          subtitle: 'السماح للبائعين بتحميل محتوى جديد',
                          value: _enableContentUploads,
                          onChanged: (value) {
                            setState(() {
                              _enableContentUploads = value;
                            });
                          },
                        ),
                        const Divider(),
                        _buildSwitchSetting(
                          title: 'تمكين المشتريات',
                          subtitle: 'السماح للمشترين بشراء المحتوى',
                          value: _enablePurchases,
                          onChanged: (value) {
                            setState(() {
                              _enablePurchases = value;
                            });
                          },
                        ),
                        const Divider(),
                        _buildSwitchSetting(
                          title: 'تمكين الإشعارات',
                          subtitle: 'إرسال إشعارات للمستخدمين',
                          value: _enableNotifications,
                          onChanged: (value) {
                            setState(() {
                              _enableNotifications = value;
                            });
                          },
                        ),
                        const Divider(),
                        _buildSwitchSetting(
                          title: 'تمكين التحليلات',
                          subtitle: 'جمع بيانات الاستخدام للتحليل',
                          value: _enableAnalytics,
                          onChanged: (value) {
                            setState(() {
                              _enableAnalytics = value;
                            });
                          },
                        ),
                        const Divider(),
                        _buildSwitchSetting(
                          title: 'الوضع الداكن',
                          subtitle: 'تمكين السمة الداكنة للتطبيق',
                          value: _enableDarkMode,
                          onChanged: (value) {
                            setState(() {
                              _enableDarkMode = value;
                            });
                          },
                        ),
                        const Divider(),
                        _buildSwitchSetting(
                          title: 'وضع الصيانة',
                          subtitle: 'وضع التطبيق في وضع الصيانة (يمكن للمسؤولين فقط الوصول)',
                          value: _enableMaintenanceMode,
                          onChanged: (value) {
                            _showMaintenanceModeConfirmation(value);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24.0),
                    
                    _buildSectionHeader('التوطين'),
                    _buildSettingsCard(
                      children: [
                        _buildDropdownSetting(
                          title: 'اللغة الافتراضية',
                          value: _selectedLanguage,
                          items: _languages.map((lang) => DropdownMenuItem(
                            value: lang,
                            child: Text(lang),
                          )).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedLanguage = value.toString();
                            });
                          },
                        ),
                        const Divider(),
                        _buildDropdownSetting(
                          title: 'العملة الافتراضية',
                          value: _selectedCurrency,
                          items: _currencies.map((currency) => DropdownMenuItem(
                            value: currency,
                            child: Text(currency),
                          )).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCurrency = value.toString();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24.0),
                    
                    _buildSectionHeader('إعدادات الأعمال'),
                    _buildSettingsCard(
                      children: [
                        _buildSliderSetting(
                          title: 'نسبة العمولة',
                          subtitle: 'النسبة المأخوذة من كل عملية بيع',
                          value: _commissionRate,
                          min: 0.0,
                          max: 50.0,
                          divisions: 50,
                          label: '${_commissionRate.toStringAsFixed(1)}%',
                          onChanged: (value) {
                            setState(() {
                              _commissionRate = value;
                            });
                          },
                        ),
                        const Divider(),
                        _buildSliderSetting(
                          title: 'الحد الأقصى لحجم التحميل',
                          subtitle: 'الحد الأقصى لحجم الملف للتحميلات (ميجابايت)',
                          value: _maxUploadSize.toDouble(),
                          min: 5.0,
                          max: 500.0,
                          divisions: 99,
                          label: '${_maxUploadSize.toStringAsFixed(0)} ميجابايت',
                          onChanged: (value) {
                            setState(() {
                              _maxUploadSize = value.toInt();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24.0),
                    
                    _buildSectionHeader('إجراءات النظام'),
                    _buildSettingsCard(
                      children: [
                        _buildActionButton(
                          title: 'نسخ قاعدة البيانات احتياطياً',
                          subtitle: 'إنشاء نسخة احتياطية من قاعدة البيانات بالكامل',
                          icon: Icons.backup,
                          onPressed: () {
                            _showActionConfirmation(
                              'نسخ قاعدة البيانات احتياطياً',
                              'هل أنت متأكد أنك تريد إنشاء نسخة احتياطية من قاعدة البيانات؟ قد يستغرق هذا عدة دقائق.',
                              () {
                                _performSystemAction('بدأ النسخ الاحتياطي. قد يستغرق هذا عدة دقائق.');
                              },
                            );
                          },
                        ),
                        const Divider(),
                        _buildActionButton(
                          title: 'مسح ذاكرة التخزين المؤقت',
                          subtitle: 'مسح ذاكرة التخزين المؤقت للنظام والملفات المؤقتة',
                          icon: Icons.cleaning_services,
                          onPressed: () {
                            _showActionConfirmation(
                              'مسح ذاكرة التخزين المؤقت',
                              'هل أنت متأكد أنك تريد مسح ذاكرة التخزين المؤقت للنظام؟',
                              () {
                                _performSystemAction('تم مسح ذاكرة التخزين المؤقت بنجاح.');
                              },
                            );
                          },
                        ),
                        const Divider(),
                        _buildActionButton(
                          title: 'إرسال إشعار تجريبي',
                          subtitle: 'إرسال إشعار تجريبي لجميع المسؤولين',
                          icon: Icons.notifications,
                          onPressed: () {
                            _performSystemAction('تم إرسال إشعار تجريبي لجميع المسؤولين.');
                          },
                        ),
                        const Divider(),
                        _buildActionButton(
                          title: 'إعادة تعيين إعدادات النظام',
                          subtitle: 'إعادة تعيين جميع الإعدادات إلى القيم الافتراضية',
                          icon: Icons.restore,
                          isDestructive: true,
                          onPressed: () {
                            _showActionConfirmation(
                              'إعادة تعيين إعدادات النظام',
                              'هل أنت متأكد أنك تريد إعادة تعيين جميع الإعدادات إلى قيمها الافتراضية؟ لا يمكن التراجع عن هذا الإجراء.',
                              () {
                                _resetSettings();
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32.0),
                    
                    Center(
                      child: CustomButton(
                        text: 'حفظ جميع الإعدادات',
                        onPressed: _saveSettings,
                        isLoading: _isLoading,
                        width: 200,
                      ),
                    ),
                    const SizedBox(height: 32.0),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16.0,
                  height: 16.0,
                  decoration: BoxDecoration(
                    color: _enableMaintenanceMode ? Colors.red : Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  _enableMaintenanceMode ? 'وضع الصيانة' : 'النظام متصل',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _enableMaintenanceMode ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    title: 'حالة الخادم',
                    status: 'متصل',
                    icon: Icons.cloud_done,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    title: 'قاعدة البيانات',
                    status: 'متصلة',
                    icon: Icons.storage,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    title: 'التخزين',
                    status: '68% مستخدم',
                    icon: Icons.sd_storage,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    title: 'حالة API',
                    status: 'تعمل',
                    icon: Icons.api,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    title: 'بوابة الدفع',
                    status: 'نشطة',
                    icon: Icons.payment,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    title: 'الذاكرة المؤقتة',
                    status: 'محسنة',
                    icon: Icons.memory,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem({
    required String title,
    required String status,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24.0),
        const SizedBox(height: 4.0),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        Text(
          status,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDropdownSetting<T>({
    required String title,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSliderSetting({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: label,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: isDestructive ? Colors.red : Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDestructive ? Colors.red : null,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: isDestructive ? Colors.red : null,
          ),
          child: Text(isDestructive ? 'إعادة تعيين' : 'تنفيذ'),
        ),
      ],
    );
  }

  void _showMaintenanceModeConfirmation(bool value) {
    if (value) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تمكين وضع الصيانة'),
          content: const Text(
            'هل أنت متأكد أنك تريد تمكين وضع الصيانة؟ سيمنع هذا جميع المستخدمين غير المسؤولين من الوصول إلى التطبيق.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _enableMaintenanceMode = true;
                });
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('تمكين'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _enableMaintenanceMode = false;
      });
    }
  }

  void _showActionConfirmation(
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _performSystemAction(String successMessage) {
    // In a real app, this would perform the actual action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
  }

  void _resetSettings() {
    setState(() {
      _enableUserRegistration = true;
      _enableContentUploads = true;
      _enablePurchases = true;
      _enableNotifications = true;
      _enableAnalytics = true;
      _enableDarkMode = false;
      _enableMaintenanceMode = false;
      _selectedLanguage = 'العربية';
      _selectedCurrency = 'SAR';
      _commissionRate = 15.0;
      _maxUploadSize = 50;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت إعادة تعيين جميع الإعدادات إلى القيم الافتراضية')),
    );
  }

  void _saveSettings() {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الإعدادات بنجاح')),
      );
    });
  }
}