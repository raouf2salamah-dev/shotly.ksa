import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'stripe_service.dart';

import '../utils/crashlytics_helper.dart';

import '../models/content_model.dart';
import '../models/user_model.dart';

class PaymentService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final StripeService _stripeService = StripeService();
  
  Stream<List<ProductDetails>> get productsStream => _productsStream;
  Stream<List<PurchaseDetails>> get purchasesStream => _purchasesStream;
  
  late Stream<List<ProductDetails>> _productsStream;
  late Stream<List<PurchaseDetails>> _purchasesStream;
  
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;
  
  PaymentService() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    // Check if the payment platform is available
    _isAvailable = await _inAppPurchase.isAvailable();
    
    if (_isAvailable) {
      // Set up streams for products and purchases
      _productsStream = Stream.value([]);
      _purchasesStream = _inAppPurchase.purchaseStream;
      
      // Listen to purchase updates
      _purchasesStream.listen(_handlePurchaseUpdates);
    }
    
    // Initialize Stripe
    await StripeService.initialize();
    
    notifyListeners();
  }
  
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle error
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        // Deliver the product and update the database
        _deliverPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        // Handle canceled purchase
      }
      
      // Complete the purchase if it's not pending
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }
  
  Future<void> _deliverPurchase(PurchaseDetails purchaseDetails) async {
    try {
      // Extract content ID from the product ID
      final contentId = _extractContentIdFromProductId(purchaseDetails.productID);
      
      // Log purchase attempt to Crashlytics
      await CrashlyticsHelper.log('Delivering purchase for content: $contentId');
      await CrashlyticsHelper.setCustomKey('purchase_product_id', purchaseDetails.productID);
      
      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        await CrashlyticsHelper.log('Purchase delivery failed: User not authenticated');
        return;
      }
      
      // Set user identifier for Crashlytics
      await CrashlyticsHelper.setUserIdentifier(currentUser.uid);
      
      // Get content details
      final contentDoc = await _firestore.collection('content').doc(contentId).get();
      if (!contentDoc.exists) return;
      
      final content = ContentModel.fromFirestore(contentDoc);
      
      // Update buyer's purchases
      await _firestore.collection('users').doc(currentUser.uid).update({
        'purchases': FieldValue.arrayUnion([contentId]),
      });
      
      // Update seller's earnings
      await _firestore.collection('users').doc(content.sellerId).update({
        'earnings': FieldValue.increment(content.price),
      });
      
      // Record the transaction
      await _firestore.collection('transactions').add({
        'contentId': contentId,
        'buyerId': currentUser.uid,
        'sellerId': content.sellerId,
        'amount': content.price,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'completed',
      });
      
      // Update content purchase count
      await _firestore.collection('content').doc(contentId).update({
        'purchaseCount': FieldValue.increment(1),
      });
      
      // Log successful purchase to Crashlytics
      await CrashlyticsHelper.log('Purchase delivered successfully for content: $contentId');
    } catch (e) {
      debugPrint('Error delivering purchase: $e');
      
      // Record error to Crashlytics
      await CrashlyticsHelper.recordError(
        e, 
        StackTrace.current, 
        reason: 'Error delivering purchase'
      );
    }
  }
  
  String _extractContentIdFromProductId(String productId) {
    // Assuming product IDs are formatted as 'content_[contentId]'
    return productId.replaceFirst('content_', '');
  }
  
  Future<void> purchaseContent(ContentModel content, {String paymentMethod = 'inapp'}) async {
    try {
      if (paymentMethod == 'stripe') {
        // Use Stripe for payment processing
        await _stripeService.processPayment(content);
      } else {
        // Use in-app purchases
        if (!_isAvailable) {
          throw Exception('In-app purchases are not available');
        }
        
        // Create a product ID for the content
        final productId = 'content_${content.id}';
        
        // Query the product details
        final ProductDetailsResponse response = 
            await _inAppPurchase.queryProductDetails({productId});
        
        if (response.notFoundIDs.isNotEmpty) {
          // If the product is not found, create a direct purchase in Firestore
          await _createDirectPurchase(content);
        } else if (response.productDetails.isNotEmpty) {
          // Purchase the product through the store
          final PurchaseParam purchaseParam = 
              PurchaseParam(productDetails: response.productDetails.first);
          await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
        } else {
          throw Exception('Failed to load product details');
        }
      }
    } catch (e) {
      debugPrint('Error purchasing content: $e');
      rethrow;
    }
  }
  
  // Purchase content using Stripe
  Future<void> purchaseWithStripe(ContentModel content) async {
    try {
      await purchaseContent(content, paymentMethod: 'stripe');
    } catch (e) {
      debugPrint('Error purchasing with Stripe: $e');
      rethrow;
    }
  }
  
  Future<void> _createDirectPurchase(ContentModel content) async {
    try {
      // Log direct purchase attempt to Crashlytics
      await CrashlyticsHelper.log('Direct purchase attempt for content: ${content.id}');
      await CrashlyticsHelper.setCustomKey('purchase_content_title', content.title);
      await CrashlyticsHelper.setCustomKey('purchase_amount', content.price.toString());
      
      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        await CrashlyticsHelper.log('Direct purchase failed: User not authenticated');
        throw Exception('User not authenticated');
      }
      
      // Set user identifier for Crashlytics
      await CrashlyticsHelper.setUserIdentifier(currentUser.uid);
      
      // Get buyer's data to check balance
      final buyerDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!buyerDoc.exists) {
        throw Exception('User data not found');
      }
      
      final buyer = UserModel.fromMap(buyerDoc.data()!, buyerDoc.id);
      
      // Check if the content is already purchased
      if (buyer.purchases.contains(content.id)) {
        throw Exception('Content already purchased');
      }
      
      // In a real app, you would check the user's balance or use a payment processor
      // For this demo, we'll simulate a successful purchase
      
      // Update buyer's purchases
      await _firestore.collection('users').doc(currentUser.uid).update({
        'purchases': FieldValue.arrayUnion([content.id]),
      });
      
      // Update seller's earnings
      await _firestore.collection('users').doc(content.sellerId).update({
        'earnings': FieldValue.increment(content.price),
      });
      
      // Record the transaction
      await _firestore.collection('transactions').add({
        'contentId': content.id,
        'buyerId': currentUser.uid,
        'sellerId': content.sellerId,
        'amount': content.price,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'completed',
      });
      
      // Log successful direct purchase to Crashlytics
      await CrashlyticsHelper.log('Direct purchase successful for content: ${content.id}');
      
      // Update content purchase count
      await _firestore.collection('content').doc(content.id).update({
        'purchaseCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error processing direct purchase: $e');
      
      // Record error to Crashlytics
      await CrashlyticsHelper.recordError(
        e, 
        StackTrace.current, 
        reason: 'Error processing direct purchase'
      );
      
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> getTransactionHistory() async {
    try {
      // Log transaction history request to Crashlytics
      await CrashlyticsHelper.log('Getting transaction history');
      
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        await CrashlyticsHelper.log('Transaction history request failed: User not authenticated');
        throw Exception('User not authenticated');
      }
      
      // Set user identifier for Crashlytics
      await CrashlyticsHelper.setUserIdentifier(currentUser.uid);
      
      // Get user role
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        throw Exception('User data not found');
      }
      
      final user = UserModel.fromMap(userDoc.data()!, userDoc.id);
      
      // Query transactions based on user role
      QuerySnapshot transactionsSnapshot;
      if (user.role == UserRole.seller) {
        transactionsSnapshot = await _firestore
            .collection('transactions')
            .where('sellerId', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .get();
      } else {
        transactionsSnapshot = await _firestore
            .collection('transactions')
            .where('buyerId', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .get();
      }
      
      // Process transaction data
      List<Map<String, dynamic>> transactions = [];
      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Get content details
        final contentDoc = await _firestore.collection('content').doc(data['contentId']).get();
        String contentTitle = 'Unknown Content';
        if (contentDoc.exists) {
          contentTitle = contentDoc.data()?['title'] ?? 'Unknown Content';
        }
        
        // Get other user details (buyer or seller)
        final otherUserId = user.role == UserRole.seller ? data['buyerId'] : data['sellerId'];
        final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();
        String otherUserName = 'Unknown User';
        if (otherUserDoc.exists) {
          otherUserName = otherUserDoc.data()?['name'] ?? 'Unknown User';
        }
        
        transactions.add({
          'id': doc.id,
          'contentId': data['contentId'],
          'contentTitle': contentTitle,
          'otherUserId': otherUserId,
          'otherUserName': otherUserName,
          'amount': data['amount'],
          'timestamp': data['timestamp'],
          'status': data['status'],
          'type': user.role == UserRole.seller ? 'sale' : 'purchase',
        });
      }
      
      return transactions;
    } catch (e) {
      debugPrint('Error getting transaction history: $e');
      
      // Record error to Crashlytics
      await CrashlyticsHelper.recordError(
        e, 
        StackTrace.current, 
        reason: 'Error getting transaction history'
      );
      
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> getPayoutInfo() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Get user data
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        throw Exception('User data not found');
      }
      
      final user = UserModel.fromMap(userDoc.data()!, userDoc.id);
      
      // Check if user is a seller
      if (user.role != UserRole.seller) {
        throw Exception('Only sellers can access payout information');
      }
      
      // Get payout methods
      final payoutMethodsDoc = await _firestore
          .collection('payoutMethods')
          .doc(currentUser.uid)
          .get();
      
      List<Map<String, dynamic>> payoutMethods = [];
      if (payoutMethodsDoc.exists) {
        final methods = payoutMethodsDoc.data()?['methods'] as List<dynamic>?;
        if (methods != null) {
          for (var method in methods) {
            payoutMethods.add(method as Map<String, dynamic>);
          }
        }
      }
      
      // Get pending balance
      final pendingBalance = user.earnings;
      
      // Get previous payouts
      final payoutsSnapshot = await _firestore
          .collection('payouts')
          .where('sellerId', isEqualTo: currentUser.uid)
          .orderBy('timestamp', descending: true)
          .get();
      
      List<Map<String, dynamic>> previousPayouts = [];
      for (var doc in payoutsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        previousPayouts.add({
          'id': doc.id,
          'amount': data['amount'],
          'method': data['method'],
          'timestamp': data['timestamp'],
          'status': data['status'],
        });
      }
      
      return {
        'pendingBalance': pendingBalance,
        'payoutMethods': payoutMethods,
        'previousPayouts': previousPayouts,
      };
    } catch (e) {
      debugPrint('Error getting payout info: $e');
      rethrow;
    }
  }
  
  Future<void> requestPayout(double amount, String methodId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Get user data
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        throw Exception('User data not found');
      }
      
      final user = UserModel.fromMap(userDoc.data()!, userDoc.id);
      
      // Check if user is a seller
      if (user.role != UserRole.seller) {
        throw Exception('Only sellers can request payouts');
      }
      
      // Check if amount is valid
      if (amount <= 0) {
        throw Exception('Payout amount must be greater than zero');
      }
      
      // Check if user has enough balance
      if (user.earnings < amount) {
        throw Exception('Insufficient balance for payout');
      }
      
      // Get payout method
      final payoutMethodsDoc = await _firestore
          .collection('payoutMethods')
          .doc(currentUser.uid)
          .get();
      
      if (!payoutMethodsDoc.exists) {
        throw Exception('No payout methods found');
      }
      
      final methods = payoutMethodsDoc.data()?['methods'] as List<dynamic>?;
      if (methods == null || methods.isEmpty) {
        throw Exception('No payout methods found');
      }
      
      Map<String, dynamic>? selectedMethod;
      for (var method in methods) {
        if (method['id'] == methodId) {
          selectedMethod = method as Map<String, dynamic>;
          break;
        }
      }
      
      if (selectedMethod == null) {
        throw Exception('Selected payout method not found');
      }
      
      // Create payout request
      await _firestore.collection('payouts').add({
        'sellerId': currentUser.uid,
        'amount': amount,
        'method': selectedMethod,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      
      // Update user's earnings
      await _firestore.collection('users').doc(currentUser.uid).update({
        'earnings': FieldValue.increment(-amount),
      });
    } catch (e) {
      debugPrint('Error requesting payout: $e');
      rethrow;
    }
  }
  
  Future<void> addPayoutMethod(Map<String, dynamic> methodDetails) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Get user data
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        throw Exception('User data not found');
      }
      
      final user = UserModel.fromMap(userDoc.data()!, userDoc.id);
      
      // Check if user is a seller
      if (user.role != UserRole.seller) {
        throw Exception('Only sellers can add payout methods');
      }
      
      // Generate a unique ID for the method
      final methodId = DateTime.now().millisecondsSinceEpoch.toString();
      methodDetails['id'] = methodId;
      
      // Add or update payout method
      final payoutMethodsDoc = await _firestore
          .collection('payoutMethods')
          .doc(currentUser.uid)
          .get();
      
      if (payoutMethodsDoc.exists) {
        await _firestore.collection('payoutMethods').doc(currentUser.uid).update({
          'methods': FieldValue.arrayUnion([methodDetails]),
        });
      } else {
        await _firestore.collection('payoutMethods').doc(currentUser.uid).set({
          'methods': [methodDetails],
        });
      }
    } catch (e) {
      debugPrint('Error adding payout method: $e');
      rethrow;
    }
  }
  
  Future<void> removePayoutMethod(String methodId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Get payout methods
      final payoutMethodsDoc = await _firestore
          .collection('payoutMethods')
          .doc(currentUser.uid)
          .get();
      
      if (!payoutMethodsDoc.exists) {
        throw Exception('No payout methods found');
      }
      
      final methods = payoutMethodsDoc.data()?['methods'] as List<dynamic>?;
      if (methods == null || methods.isEmpty) {
        throw Exception('No payout methods found');
      }
      
      // Find the method to remove
      Map<String, dynamic>? methodToRemove;
      for (var method in methods) {
        if (method['id'] == methodId) {
          methodToRemove = Map<String, dynamic>.from(method as Map);
          break;
        }
      }
      
      if (methodToRemove == null) {
        throw Exception('Payout method not found');
      }
      
      // Remove the method
      await _firestore.collection('payoutMethods').doc(currentUser.uid).update({
        'methods': FieldValue.arrayRemove([methodToRemove]),
      });
    } catch (e) {
      debugPrint('Error removing payout method: $e');
      rethrow;
    }
  }
}