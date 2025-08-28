import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  // Helper method to capitalize a string
  String _capitalizeString(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
  late TabController _tabController;
  bool _isLoading = false;
  
  // Mock data for demonstration
  final int _totalUsers = 1250;
  final int _totalSellers = 350;
  final int _totalBuyers = 900;
  final int _totalAdmins = 5;
  final int _totalSuperAdmins = 2;
  final int _totalContent = 2800;
  final double _totalRevenue = 15750.50;
  final int _pendingReports = 12;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    
    // Check if user is admin or super admin
    if (!authService.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('You need admin privileges to access this page'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Users'),
            Tab(text: 'Content'),
            Tab(text: 'AI'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/admin/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (!mounted) return;
              context.go('/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildContentTab(),
                _buildAITab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show quick actions menu
          _showQuickActionsMenu(context);
        },
        child: const Icon(Icons.add),
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
          Text(
            'System Overview',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Users',
                  value: _totalUsers.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Revenue',
                  value: currencyFormat.format(_totalRevenue),
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Content',
                  value: _totalContent.toString(),
                  icon: Icons.image,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Pending Reports',
                  value: _pendingReports.toString(),
                  icon: Icons.flag,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          
          // User distribution
          const SizedBox(height: 32.0),
          Text(
            'User Distribution',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Placeholder for pie chart
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.background,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24.0),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('Sellers', _totalSellers, Colors.blue),
                      const SizedBox(height: 16.0),
                      _buildLegendItem('Buyers', _totalBuyers, Colors.green),
                      const SizedBox(height: 16.0),
                      _buildLegendItem('Admins', _totalAdmins, Colors.red),
                      if (Provider.of<AuthService>(context).isSuperAdmin) ...[  
                        const SizedBox(height: 16.0),
                        _buildLegendItem('Super Admins', _totalSuperAdmins, Colors.purple),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Quick actions
          const SizedBox(height: 32.0),
          Text(
            'Quick Actions',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            children: [
              _buildActionButton(
                icon: Icons.person_add,
                label: 'Add User',
                onTap: () => context.push('/admin/users/add'),
              ),
              if (Provider.of<AuthService>(context).isSuperAdmin)
                _buildActionButton(
                  icon: Icons.admin_panel_settings,
                  label: 'Create Super Admin',
                  onTap: () => context.push('/admin/create-super-admin'),
                ),
              _buildActionButton(
                icon: Icons.category,
                label: 'Manage Categories',
                onTap: () => context.push('/admin/categories'),
              ),
              _buildActionButton(
                icon: Icons.flag,
                label: 'Review Reports',
                onTap: () => context.push('/admin/reports'),
              ),
              _buildActionButton(
                icon: Icons.settings,
                label: 'System Settings',
                onTap: () => context.push('/admin/settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildUsersTab() {
    final theme = Theme.of(context);
    
    // Mock user data
    final users = [
      {'id': '1', 'name': 'John Doe', 'email': 'john@example.com', 'role': 'seller', 'status': 'active'},
      {'id': '2', 'name': 'Jane Smith', 'email': 'jane@example.com', 'role': 'buyer', 'status': 'active'},
      {'id': '3', 'name': 'Bob Johnson', 'email': 'bob@example.com', 'role': 'seller', 'status': 'suspended'},
      {'id': '4', 'name': 'Alice Brown', 'email': 'alice@example.com', 'role': 'buyer', 'status': 'active'},
      {'id': '5', 'name': 'Admin User', 'email': 'admin@example.com', 'role': 'admin', 'status': 'active'},
    ];
    
    return Column(
      children: [
        // Search and filter bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                onSelected: (value) {
                  // Handle filter selection
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'all', child: Text('All Users')),
                  const PopupMenuItem(value: 'sellers', child: Text('Sellers Only')),
                  const PopupMenuItem(value: 'buyers', child: Text('Buyers Only')),
                  const PopupMenuItem(value: 'admins', child: Text('Admins Only')),
                  const PopupMenuItem(value: 'suspended', child: Text('Suspended Users')),
                ],
              ),
            ],
          ),
        ),
        
        // Users list
        Expanded(
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getRoleColor(user['role']!),
                    child: Text(
                      user['name']![0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(user['name']!),
                  subtitle: Text('${user['email']} • ${user['role']?.capitalize()}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: user['status'] == 'active' ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          user['status']!.capitalize(),
                          style: const TextStyle(color: Colors.white, fontSize: 12.0),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          _showUserActionMenu(context, user);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to user details
                    context.push('/admin/users/${user['id']}');
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildContentTab() {
    final theme = Theme.of(context);
    
    // Mock content data
    final contentItems = [
      {'id': '1', 'title': 'Beach Sunset', 'seller': 'John Doe', 'type': 'image', 'status': 'approved', 'price': 5.99},
      {'id': '2', 'title': 'City Timelapse', 'seller': 'Alice Brown', 'type': 'video', 'status': 'pending', 'price': 12.99},
      {'id': '3', 'title': 'Abstract Art', 'seller': 'Bob Johnson', 'type': 'image', 'status': 'approved', 'price': 7.50},
      {'id': '4', 'title': 'Nature Sounds', 'seller': 'Jane Smith', 'type': 'audio', 'status': 'rejected', 'price': 3.99},
      {'id': '5', 'title': 'Mountain View', 'seller': 'John Doe', 'type': 'image', 'status': 'approved', 'price': 9.99},
    ];
    
    return Column(
      children: [
        // Search and filter bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search content...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                onSelected: (value) {
                  // Handle filter selection
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'all', child: Text('All Content')),
                  const PopupMenuItem(value: 'images', child: Text('Images Only')),
                  const PopupMenuItem(value: 'videos', child: Text('Videos Only')),
                  const PopupMenuItem(value: 'audio', child: Text('Audio Only')),
                  const PopupMenuItem(value: 'pending', child: Text('Pending Approval')),
                ],
              ),
            ],
          ),
        ),
        
        // Content list
        Expanded(
          child: ListView.builder(
            itemCount: contentItems.length,
            itemBuilder: (context, index) {
              final content = contentItems[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getContentTypeColor(content['type'].toString()),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      _getContentTypeIcon(content['type'].toString()),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(content['title'].toString()),
                  subtitle: Text('${content['seller']} • \$${content['price']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: _getStatusColor(content['status'].toString()),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        _capitalizeString(content['status'].toString()),
                          style: const TextStyle(color: Colors.white, fontSize: 12.0),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          _showContentActionMenu(context, content);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to content details
                    context.push('/admin/content/${content['id']}');
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24.0),
              const SizedBox(width: 8.0),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLegendItem(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 16.0,
          height: 16.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8.0),
        Text(
          '$label: $value',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32.0, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8.0),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showQuickActionsMenu(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isSuperAdmin = authService.isSuperAdmin;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Add New User'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/users/add');
              },
            ),
            if (isSuperAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Create Super Admin'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/admin/create-super-admin');
                },
              ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Add New Category'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/categories/add');
              },
            ),
            ListTile(
              leading: const Icon(Icons.announcement),
              title: const Text('Create Announcement'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/announcements/create');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('System Settings'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/settings');
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showUserActionMenu(BuildContext context, Map<String, String> user) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit User'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/users/${user['id']}/edit');
              },
            ),
            ListTile(
              leading: Icon(
                user['status'] == 'active' ? Icons.block : Icons.check_circle,
                color: user['status'] == 'active' ? Colors.red : Colors.green,
              ),
              title: Text(
                user['status'] == 'active' ? 'Suspend User' : 'Activate User',
              ),
              onTap: () {
                Navigator.pop(context);
                // Toggle user status
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User status updated')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete User', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, 'user', user['id']!);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showContentActionMenu(BuildContext context, Map<String, dynamic> content) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (content['status'] == 'pending')
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Approve Content'),
                onTap: () {
                  Navigator.pop(context);
                  // Approve content
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Content approved')),
                  );
                },
              ),
            if (content['status'] == 'pending')
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Reject Content'),
                onTap: () {
                  Navigator.pop(context);
                  // Reject content
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Content rejected')),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/content/${content['id']}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.featured_play_list),
              title: const Text('Feature Content'),
              onTap: () {
                Navigator.pop(context);
                // Feature content
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Content featured')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Content', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, 'content', content['id']);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showDeleteConfirmation(BuildContext context, String itemType, String itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $itemType'),
        content: Text('Are you sure you want to delete this $itemType? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Delete item
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$itemType deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  Color _getRoleColor(String role) {
    switch (role) {
      case 'superAdmin':
        return Colors.purple;
      case 'admin':
        return Colors.red;
      case 'seller':
        return Colors.blue;
      case 'buyer':
      default:
        return Colors.green;
    }
  }
  
  Color _getContentTypeColor(String type) {
    switch (type) {
      case 'video':
        return Colors.red;
      case 'audio':
        return Colors.orange;
      case 'image':
      default:
        return Colors.blue;
    }
  }
  
  IconData _getContentTypeIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.videocam;
      case 'gif':
        return Icons.gif;
      case 'image':
      default:
        return Icons.image;
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
      default:
        return Colors.red;
    }
  }
  
  Widget _buildAITab() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Features Section
          Text(
            'AI Features',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          
          // AI Usage Dashboard
          Card(
            child: ListTile(
              leading: Icon(Icons.analytics, color: theme.colorScheme.primary),
              title: const Text('AI Usage Dashboard'),
              subtitle: const Text('Track AI usage, costs, and set budget limits'),
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => context.push('/ai-usage'),
              ),
            ),
          ),
          
          // Gemini Demo
          Card(
            child: ListTile(
              leading: Icon(Icons.smart_toy, color: theme.colorScheme.primary),
              title: const Text('Gemini AI Demo'),
              subtitle: const Text('Test the Gemini AI integration'),
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => context.push('/gemini-demo'),
              ),
            ),
          ),
          
          const SizedBox(height: 24.0),
          
          // AI Usage Statistics
          Text(
            'AI Usage Statistics',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          
          // Mock AI usage statistics
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total AI Requests',
                  value: '1,250',
                  icon: Icons.api,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Monthly Cost',
                  value: '\$45.75',
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Gemini Requests',
                  value: '850',
                  icon: Icons.smart_toy,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: _buildSummaryCard(
                  title: 'OpenAI Requests',
                  value: '400',
                  icon: Icons.psychology,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24.0),
          
          // AI Settings
          Text(
            'AI Settings',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          
          // AI Settings cards
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Budget Controls',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16.0),
                  ListTile(
                    title: const Text('Monthly Budget Limit'),
                    subtitle: const Text('\$100.00'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {},
                    ),
                  ),
                  ListTile(
                    title: const Text('Alert Threshold'),
                    subtitle: const Text('80% of budget'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {},
                    ),
                  ),
                  ListTile(
                    title: const Text('Auto-disable AI when budget exceeded'),
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16.0),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Default AI Models',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16.0),
                  ListTile(
                    title: const Text('Primary AI Model'),
                    subtitle: const Text('Gemini Pro'),
                    trailing: IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {},
                    ),
                  ),
                  ListTile(
                    title: const Text('Fallback AI Model'),
                    subtitle: const Text('GPT-3.5 Turbo'),
                    trailing: IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}