import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';

class AdminContentManagementScreen extends StatefulWidget {
  const AdminContentManagementScreen({super.key});

  @override
  State<AdminContentManagementScreen> createState() => _AdminContentManagementScreenState();
}

class _AdminContentManagementScreenState extends State<AdminContentManagementScreen> {
  bool _isLoading = false;
  String _searchQuery = '';
  String? _filterType;
  String? _filterStatus;
  
  // Mock content data
  final List<Map<String, dynamic>> _contentItems = [
    {
      'id': '1',
      'title': 'Beach Sunset',
      'description': 'Beautiful sunset at the beach',
      'seller': 'John Doe',
      'sellerId': '1',
      'type': 'image',
      'status': 'approved',
      'price': 5.99,
      'createdAt': DateTime.now().subtract(const Duration(days: 15)),
      'featured': true,
      'downloads': 120,
      'rating': 4.5,
    },
    {
      'id': '2',
      'title': 'City Timelapse',
      'description': 'Stunning timelapse of city skyline',
      'seller': 'Alice Brown',
      'sellerId': '4',
      'type': 'video',
      'status': 'pending',
      'price': 12.99,
      'createdAt': DateTime.now().subtract(const Duration(days: 3)),
      'featured': false,
      'downloads': 0,
      'rating': 0.0,
    },
    {
      'id': '3',
      'title': 'Abstract Art',
      'description': 'Modern abstract digital art',
      'seller': 'Bob Johnson',
      'sellerId': '3',
      'type': 'image',
      'status': 'approved',
      'price': 7.50,
      'createdAt': DateTime.now().subtract(const Duration(days: 45)),
      'featured': false,
      'downloads': 87,
      'rating': 4.2,
    },
    {
      'id': '4',
      'title': 'Nature Sounds',
      'description': 'Relaxing sounds of nature',
      'seller': 'Jane Smith',
      'sellerId': '2',
      'type': 'audio',
      'status': 'rejected',
      'price': 3.99,
      'createdAt': DateTime.now().subtract(const Duration(days: 5)),
      'featured': false,
      'downloads': 0,
      'rating': 0.0,
      'rejectionReason': 'Poor audio quality',
    },
    {
      'id': '5',
      'title': 'Mountain View',
      'description': 'Panoramic view of mountain range',
      'seller': 'John Doe',
      'sellerId': '1',
      'type': 'image',
      'status': 'approved',
      'price': 9.99,
      'createdAt': DateTime.now().subtract(const Duration(days: 60)),
      'featured': true,
      'downloads': 215,
      'rating': 4.8,
    },
  ];

