import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
// Using UserRole from auth_service.dart only

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  bool _isLoading = false;
  String _searchQuery = '';
  UserRole? _filterRole;
  bool _showSuspended = false;
  bool _showSuperAdmins = false;
  
  // Mock user data for demonstration
  final List<Map<String, dynamic>> _users = [
    {
      'id': '1',
      'name': 'John Super Admin',
      'email': 'john@example.com',
      'role': UserRole.superAdmin,
      'status': 'active',
      'createdAt': DateTime.now().subtract(const Duration(days: 365)),
      'lastActive': DateTime.now().subtract(const Duration(minutes: 5)),
    },
    {
      'id': '2',
      'name': 'Jane Admin',
      'email': 'jane@example.com',
      'role': UserRole.admin,
      'status': 'active',
      'createdAt': DateTime.now().subtract(const Duration(days: 180)),
      'lastActive': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'id': '3',
      'name': 'Bob Seller',
      'email': 'bob@example.com',
      'role': UserRole.seller,
      'status': 'active',
      'createdAt': DateTime.now().subtract(const Duration(days: 90)),
      'lastActive': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'id': '4',
      'name': 'Raouf Salamah',
      'email': 'raouf2salamah@gmail.com',
      'role': UserRole.superAdmin,
      'status': 'active',
      'createdAt': DateTime.now().subtract(const Duration(days: 30)),
      'lastActive': DateTime.now(),
    },
    {
      'id': '5',
      'name': 'Alice Buyer',
      'email': 'alice@example.com',
      'role': UserRole.buyer,
      'status': 'active',
      'createdAt': DateTime.now().subtract(const Duration(days: 270)),
      'lastActive': DateTime.now().subtract(const Duration(days: 30)),
    },
    {
      'id': '6',
      'name': 'Charlie Admin',
      'email': 'charlie@example.com',
      'role': UserRole.admin,
      'status': 'suspended',
      'createdAt': DateTime.now().subtract(const Duration(days: 120)),
      'lastActive': DateTime.now().subtract(const Duration(days: 15)),
    },
  ];

  List<Map<String, dynamic>> get filteredUsers {
    return _users.where((user) {
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final name = user['name'] as String;
        final email = user['email'] as String;
        if (!name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
            !email.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }
      
      // Apply role filter
      if (_filterRole != null && user['role'] != _filterRole) {
        return false;
      }
      
      // Apply status filter
      if (_showSuspended && user['status'] != 'suspended') {
        return false;
      } else if (!_showSuspended && user['status'] == 'suspended') {
        return false;
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    
    // Check if user is admin
    if (!authService.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
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
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                // Refresh user list (would fetch from backend in real app)
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchAndFilterBar(),
                _buildUserStats(),
                Expanded(
                  child: _buildUserList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/admin/users/add');
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search users by name or email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 8.0),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All Users',
                  selected: _filterRole == null && !_showSuspended && !_showSuperAdmins,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filterRole = null;
                        _showSuspended = false;
                        _showSuperAdmins = false;
                      });
                    }
                  },
                ),
                const SizedBox(width: 8.0),
                if (Provider.of<AuthService>(context, listen: false).isSuperAdmin)
                  _buildFilterChip(
                    label: 'Super Admins',
                    selected: _filterRole == UserRole.superAdmin,
                    onSelected: (selected) {
                      setState(() {
                        _filterRole = selected ? UserRole.superAdmin : null;
                      });
                    },
                  ),
                if (Provider.of<AuthService>(context, listen: false).isSuperAdmin)
                  const SizedBox(width: 8.0),
                _buildFilterChip(
                  label: 'Admins',
                  selected: _filterRole == UserRole.admin,
                  onSelected: (selected) {
                    setState(() {
                      _filterRole = selected ? UserRole.admin : null;
                    });
                  },
                ),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                  label: 'Sellers',
                  selected: _filterRole == UserRole.seller,
                  onSelected: (selected) {
                    setState(() {
                      _filterRole = selected ? UserRole.seller : null;
                    });
                  },
                ),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                  label: 'Buyers',
                  selected: _filterRole == UserRole.buyer,
                  onSelected: (selected) {
                    setState(() {
                      _filterRole = selected ? UserRole.buyer : null;
                    });
                  },
                ),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                  label: 'Suspended',
                  selected: _showSuspended,
                  onSelected: (selected) {
                    setState(() {
                      _showSuspended = selected;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildUserStats() {
    // Count users by role
    int totalUsers = _users.length;
    int activeUsers = _users.where((user) => user['status'] == 'active').length;
    int suspendedUsers = _users.where((user) => user['status'] == 'suspended').length;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                label: 'Total Users',
                value: totalUsers.toString(),
                icon: Icons.people,
                color: Colors.blue,
              ),
              _buildStatItem(
                label: 'Active',
                value: activeUsers.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              _buildStatItem(
                label: 'Suspended',
                value: suspendedUsers.toString(),
                icon: Icons.block,
                color: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24.0),
        const SizedBox(height: 4.0),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildUserList() {
    final users = filteredUsers;
    
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64.0, color: Colors.grey),
            const SizedBox(height: 16.0),
            Text(
              'No users found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: users.length,
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getRoleColor(user['role']),
                      child: Text(
                        user['name'][0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['name'],
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user['email'],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: user['status'] == 'active' ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        user['status'].toString().capitalize(),
                        style: const TextStyle(color: Colors.white, fontSize: 12.0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Role',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            _getRoleText(user['role']),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Created',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            _formatDate(user['createdAt']),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Last Active',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            _formatTimeAgo(user['lastActive']),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      onPressed: () {
                        context.push('/admin/users/${user['id']}/edit');
                      },
                    ),
                    const SizedBox(width: 8.0),
                    if (user['role'] == UserRole.admin && Provider.of<AuthService>(context, listen: false).isSuperAdmin)
                      TextButton.icon(
                        icon: const Icon(Icons.star, color: Colors.purple),
                        label: const Text('Make Super Admin', style: TextStyle(color: Colors.purple)),
                        onPressed: () {
                          _promoteTosuperAdmin(user);
                        },
                      ),
                    if (user['role'] == UserRole.superAdmin && Provider.of<AuthService>(context, listen: false).isSuperAdmin && user['id'] != Provider.of<AuthService>(context, listen: false).user?.uid)
                      TextButton.icon(
                        icon: const Icon(Icons.star_border, color: Colors.red),
                        label: const Text('Revoke Super Admin', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          _revokeSuperAdmin(user);
                        },
                      ),
                    const SizedBox(width: 8.0),
                    TextButton.icon(
                      icon: Icon(
                        user['status'] == 'active' ? Icons.block : Icons.check_circle,
                        color: user['status'] == 'active' ? Colors.red : Colors.green,
                      ),
                      label: Text(
                        user['status'] == 'active' ? 'Suspend' : 'Activate',
                        style: TextStyle(
                          color: user['status'] == 'active' ? Colors.red : Colors.green,
                        ),
                      ),
                      onPressed: () {
                        _toggleUserStatus(user);
                      },
                    ),
                    const SizedBox(width: 8.0),
                    TextButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        _showDeleteConfirmation(user);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleUserStatus(Map<String, dynamic> user) {
    // In a real app, this would call an API to update the user's status
    setState(() {
      user['status'] = user['status'] == 'active' ? 'suspended' : 'active';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          user['status'] == 'active'
              ? 'User has been activated'
              : 'User has been suspended',
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              user['status'] = user['status'] == 'active' ? 'suspended' : 'active';
            });
          },
        ),
      ),
    );
  }
  
  void _promoteTosuperAdmin(Map<String, dynamic> user) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Promote to Super Admin'),
          content: Text('Are you sure you want to promote ${user['name']} to Super Admin? This will give them full control over the system, including the ability to manage other admins.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // In a real app, this would call the AuthService.promoteToSuperAdmin method
                setState(() {
                  user['role'] = UserRole.superAdmin;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${user['name']} has been promoted to Super Admin'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Promote'),
            ),
          ],
        );
      },
    );
  }
  
  void _revokeSuperAdmin(Map<String, dynamic> user) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Revoke Super Admin'),
          content: Text('Are you sure you want to revoke Super Admin privileges from ${user['name']}? They will be downgraded to regular Admin.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // In a real app, this would call the AuthService.revokeSuperAdmin method
                setState(() {
                  user['role'] = UserRole.admin;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Super Admin privileges revoked from ${user['name']}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Revoke'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user['name']}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(user);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteUser(Map<String, dynamic> user) {
    // In a real app, this would call an API to delete the user
    setState(() {
      _users.remove(user);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${user['name']} has been deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _users.add(user);
            });
          },
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Colors.purple;
      case UserRole.admin:
        return Colors.red;
      case UserRole.seller:
        return Colors.blue;
      case UserRole.buyer:
      default:
        return Colors.green;
    }
  }

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.seller:
        return 'Seller';
      case UserRole.buyer:
        return 'Buyer';
      default:
        return 'Unknown';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}