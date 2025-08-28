import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../utils/crashlytics_helper.dart';

class EarningsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get earnings summary for a seller
  Future<Map<String, dynamic>> getEarningsSummary({
    required String userId,
    required String period,
  }) async {
    try {
      // Log earnings summary request to Crashlytics
      await CrashlyticsHelper.log('Getting earnings summary');
      await CrashlyticsHelper.setCustomKey('earnings_period', period);
      await CrashlyticsHelper.setUserIdentifier(userId);
      // Calculate the start date based on the selected period
      DateTime startDate;
      final now = DateTime.now();
      
      switch (period) {
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'year':
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        case 'all':
        default:
          startDate = DateTime(2000); // A date far in the past
          break;
      }
      
      // Query transactions for this seller in the given period
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('sellerId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('status', isEqualTo: 'completed')
          .orderBy('date', descending: true)
          .get();
      
      // Convert to transaction models
      final transactions = querySnapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
      
      // Calculate total earnings
      double totalEarnings = 0;
      for (var transaction in transactions) {
        totalEarnings += transaction.amount;
      }
      
      // Create monthly summary for charts
      Map<String, double> monthlySummary = {};
      
      for (var transaction in transactions) {
        final date = transaction.date;
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        
        if (monthlySummary.containsKey(monthKey)) {
          monthlySummary[monthKey] = (monthlySummary[monthKey] ?? 0) + transaction.amount;
        } else {
          monthlySummary[monthKey] = transaction.amount;
        }
      }
      
      final result = {
        'totalEarnings': totalEarnings,
        'transactionCount': transactions.length,
        'transactions': transactions,
      };
      
      // Log successful earnings summary to Crashlytics
      await CrashlyticsHelper.log('Earnings summary retrieved successfully');
      await CrashlyticsHelper.setCustomKey('earnings_total', totalEarnings.toString());
      await CrashlyticsHelper.setCustomKey('earnings_transaction_count', transactions.length.toString());
      
      return result;
    } catch (e) {
      debugPrint('Error getting earnings summary: $e');
      
      // Record error to Crashlytics
      await CrashlyticsHelper.recordError(
        e, 
        StackTrace.current, 
        reason: 'Error getting earnings summary'
      );
      
      rethrow;
    }
  }

  /// Get transaction details
  Future<TransactionModel?> getTransaction(String transactionId) async {
    try {
      // Log transaction retrieval to Crashlytics
      await CrashlyticsHelper.log('Getting transaction details');
      await CrashlyticsHelper.setCustomKey('transaction_id', transactionId);
      final docSnapshot = await _firestore
          .collection('transactions')
          .doc(transactionId)
          .get();
      
      if (docSnapshot.exists) {
        return TransactionModel.fromFirestore(docSnapshot);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting transaction: $e');
      
      // Record error to Crashlytics
      await CrashlyticsHelper.recordError(
        e, 
        StackTrace.current, 
        reason: 'Error getting transaction details'
      );
      
      rethrow;
    }
  }

  /// Get all transactions for a seller
  Future<List<TransactionModel>> getSellerTransactions(String sellerId) async {
    try {
      // Log seller transactions retrieval to Crashlytics
      await CrashlyticsHelper.log('Getting seller transactions');
      await CrashlyticsHelper.setUserIdentifier(sellerId);
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('date', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting seller transactions: $e');
      
      // Record error to Crashlytics
      await CrashlyticsHelper.recordError(
        e, 
        StackTrace.current, 
        reason: 'Error getting seller transactions'
      );
      
      rethrow;
    }
  }

  /// Get all transactions for a buyer
  Future<List<TransactionModel>> getBuyerTransactions(String buyerId) async {
    try {
      // Log buyer transactions retrieval to Crashlytics
      await CrashlyticsHelper.log('Getting buyer transactions');
      await CrashlyticsHelper.setUserIdentifier(buyerId);
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('buyerId', isEqualTo: buyerId)
          .orderBy('date', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting buyer transactions: $e');
      
      // Record error to Crashlytics
      await CrashlyticsHelper.recordError(
        e, 
        StackTrace.current, 
        reason: 'Error getting buyer transactions'
      );
      
      rethrow;
    }
  }

  /// Create a new transaction
  Future<String> createTransaction(TransactionModel transaction) async {
    try {
      // Log transaction creation to Crashlytics
      await CrashlyticsHelper.log('Creating new transaction');
      await CrashlyticsHelper.setCustomKey('transaction_amount', transaction.amount.toString());
      await CrashlyticsHelper.setCustomKey('transaction_content', transaction.contentTitle);
      final docRef = await _firestore
          .collection('transactions')
          .add(transaction.toMap());
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating transaction: $e');
      
      // Record error to Crashlytics
      await CrashlyticsHelper.recordError(
        e, 
        StackTrace.current, 
        reason: 'Error creating transaction'
      );
      
      rethrow;
    }
  }

  /// Update transaction status
  Future<void> updateTransactionStatus(String transactionId, String status) async {
    try {
      // Log transaction status update to Crashlytics
      await CrashlyticsHelper.log('Updating transaction status');
      await CrashlyticsHelper.setCustomKey('transaction_id', transactionId);
      await CrashlyticsHelper.setCustomKey('transaction_status', status);
      await _firestore
          .collection('transactions')
          .doc(transactionId)
          .update({'status': status});
    } catch (e) {
      debugPrint('Error updating transaction status: $e');
      
      // Record error to Crashlytics
      await CrashlyticsHelper.recordError(
        e, 
        StackTrace.current, 
        reason: 'Error updating transaction status'
      );
      
      rethrow;
    }
  }
}