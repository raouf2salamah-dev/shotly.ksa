import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

class AuthServiceSafe extends ChangeNotifier {
  // Use Flutter's built-in logging instead of logger package
  void _log(String message, {Object? error}) {
    developer.log(message, error: error);
  }
  FirebaseAuth? _auth;
  User? _user;
  bool _isInitialized = false;
  bool _isLoading = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  User? get currentUser => _user;

  // Singleton pattern
  static final AuthServiceSafe _instance = AuthServiceSafe._internal();
  factory AuthServiceSafe() => _instance;

  AuthServiceSafe._internal() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      _auth = FirebaseAuth.instance;
      _user = _auth?.currentUser;
      _isInitialized = true;
      
      // Set up auth state listener
      _auth?.authStateChanges().listen((User? user) {
        _user = user;
        notifyListeners();
      });
    } catch (e) {
      _log('Failed to initialize AuthService', error: e);
      _isInitialized = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    if (_auth == null) {
      _log('Auth is null, cannot sign in');
      return null;
    }

    try {
      _isLoading = true;
      notifyListeners();
      
      final userCredential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _user = userCredential.user;
      return _user;
    } catch (e) {
      _log('Error signing in with email and password', error: e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (_auth == null) {
      _log('Auth is null, cannot sign out');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();
      
      await _auth!.signOut();
      _user = null;
    } catch (e) {
      _log('Error signing out', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}