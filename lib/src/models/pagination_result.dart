import 'package:cloud_firestore/cloud_firestore.dart';

class PaginationResult<T> {
  final List<T> items;
  final String? lastDocumentId;
  final bool hasMore;

  PaginationResult({
    required this.items,
    this.lastDocumentId,
    required this.hasMore,
  });

  factory PaginationResult.empty() {
    return PaginationResult<T>(
      items: [],
      lastDocumentId: null,
      hasMore: false,
    );
  }

  static PaginationResult<T> fromQuerySnapshot<T>(
    QuerySnapshot snapshot,
    T Function(DocumentSnapshot) fromFirestore,
  ) {
    final items = snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    final lastDocId = snapshot.docs.isNotEmpty ? snapshot.docs.last.id : null;
    final hasMore = snapshot.docs.length > 0;

    return PaginationResult<T>(
      items: items,
      lastDocumentId: lastDocId,
      hasMore: hasMore,
    );
  }
}