import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../services/auth_service.dart';
import '../../services/analytics_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/social_auth_button.dart';
import '../../l10n/app_localizations.dart';

class LoginScreenAr extends StatefulWidget {
  const LoginScreenAr({super.key});

  @override
  State<LoginScreenAr> createState() => _LoginScreenArState();
}

class _LoginScreenArState extends State<LoginScreenAr> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  // Handle login with email and password
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    
    try {
      await authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // Log login event
      await analyticsService.logLogin(method: 'email');
      
      if (!mounted) return;
      
      // Navigate based on user role
      if (authService.isAdmin) {
        context.go('/admin');
      } else if (authService.isSeller) {
        context.go('/seller');
      } else {
        context.go('/buyer');
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تسجيل الدخول: ${e.toString()}'))
      );
    }
  }
  
  // Handle login with Google
  Future<void> _handleGoogleLogin() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    
    try {
      await authService.signInWithGoogle();
      
      // Log login event
      await analyticsService.logLogin(method: 'google');
      
      if (!mounted) return;
      
      // Navigate based on user role
      if (authService.isAdmin) {
        context.go('/admin');
      } else if (authService.isSeller) {
        context.go('/seller');
      } else {
        context.go('/buyer');
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تسجيل الدخول بواسطة جوجل: ${e.toString()}'))
      );
    }
  }
  
  // Handle login with Apple
  Future<void> _handleAppleLogin() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    
    try {
      await authService.signInWithApple();
      
      // Log login event
      await analyticsService.logLogin(method: 'apple');
      
      if (!mounted) return;
      
      // Navigate based on user role
      if (authService.isAdmin) {
        context.go('/admin');
      } else if (authService.isSeller) {
        context.go('/seller');
      } else {
        context.go('/buyer');
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تسجيل الدخول بواسطة آبل: ${e.toString()}'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo and welcome text
                    const Icon(
                      Icons.camera_alt,
                      size: 64,
                      color: Colors.blue,
                    ).animate().fadeIn(duration: 600.ms).slideY(
                      begin: -0.2,
                      end: 0,
                      curve: Curves.easeOutQuad,
                      duration: 600.ms,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'مرحباً بعودتك!',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                    const SizedBox(height: 8),
                    Text(
                      'سجل دخولك للوصول إلى حسابك',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                    const SizedBox(height: 32),
                    
                    // Email field
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'البريد الإلكتروني',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال البريد الإلكتروني';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'الرجاء إدخال بريد إلكتروني صحيح';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
                    const SizedBox(height: 16),
                    
                    // Password field
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'كلمة المرور',
                      prefixIcon: Icons.lock_outline,
                      obscureText: !_isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال كلمة المرور';
                        }
                        if (value.length < 6) {
                          return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 800.ms, duration: 600.ms),
                    const SizedBox(height: 16),
                    
                    // Remember me and forgot password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                            ),
                            const Text('تذكرني'),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to forgot password screen
                          },
                          child: const Text('نسيت كلمة المرور؟'),
                        ),
                      ],
                    ).animate().fadeIn(delay: 1000.ms, duration: 600.ms),
                    const SizedBox(height: 24),
                    
                    // Login button
                    CustomButton(
                      text: 'تسجيل الدخول',
                      onPressed: _handleLogin,
                    ).animate().fadeIn(delay: 1200.ms, duration: 600.ms),
                    const SizedBox(height: 24),
                    
                    // Or continue with
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'أو استمر باستخدام',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ).animate().fadeIn(delay: 1400.ms, duration: 600.ms),
                    const SizedBox(height: 24),
                    
                    // Social login buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SocialAuthButton(
                          icon: FontAwesomeIcons.google,
                          onPressed: _handleGoogleLogin,
                        ),
                        const SizedBox(width: 16),
                        SocialAuthButton(
                          icon: FontAwesomeIcons.apple,
                          onPressed: _handleAppleLogin,
                        ),
                        const SizedBox(width: 16),
                        SocialAuthButton(
                          icon: FontAwesomeIcons.facebook,
                          onPressed: () {
                            // Handle Facebook login
                          },
                        ),
                      ],
                    ).animate().fadeIn(delay: 1600.ms, duration: 600.ms),
                    const SizedBox(height: 32),
                    
                    // Don't have an account
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('ليس لديك حساب؟'),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: const Text('إنشاء حساب'),
                        ),
                      ],
                    ).animate().fadeIn(delay: 1800.ms, duration: 600.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}