import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/content_model.dart';
import '../utils/crashlytics_helper.dart';

class StripeService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Initialize Stripe with your publishable key
  static Future<void> initialize() async {
    // Using a test publishable key for development
    const publishableKey = 'pk_test_51OqXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
  }
  
  // Create a payment intent on your server and get the client secret
  Future<Map<String, dynamic>> createPaymentIntent(double amount, String currency) async {
    try {
      // In a real app, you would make an API call to your server to create a payment intent
      // For demo purposes, we'll simulate a successful response
      
      // This would typically be done on your backend server for security reasons
      // The server would call Stripe API to create a PaymentIntent and return the client secret
      
      // Simulate a server response
      return {
        'clientSecret': 'pi_simulated_client_secret',
        'ephemeralKey': 'ek_simulated_ephemeral_key',
        'customer': 'cus_simulated_customer_id',
        'publishableKey': Stripe.publishableKey,
      };
    } catch (e) {
      debugPrint('Error creating payment intent: $e');
      rethrow;
    }
  }
  
  // Process a payment for content purchase
  Future<void> processPayment(ContentModel content) async {
    try {
      // Log payment attempt to Crashlytics
      await CrashlyticsHelper.log('Stripe payment attempt for content: ${content.id}');
      await CrashlyticsHelper.setCustomKey('payment_content_title', content.title);
      await CrashlyticsHelper.setCustomKey('payment_amount', content.price.toString());
      
      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        await CrashlyticsHelper.log('Payment failed: User not authenticated');
        throw Exception('User not authenticated');
      }
      
      // Set user identifier for Crashlytics
      await CrashlyticsHelper.setUserIdentifier(currentUser.uid);
      
      // Create a payment intent
      final paymentIntentData = await createPaymentIntent(
        content.price, 
        'USD' // or your preferred currency
      );
      
      // Initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'Shotly',
          customerId: paymentIntentData['customer'],
          paymentIntentClientSecret: paymentIntentData['clientSecret'],
          customerEphemeralKeySecret: paymentIntentData['ephemeralKey'],
        ),
      );
      
      // Present the payment sheet to the user
      await Stripe.instance.presentPaymentSheet();
      
      // If we get here, the payment was successful
      // Update the database to reflect the purchase
      await _recordSuccessfulPurchase(currentUser.uid, content);
      
      // Log successful payment to Crashlytics
      await CrashlyticsHelper.log('Stripe payment successful for content: ${content.id}');
    } on StripeException catch (e) {
      // Handle Stripe-specific exceptions
      debugPrint('Stripe error: ${e.error.localizedMessage}');
      
      // Record error to Crashlytics
      await CrashlyticsHelper.recordError(
        e, 
        StackTrace.current, 
        reason: 'Stripe payment error'
      );
      
      rethrow;
    } catch (e) {
      debugPrint('Error processing payment: $e');
      
      // Record error to Crashlytics
      await CrashlyticsHelper.recordError(
        e, 
        StackTrace.current, 
        reason: 'Error processing payment'
      );
      
      rethrow;
    }
  }
  
  // Record a successful purchase in Firestore
  Future<void> _recordSuccessfulPurchase(String userId, ContentModel content) async {
    try {
      // Update buyer's purchases
      await _firestore.collection('users').doc(userId).update({
        'purchases': FieldValue.arrayUnion([content.id]),
      });
      
      // Update seller's earnings
      await _firestore.collection('users').doc(content.sellerId).update({
        'earnings': FieldValue.increment(content.price),
      });
      
      // Record the transaction
      await _firestore.collection('transactions').add({
        'contentId': content.id,
        'buyerId': userId,
        'sellerId': content.sellerId,
        'amount': content.price,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'completed',
        'paymentMethod': 'stripe',
      });
      
      // Update content purchase count
      await _firestore.collection('content').doc(content.id).update({
        'purchaseCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error recording successful purchase: $e');
      rethrow;
    }
  }
}