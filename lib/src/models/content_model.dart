import 'package:cloud_firestore/cloud_firestore.dart';

enum ContentType { image, video, gif }

extension ContentTypeExtension on ContentType {
  static String getDisplayName(ContentType type) {
    switch (type) {
      case ContentType.image:
        return 'Image';
      case ContentType.video:
        return 'Video';
      case ContentType.gif:
        return 'GIF';
      default:
        return 'Unknown';
    }
  }
}

class ContentModel {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final double price;
  final String mediaUrl;
  final String thumbnailUrl;
  final ContentType contentType;
  final List<String> tags;
  final String category;
  final DateTime createdAt;
  final int views;
  final int downloads;
  final int favorites;
  final String sellerName; // Added seller name field
  
  ContentModel({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.contentType,
    required this.tags,
    required this.category,
    required this.createdAt,
    required this.views,
    required this.downloads,
    required this.favorites,
    this.sellerName = '', // Default empty string for seller name
  });
  
  // Convert ContentType enum to string
  String get contentTypeString {
    switch (contentType) {
      case ContentType.image:
        return 'image';
      case ContentType.gif:
        return 'gif';
      case ContentType.video:
        return 'video';
      default:
        return 'image';
    }
  }
  
  // Convert string to ContentType enum
  static ContentType _stringToContentType(String type) {
    switch (type) {
      case 'image':
        return ContentType.image;
      case 'photo': // For backward compatibility
        return ContentType.image;
      case 'gif':
        return ContentType.gif;
      case 'video':
        return ContentType.video;
      // Handle legacy types for backward compatibility
      case 'audio':
      case 'document':
      case 'other':
      default:
        return ContentType.image;
    }
  }
  
  // Get display name for content type
  String get contentTypeDisplayName {
    return ContentTypeExtension.getDisplayName(contentType);
  }
  
  // Create a ContentModel from a Firestore document
  factory ContentModel.fromMap(Map<String, dynamic> map) {
    return ContentModel(
      id: map['id'] as String,
      sellerId: map['sellerId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      mediaUrl: map['mediaUrl'] as String,
      thumbnailUrl: map['thumbnailUrl'] as String,
      contentType: _stringToContentType(map['contentType'] as String),
      tags: List<String>.from(map['tags']),
      category: map['category'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      views: map['views'] as int,
      sellerName: map['sellerName'] as String? ?? '',
      downloads: map['downloads'] as int,
      favorites: map['favorites'] as int,
    );
  }
  
  // Convert a ContentModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'price': price,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'contentType': contentTypeString,
      'tags': tags,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'views': views,
      'downloads': downloads,
      'favorites': favorites,
      'sellerName': sellerName,
    };
  }
  
  // Create a ContentModel from a Firestore document
  factory ContentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ContentModel(
      id: doc.id,
      sellerId: data['sellerId'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      price: (data['price'] as num).toDouble(),
      mediaUrl: data['mediaUrl'] as String,
      thumbnailUrl: data['thumbnailUrl'] as String,
      contentType: _stringToContentType(data['contentType'] as String),
      tags: List<String>.from(data['tags']),
      category: data['category'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      views: data['views'] as int,
      downloads: data['downloads'] as int,
      favorites: data['favorites'] as int,
      sellerName: data['sellerName'] as String? ?? '',
    );
  }
  
  // Create a copy of this ContentModel with optional new values
  ContentModel copyWith({
    String? id,
    String? sellerId,
    String? title,
    String? description,
    double? price,
    String? mediaUrl,
    String? thumbnailUrl,
    ContentType? contentType,
    List<String>? tags,
    String? category,
    DateTime? createdAt,
    int? views,
    int? downloads,
    int? favorites,
    String? sellerName,
  }) {
    return ContentModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      contentType: contentType ?? this.contentType,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      views: views ?? this.views,
      downloads: downloads ?? this.downloads,
      favorites: favorites ?? this.favorites,
      sellerName: sellerName ?? this.sellerName,
    );
  }
}