  List<Map<String, dynamic>> get filteredContent {
    return _contentItems.where((content) {
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final title = content['title'] as String;
        final description = content['description'] as String;
        final seller = content['seller'] as String;
        if (!title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
            !description.toLowerCase().contains(_searchQuery.toLowerCase()) &&
            !seller.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }
      
      // Apply type filter
      if (_filterType != null && content['type'] != _filterType) {
        return false;
      }
      
      // Apply status filter
      if (_filterStatus != null && content['status'] != _filterStatus) {
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
          title: const Text('Content Management'),
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
        title: const Text('Content Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                // Refresh content list (would fetch from backend in real app)
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
                _buildContentStats(),
                Expanded(
                  child: _buildContentList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddContentOptions(context);
        },
        child: const Icon(Icons.add),
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
              hintText: 'Search content...',
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
                // Type filters
                _buildFilterChip(
                  label: 'All Types',
                  selected: _filterType == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filterType = null;
                      });
                    }
                  },
                ),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                  label: 'Images',
                  selected: _filterType == 'image',
                  onSelected: (selected) {
                    setState(() {
                      _filterType = selected ? 'image' : null;
                    });
                  },
                ),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                  label: 'Videos',
                  selected: _filterType == 'video',
                  onSelected: (selected) {
                    setState(() {
                      _filterType = selected ? 'video' : null;
                    });
                  },
                ),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                  label: 'Audio',
                  selected: _filterType == 'audio',
                  onSelected: (selected) {
                    setState(() {
                      _filterType = selected ? 'audio' : null;
                    });
                  },
                ),
                const SizedBox(width: 16.0),
                
                // Status filters
                _buildFilterChip(
                  label: 'All Status',
                  selected: _filterStatus == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filterStatus = null;
                      });
                    }
                  },
                ),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                  label: 'Approved',
                  selected: _filterStatus == 'approved',
                  onSelected: (selected) {
                    setState(() {
                      _filterStatus = selected ? 'approved' : null;
                    });
                  },
                ),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                  label: 'Pending',
                  selected: _filterStatus == 'pending',
                  onSelected: (selected) {
                    setState(() {
                      _filterStatus = selected ? 'pending' : null;
                    });
                  },
                ),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                  label: 'Rejected',
                  selected: _filterStatus == 'rejected',
                  onSelected: (selected) {
                    setState(() {
                      _filterStatus = selected ? 'rejected' : null;
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

  Widget _buildContentStats() {
    // Count content by status
    int totalContent = _contentItems.length;
    int approvedContent = _contentItems.where((content) => content['status'] == 'approved').length;
    int pendingContent = _contentItems.where((content) => content['status'] == 'pending').length;
    int rejectedContent = _contentItems.where((content) => content['status'] == 'rejected').length;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                label: 'Total',
                value: totalContent.toString(),
                icon: Icons.collections,
                color: Colors.blue,
              ),
              _buildStatItem(
                label: 'Approved',
                value: approvedContent.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              _buildStatItem(
                label: 'Pending',
                value: pendingContent.toString(),
                icon: Icons.pending,
                color: Colors.orange,
              ),
              _buildStatItem(
                label: 'Rejected',
                value: rejectedContent.toString(),
                icon: Icons.cancel,
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

  Widget _buildContentList() {
    final content = filteredContent;
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    if (content.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64.0, color: Colors.grey),
            const SizedBox(height: 16.0),
            Text(
              'No content found',
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
      itemCount: content.length,
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, index) {
        final item = content[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Content preview
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _getContentTypeColor(item['type']),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4.0),
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getContentTypeIcon(item['type']),
                    color: Colors.white,
                    size: 64.0,
                  ),
                ),
              ),
              
              // Content details
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['title'],
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: _getStatusColor(item['status']),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            item['status'].toString().capitalize(),
                            style: const TextStyle(color: Colors.white, fontSize: 12.0),
                          ),
                        ),
                        if (item['featured'] == true)
                          Container(
                            margin: const EdgeInsets.only(left: 8.0),
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: const Text(
                              'Featured',
                              style: TextStyle(color: Colors.white, fontSize: 12.0),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      item['description'],
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Seller',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                item['seller'],
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
                                'Price',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                currencyFormat.format(item['price']),
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
                                'Type',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                item['type'].toString().capitalize(),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
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
                                _formatDate(item['createdAt']),
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
                                'Downloads',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                item['downloads'].toString(),
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
                                'Rating',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 16.0,
                                    color: item['rating'] > 0 ? Colors.amber : Colors.grey,
                                  ),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    item['rating'] > 0 ? item['rating'].toString() : 'N/A',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Rejection reason if applicable
                    if (item['status'] == 'rejected' && item['rejectionReason'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info, color: Colors.red, size: 16.0),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  'Rejection reason: ${item['rejectionReason']}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.visibility),
                          label: const Text('View'),
                          onPressed: () {
                            context.push('/admin/content/${item['id']}');
                          },
                        ),
                        const SizedBox(width: 8.0),
                        if (item['status'] == 'pending')
                          TextButton.icon(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            label: const Text('Approve', style: TextStyle(color: Colors.green)),
                            onPressed: () {
                              _approveContent(item);
                            },
                          ),
                        if (item['status'] == 'pending')
                          const SizedBox(width: 8.0),
                        if (item['status'] == 'pending')
                          TextButton.icon(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            label: const Text('Reject', style: TextStyle(color: Colors.red)),
                            onPressed: () {
                              _showRejectDialog(item);
                            },
                          ),
                        const SizedBox(width: 8.0),
                        TextButton.icon(
                          icon: Icon(
                            item['featured'] == true ? Icons.star : Icons.star_border,
                            color: item['featured'] == true ? Colors.amber : null,
                          ),
                          label: Text(
                            item['featured'] == true ? 'Unfeature' : 'Feature',
                          ),
                          onPressed: () {
                            _toggleFeatured(item);
                          },
                        ),
                        const SizedBox(width: 8.0),
                        TextButton.icon(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('Delete', style: TextStyle(color: Colors.red)),
                          onPressed: () {
                            _showDeleteConfirmation(item);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _approveContent(Map<String, dynamic> content) {
    // In a real app, this would call an API to approve the content
    setState(() {
      content['status'] = 'approved';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${content['title']} has been approved'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              content['status'] = 'pending';
            });
          },
        ),
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> content) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Content'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16.0),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectContent(content, reasonController.text);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _rejectContent(Map<String, dynamic> content, String reason) {
    // In a real app, this would call an API to reject the content
    setState(() {
      content['status'] = 'rejected';
      content['rejectionReason'] = reason.isNotEmpty ? reason : 'No reason provided';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${content['title']} has been rejected'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              content['status'] = 'pending';
              content.remove('rejectionReason');
            });
          },
        ),
      ),
    );
  }

  void _toggleFeatured(Map<String, dynamic> content) {
    // In a real app, this would call an API to toggle featured status
    setState(() {
      content['featured'] = !(content['featured'] as bool);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          content['featured'] == true
              ? '${content['title']} is now featured'
              : '${content['title']} is no longer featured',
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              content['featured'] = !(content['featured'] as bool);
            });
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content'),
        content: Text(
          'Are you sure you want to delete "${content['title']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteContent(content);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteContent(Map<String, dynamic> content) {
    // In a real app, this would call an API to delete the content
    setState(() {
      _contentItems.remove(content);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${content['title']} has been deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _contentItems.add(content);
            });
          },
        ),
      ),
    );
  }

  void _showAddContentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add New Content',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: const Text('Add Image'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/content/add/image');
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.red),
              title: const Text('Add Video'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/content/add/video');
              },
            ),
            ListTile(
              leading: const Icon(Icons.gif, color: Colors.purple),
              title: const Text('Add GIF'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/content/add/gif');
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Manage Categories'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/categories');
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getContentTypeColor(String type) {
    switch (type) {
      case 'video':
        return Colors.red;
      case 'gif':
        return Colors.purple;
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}