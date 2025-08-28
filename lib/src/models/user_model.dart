import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { buyer, seller, admin, superAdmin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String profileImageUrl;
  final UserRole role;
  final DateTime createdAt;
  final List<String> favorites;
  final List<String> purchases;
  final double earnings;
  
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.profileImageUrl,
    required this.role,
    required this.createdAt,
    required this.favorites,
    required this.purchases,
    required this.earnings,
  });
  
  // Convert UserRole enum to string
  String get roleString {
    switch (role) {
      case UserRole.seller:
        return 'seller';
      case UserRole.admin:
        return 'admin';
      case UserRole.superAdmin:
        return 'admin'; // Still uses 'admin' as role string but with isSuperAdmin flag
      case UserRole.buyer:
      default:
        return 'buyer';
    }
  }
  
  // Check if user is a super admin
  bool get isSuperAdmin => role == UserRole.superAdmin;
  
  // Convert string to UserRole enum
  static UserRole _stringToRole(String role, {bool isSuperAdmin = false}) {
    if (isSuperAdmin) return UserRole.superAdmin;
    
    switch (role) {
      case 'seller':
        return UserRole.seller;
      case 'admin':
        return UserRole.admin;
      case 'buyer':
      default:
        return UserRole.buyer;
    }
  }
  
  // Create a UserModel from a Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    final bool isSuperAdmin = map['isSuperAdmin'] as bool? ?? false;
    
    return UserModel(
      id: id,
      name: map['name'] as String,
      email: map['email'] as String,
      profileImageUrl: map['profileImageUrl'] as String? ?? '',
      role: _stringToRole(map['role'] as String? ?? 'buyer', isSuperAdmin: isSuperAdmin),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      favorites: map['favorites'] != null
          ? List<String>.from(map['favorites'])
          : [],
      purchases: map['purchases'] != null
          ? List<String>.from(map['purchases'])
          : [],
      earnings: map['earnings'] != null
          ? (map['earnings'] as num).toDouble()
          : 0.0,
    );
  }
  
  // Convert a UserModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'role': roleString,
      'isSuperAdmin': role == UserRole.superAdmin,
      'createdAt': Timestamp.fromDate(createdAt),
      'favorites': favorites,
      'purchases': purchases,
      'earnings': earnings,
    };
  }
  
  // Create a copy of this UserModel with optional new values
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    UserRole? role,
    DateTime? createdAt,
    List<String>? favorites,
    List<String>? purchases,
    double? earnings,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      favorites: favorites ?? this.favorites,
      purchases: purchases ?? this.purchases,
      earnings: earnings ?? this.earnings,
    );
  }
  
  // Check if user has favorited a content
  bool hasFavorited(String contentId) {
    return favorites.contains(contentId);
  }
  
  // Check if user has purchased a content
  bool hasPurchased(String contentId) {
    return purchases.contains(contentId);
  }
  
  // Check if user is a seller
  bool get isSeller => role == UserRole.seller;
  
  // Check if user is a buyer
  bool get isBuyer => role == UserRole.buyer;
}