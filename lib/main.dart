import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'src/services/firebase_options.dart';
import 'src/screens/buyer/buyer_home_screen.dart';
import 'src/screens/seller/seller_home_screen.dart';
import 'src/screens/admin/admin_dashboard_screen.dart';
import 'src/services/auth_service.dart';
import 'src/services/content_service.dart';
import 'src/services/analytics_service.dart';
import 'src/services/search_service.dart';
import 'src/services/locale_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Wait for Firebase initialization to complete before running the app
  await initializeFirebase();
  runApp(const MyApp());
}

// Firebase initialization with proper error handling
Future<FirebaseApp?> initializeFirebase() async {
  try {
    // Initialize Firebase with the correct options
    return await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Error initializing Firebase: $e");
    // Return null instead of throwing to allow app to continue
    return null;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _firebaseInitialized = false;
  
  @override
  void initState() {
    super.initState();
    // Check Firebase initialization status
    Firebase.apps.isNotEmpty ? _firebaseInitialized = true : _checkFirebaseStatus();
  }
  
  void _checkFirebaseStatus() {
    // Periodically check if Firebase is initialized
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _firebaseInitialized = Firebase.apps.isNotEmpty;
        });
        if (!_firebaseInitialized) {
          _checkFirebaseStatus();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Always return the app with providers, regardless of Firebase status
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => ContentService()),
        Provider(create: (_) => AnalyticsService()),
        ChangeNotifierProvider(create: (_) => SearchService()),
        ChangeNotifierProvider(create: (_) => LocaleService()),
      ],
      child: MaterialApp(
        title: 'Firebase Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        routes: {
          '/buyer_home_screen': (context) => const BuyerHomeScreen(),
          '/seller_home_screen': (context) => const SellerHomeScreen(),
          '/admin': (context) => const AdminDashboardScreen(),
        },
        home: _firebaseInitialized 
          ? const AuthWrapper() 
          : const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Initializing app...'),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

// Original MyApp class restored

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return const LoginScreen();
          }
          
          // Check user type in Firestore and navigate accordingly
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                final userType = userData?['userType'] as String? ?? 'buyer';
                
                if (userType == 'seller') {
                  return const SellerHomeScreen();
                } else if (userType == 'admin' || userType == 'super_admin') {
                  return const AdminDashboardScreen();
                } else {
                  return const BuyerHomeScreen();
                }
              }
              
              // Default to buyer if no user data found
              return const BuyerHomeScreen();
            },
          );
        }
        
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String _userType = 'buyer'; // Default to buyer

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Sign in with email and password
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Determine route based on Firestore userType
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userType = (userDoc.data()?['userType'] as String?) ?? 'buyer';
      String route = '/buyer';
      if (userType == 'seller') route = '/seller';
      else if (userType == 'admin' || userType == 'super_admin') route = '/admin';
      Navigator.pushReplacementNamed(context, route);
      // Remove the following block:
      // if (!mounted) return;
      // if (_userType == 'seller') {
      //   Navigator.pushReplacementNamed(context, '/seller_home_screen');
      // } else {
      //   Navigator.pushReplacementNamed(context, '/buyer_home_screen');
      // }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Create user with email and password
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Store user type in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': _emailController.text.trim(),
        'userType': _userType,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Determine route based on Firestore userType
      final user = userCredential.user!;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userType = (userDoc.data()?['userType'] as String?) ?? 'buyer';
      String route = '/buyer';
      if (userType == 'seller') route = '/seller';
      else if (userType == 'admin' || userType == 'super_admin') route = '/admin';
      Navigator.pushReplacementNamed(context, route);
      // Remove the following block:
      // if (!mounted) return;
      // if (_userType == 'seller') {
      //   Navigator.pushReplacementNamed(context, '/seller_home_screen');
      // } else {
      //   Navigator.pushReplacementNamed(context, '/buyer_home_screen');
      // }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade500,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo or Icon
                        Icon(
                          Icons.business_center,
                          size: 80,
                          color: Colors.blue.shade800,
                        ),
                        const SizedBox(height: 16),
                        
                        // Title
                        const Text(
                          'Business Portal',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Subtitle
                        Text(
                          'Sign in to access your account',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // User Type Selection
                        Row(
                          children: [
                            const Text('I am a: ', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'buyer',
                                    label: Text('Buyer'),
                                    icon: Icon(Icons.shopping_cart),
                                  ),
                                  ButtonSegment(
                                    value: 'seller',
                                    label: Text('Seller'),
                                    icon: Icon(Icons.store),
                                  ),
                                  ButtonSegment(
                                    value: 'admin',
                                    label: Text('Admin'),
                                    icon: Icon(Icons.admin_panel_settings),
                                  ),
                                ],
                                selected: {_userType},
                                onSelectionChanged: (Set<String> selection) {
                                  setState(() {
                                    _userType = selection.first;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Error Message
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade800),
                            ),
                          ),
                        
                        // Sign In Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade800,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Sign In', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _signUp,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.blue.shade800),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Create Account', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final User user;
  
  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You are logged in!',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            Text(
              'User ID: ${user.uid}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}