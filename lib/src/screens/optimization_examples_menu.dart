import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OptimizationExamplesMenu extends StatelessWidget {
  const OptimizationExamplesMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Optimization Examples'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildExampleButton(
              context,
              title: 'Optimized Query Example',
              description: 'Demonstrates Firebase query optimization with pagination, caching, and bundle loading',
              route: '/optimized-query-example',
              icon: Icons.storage,
            ),
            const SizedBox(height: 16),
            _buildExampleButton(
              context,
              title: 'Asset Optimization Example',
              description: 'Shows asset compression techniques for different screen densities',
              route: '/asset-optimization-example',
              icon: Icons.image,
            ),
            const SizedBox(height: 16),
            _buildExampleButton(
              context,
              title: 'WebP Conversion Example',
              description: 'Convert PNG/JPG to WebP and generate multiple resolution variants',
              route: '/webp-conversion-example',
              icon: Icons.transform,
            ),
            const SizedBox(height: 16),
            _buildExampleButton(
              context,
              title: 'Asset Preloading Example',
              description: 'Pre-bundles essential images for first-time users',
              route: '/asset-preloading-example',
              icon: Icons.image_search,
            ),
            const SizedBox(height: 16),
            _buildExampleButton(
              context,
              title: 'Loading & Error Handling',
              description: 'Standardized loading indicators and error handling with retry options',
              route: '/loading-error-example',
              icon: Icons.refresh,
            ),
            const SizedBox(height: 16),
            _buildExampleButton(
              context,
              title: 'Simple Cache Demo',
              description: 'Demonstrates lightweight key-value caching with automatic expiration',
              route: '/simple-cache-demo',
              icon: Icons.cached,
            ),
            const SizedBox(height: 16),
            _buildExampleButton(
              context,
              title: 'Favorites Demo',
              description: 'Demonstrates using SimpleCacheService for managing user favorites',
              route: '/favorites-demo',
              icon: Icons.favorite,
            ),
            const SizedBox(height: 16),
            _buildExampleButton(
              context,
              title: 'Heavy Feature Example',
              description: 'Demonstrates deferred loading of heavy feature modules',
              route: '/heavy-feature-example',
              icon: Icons.memory,
            ),
            const SizedBox(height: 16),
            _buildExampleButton(
              context,
              title: 'Deferred Media Demo',
              description: 'Demonstrates deferred loading of media packages (image_picker, file_picker, video_player)',
              route: '/media-demo',
              icon: Icons.perm_media,
            ),
            const SizedBox(height: 16),
            _buildExampleButton(
              context,
              title: 'Upload Screen',
              description: 'Demonstrates validated media uploads with size and content restrictions',
              route: '/upload-screen',
              icon: Icons.upload_file,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Optimization Examples',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'These examples demonstrate best practices for optimizing Flutter applications with Firebase:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildBulletPoint('Pagination with ListView.builder'),
            _buildBulletPoint('Optimized Firestore queries with limits and caching'),
            _buildBulletPoint('Asset compression techniques'),
            _buildBulletPoint('WebP conversion and multi-resolution variants'),
            _buildBulletPoint('Bundle loading for frequently accessed data'),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildExampleButton(BuildContext context, {
    required String title,
    required String description,
    required String route,
    required IconData icon,
  }) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: () => context.push(route),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}