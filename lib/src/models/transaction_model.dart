import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String buyerId;
  final String sellerId;
  final String contentId;
  final String contentTitle;
  final double amount;
  final DateTime date;
  final String status; // 'completed', 'pending', 'refunded'

  TransactionModel({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.contentId,
    required this.contentTitle,
    required this.amount,
    required this.date,
    required this.status,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      buyerId: map['buyerId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      contentId: map['contentId'] ?? '',
      contentTitle: map['contentTitle'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      status: map['status'] ?? 'completed',
    );
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel.fromMap({
      'id': doc.id,
      ...data,
    });
  }

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'sellerId': sellerId,
      'contentId': contentId,
      'contentTitle': contentTitle,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'status': status,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? buyerId,
    String? sellerId,
    String? contentId,
    String? contentTitle,
    double? amount,
    DateTime? date,
    String? status,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      contentId: contentId ?? this.contentId,
      contentTitle: contentTitle ?? this.contentTitle,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }
}