import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileAvatar extends StatelessWidget {
  final double radius;
  final String? photoUrl;
  final String name;
  final VoidCallback? onTap;
  
  const ProfileAvatar({
    super.key,
    required this.radius,
    this.photoUrl,
    required this.name,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValidUrl = photoUrl != null && photoUrl!.isNotEmpty;
    
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        child: hasValidUrl
            ? ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: CachedNetworkImage(
                  imageUrl: photoUrl!,
                  fit: BoxFit.cover,
                  width: radius * 2,
                  height: radius * 2,
                  placeholder: (context, url) => _buildInitials(),
                  errorWidget: (context, url, error) => _buildInitials(),
                ),
              )
            : _buildInitials(),
      ),
    );
  }
  
  Widget _buildInitials() {
    final initials = name.isNotEmpty
        ? name.split(' ').map((part) => part.isNotEmpty ? part[0] : '').join('')
        : '?';
    
    return Center(
      child: Text(
        initials.length > 2 ? initials.substring(0, 2) : initials,
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}