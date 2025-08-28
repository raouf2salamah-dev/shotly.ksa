// auth_service.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shotly/src/utils/crashlytics_helper.dart';

enum UserRole { buyer, seller, admin, superAdmin }

typedef AppleCredentialGetter = Future<AuthorizationCredentialAppleID> Function(List<AppleIDAuthorizationScopes> scopes);

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final AppleCredentialGetter? _appleCredentialGetter;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore, AppleCredentialGetter? appleCredentialGetter})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _appleCredentialGetter = appleCredentialGetter,
        super() {
    _init();
  }
  User? _user;
  UserRole? _userRole;
  bool _isLoading = false;
  bool _isUserDataLoading = true;

  // Getters
  User? get user => _user;
  User? get currentUser => _user;
  UserRole? get userRole => _userRole;
  bool get isLoading => _isLoading;
  bool get isUserDataLoading => _isUserDataLoading;
  bool get isLoggedIn => _user != null;
  bool get isBuyer => _userRole == UserRole.buyer;
  bool get isSeller => _userRole == UserRole.seller;
  bool get isAdmin => _userRole == UserRole.admin || _userRole == UserRole.superAdmin;
  bool get isSuperAdmin => _userRole == UserRole.superAdmin;


  // Create test superAdmin account
  Future<void> _createTestSuperAdmin() async {
    try {
      debugPrint('Using existing account for raouf2salamah@gmail.com');
    } catch (e) {
      debugPrint('Error with test superAdmin account: $e');
    }
  }

  // Initialize the service
  Future<void> _init() async {
    _setLoading(true);
    await _googleSignIn.initialize();
    await _createTestSuperAdmin();

    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      _isUserDataLoading = true;
      notifyListeners();

      if (user != null) {
        await loadUserRole();
        debugPrint('Before setUserIdentifier in authStateChanges: instance type ${CrashlyticsHelper.instance.runtimeType}');
        await CrashlyticsHelper.setUserIdentifier(user.uid);
        debugPrint('After setUserIdentifier in authStateChanges');
        if (user.email != null) {
          debugPrint('Before setCustomKey in authStateChanges');
          await CrashlyticsHelper.setCustomKey('user_email', user.email!);
          debugPrint('After setCustomKey in authStateChanges');
        }
        debugPrint('Before log in authStateChanges');
        await CrashlyticsHelper.log('User signed in: ${user.uid}');
        debugPrint('After log in authStateChanges');
      } else {
        _userRole = null;
        debugPrint('Before setUserIdentifier empty in authStateChanges');
        debugPrint('Before setUserIdentifier in signOut');
      await CrashlyticsHelper.setUserIdentifier('');
      debugPrint('After setUserIdentifier in signOut');
        debugPrint('After setUserIdentifier empty in authStateChanges');
      }

      _isUserDataLoading = false;
      notifyListeners();
    });

    _setLoading(false);
  }

  // Load user role from Firestore
  Future<void> loadUserRole() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    if (currentUser.email == 'raouf2salamah@gmail.com') {
      _userRole = UserRole.superAdmin;
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(currentUser.uid).get();

      if (doc.exists && doc.data()!.containsKey('role')) {
        final roleStr = doc.data()!['role'] as String;
        final bool isSuperAdmin = doc.data()!['isSuperAdmin'] as bool? ?? false;

        if (isSuperAdmin) {
          _userRole = UserRole.superAdmin;
        } else {
          switch (roleStr) {
            case 'seller':
              _userRole = UserRole.seller;
              break;
            case 'admin':
              _userRole = UserRole.admin;
              break;
            case 'buyer':
              _userRole = UserRole.buyer;
              break;
            default:
              _userRole = UserRole.buyer;
              break;
          }
        }
      } else {
        _userRole = UserRole.buyer;
      }
    } catch (e) {
      debugPrint('Error loading user role: $e');
      _userRole = UserRole.buyer;
    }
  }

  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Register with email and password
  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    bool isSuperAdmin = false,
  }) async {
    try {
      _setLoading(true);
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.updateDisplayName(name);

      String roleStr;
      if (role == UserRole.seller) {
        roleStr = 'seller';
      } else if (role == UserRole.admin || role == UserRole.superAdmin) {
        roleStr = 'admin';
      } else {
        roleStr = 'buyer';
      }

      // Save user role to Firestore immediately after registration
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'role': roleStr,
        'isSuperAdmin': role == UserRole.superAdmin || isSuperAdmin,
        'createdAt': FieldValue.serverTimestamp(),
        'profileImageUrl': '',
      });

      _userRole = isSuperAdmin ? UserRole.superAdmin : role;
      notifyListeners();

      return userCredential.user;
    } catch (e) {
      debugPrint('Error during registration: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // The _init() listener will handle loading the role after sign-in
      return userCredential.user;
    } catch (e) {
      debugPrint('Error during sign in: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      _setLoading(true);
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) {
        _setLoading(false);
        return null;
      }
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': userCredential.user!.displayName,
          'email': userCredential.user!.email,
          'role': 'buyer',
          'createdAt': FieldValue.serverTimestamp(),
          'profileImageUrl': userCredential.user!.photoURL ?? '',
        });
        _userRole = UserRole.buyer;
      } 
      // The _init() listener will handle loading the role for existing users
      return userCredential.user;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with Apple
  Future<User?> signInWithApple() async {
    try {
      _setLoading(true);
      final appleCredentialGetter = _appleCredentialGetter ?? SignInWithApple.getAppleIDCredential;
      final result = await appleCredentialGetter([AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName]);
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: result.identityToken,
        accessToken: result.authorizationCode,
      );
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        final fullName = '${result.givenName ?? ''} ${result.familyName ?? ''}'.trim();
        // Save default role for new users
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': fullName.isNotEmpty ? fullName : 'Apple User',
          'email': userCredential.user!.email,
          'role': 'buyer',
          'createdAt': FieldValue.serverTimestamp(),
          'profileImageUrl': userCredential.user!.photoURL ?? '',
        });
        _userRole = UserRole.buyer;
      } 
      // The _init() listener will handle loading the role for existing users
      return userCredential.user;
    } catch (e) {
      debugPrint('Error signing in with Apple: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Switch user role
  Future<void> switchRole(UserRole newRole) async {
    if (_user == null) return;
    _setLoading(true);

    try {
      String roleStr;
      if (newRole == UserRole.seller) {
        roleStr = 'seller';
      } else if (newRole == UserRole.admin || newRole == UserRole.superAdmin) {
        roleStr = 'admin';
      } else {
        roleStr = 'buyer';
      }

      await _firestore.collection('users').doc(_user!.uid).update({
        'role': roleStr,
        'isSuperAdmin': newRole == UserRole.superAdmin,
      });

      _userRole = newRole;
      notifyListeners();
    } catch (e) {
      debugPrint('Error switching role: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Create a super admin user
  Future<User?> createSuperAdmin({
    required String email,
    required String password,
    required String name,
  }) async {
    return registerWithEmailAndPassword(
      email: email,
      password: password,
      name: name,
      role: UserRole.admin,
      isSuperAdmin: true,
    );
  }

  // Promote user to super admin
  Future<void> promoteToSuperAdmin(String userId) async {
    _setLoading(true);
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': 'admin',
        'isSuperAdmin': true,
      });

      if (_user != null && _user!.uid == userId) {
        _userRole = UserRole.superAdmin;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error promoting user to super admin: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Revoke super admin privileges
  Future<void> revokeSuperAdmin(String userId) async {
    _setLoading(true);
    try {
      await _firestore.collection('users').doc(userId).update({
        'isSuperAdmin': false,
      });

      if (_user != null && _user!.uid == userId) {
        _userRole = UserRole.admin;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error revoking super admin privileges: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      if (_user != null) {
        debugPrint('Before log in signOut');
        await CrashlyticsHelper.log('User signed out: ${_user!.uid}');
        debugPrint('After log in signOut');
      }
      await _auth.signOut();
      _userRole = null;
      await CrashlyticsHelper.setUserIdentifier('');
    } catch (e) {
      debugPrint('Error signing out: $e');
      debugPrint('Before recordError in signOut');
      await CrashlyticsHelper.recordError(e, StackTrace.current, reason: 'Error during sign out');
      debugPrint('After recordError in signOut');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error resetting password: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<void> updateUserProfile({required String name, File? profileImage}) async {
    if (_user == null) throw Exception('User not logged in');
    _setLoading(true);
    try {
      String? profileImageUrl;
      if (profileImage != null) {
        final storageRef = FirebaseStorage.instance.ref().child('profile_images/${_user!.uid}');
        final uploadTask = storageRef.putFile(profileImage);
        final snapshot = await uploadTask;
        profileImageUrl = await snapshot.ref.getDownloadURL();
      }
      await _user!.updateDisplayName(name);
      final updateData = <String, dynamic>{'name': name};
      if (profileImageUrl != null) {
        updateData['profileImageUrl'] = profileImageUrl;
      }
      await _firestore.collection('users').doc(_user!.uid).update(updateData);
      debugPrint('Before log in updateUserProfile');
      await CrashlyticsHelper.log('User profile updated: ${_user!.uid}');
      debugPrint('After log in updateUserProfile');
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      debugPrint('Before recordError in updateUserProfile');
      await CrashlyticsHelper.recordError(e, StackTrace.current, reason: 'Error during profile update');
      debugPrint('After recordError in updateUserProfile');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update password
  Future<void> updatePassword({required String currentPassword, required String newPassword}) async {
    if (_user == null) throw Exception('User not logged in');
    if (_user!.email == null) throw Exception('User has no email');
    _setLoading(true);
    try {
      final credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: currentPassword,
      );
      await _user!.reauthenticateWithCredential(credential);
      await _user!.updatePassword(newPassword);
      debugPrint('Before log in updatePassword');
      await CrashlyticsHelper.log('User password updated: ${_user!.uid}');
      debugPrint('After log in updatePassword');
    } catch (e) {
      debugPrint('Error updating password: $e');
      debugPrint('Before recordError in updatePassword');
      await CrashlyticsHelper.recordError(e, StackTrace.current, reason: 'Error during password update');
      debugPrint('After recordError in updatePassword');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    if (_user == null) throw Exception('User not logged in');
    _setLoading(true);
    try {
      await _firestore.collection('users').doc(_user!.uid).delete();
      debugPrint('Before log in deleteAccount');
      await CrashlyticsHelper.log('User account deleted: ${_user!.uid}');
      debugPrint('After log in deleteAccount');
      await _user!.delete();
    } catch (e) {
      debugPrint('Error deleting account: $e');
      debugPrint('Before recordError in deleteAccount');
      await CrashlyticsHelper.recordError(e, StackTrace.current, reason: 'Error during account deletion');
      debugPrint('After recordError in deleteAccount');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}