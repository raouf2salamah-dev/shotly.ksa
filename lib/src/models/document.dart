import 'package:cloud_firestore/cloud_firestore.dart';

class Document {
  final String id;
  final Map<String, dynamic> data;
  final String collection;
  final DateTime updatedAt;
  
  Document({
    required this.id,
    required this.data,
    required this.collection,
    required this.updatedAt,
  });
  
  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      data: Map<String, dynamic>.from(json['data']),
      collection: json['collection'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data,
      'collection': collection,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  factory Document.fromFirestore(DocumentSnapshot doc, String collectionName) {
    return Document(
      id: doc.id,
      data: doc.data() as Map<String, dynamic>,
      collection: collectionName,
      updatedAt: (doc.data() as Map<String, dynamic>)['updatedAt'] is Timestamp
          ? ((doc.data() as Map<String, dynamic>)['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}