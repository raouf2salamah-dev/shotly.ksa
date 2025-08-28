import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const String routeName = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      delegates: [GlobalMaterialLocalizations.delegate],
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade300, Colors.blue.shade100],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/images/shotly_logo.svg',
                            width: 120,
                            height: 120,
                          ).animate().fadeIn(duration: 600.ms).slideY(),
                          const SizedBox(height: 16),
                          Text('إنشاء حساب في Shotly', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)).animate().fadeIn(delay: 300.ms),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'الاسم',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                            ),
                            textDirection: TextDirection.ltr,
                            validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                          ).animate().fadeIn(delay: 400.ms).slideX(),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'البريد الإلكتروني',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textDirection: TextDirection.ltr,
                            validator: (value) => value!.isEmpty ? 'Please enter your email' : null,
                          ).animate().fadeIn(delay: 500.ms).slideX(),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'كلمة المرور',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                            ),
                            obscureText: true,
                            textDirection: TextDirection.ltr,
                            validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
                          ).animate().fadeIn(delay: 600.ms).slideX(),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'تأكيد كلمة المرور',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                            ),
                            obscureText: true,
                            textDirection: TextDirection.ltr,
                            validator: (value) => value != _passwordController.text ? 'Passwords do not match' : null,
                          ).animate().fadeIn(delay: 700.ms).slideX(),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                final authService = Provider.of<AuthService>(context, listen: false);
                                try {
                                  await authService.registerWithEmailAndPassword(
                                    email: _emailController.text,
                                    password: _passwordController.text,
                                    name: _nameController.text,
                                    role: UserRole.buyer,
                                  );
                                  if (authService.userRole == UserRole.seller) context.go('/seller');
                                  else if (authService.userRole == UserRole.buyer) context.go('/buyer');
                                  else if (authService.userRole == UserRole.admin || authService.userRole == UserRole.superAdmin) context.go('/admin');
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التسجيل: $e')));
                                }
                              }
                            },
                            child: Text('إنشاء حساب', style: TextStyle(color: Colors.blue)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              minimumSize: Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                          ).animate().fadeIn(delay: 800.ms),
                          const SizedBox(height: 24),
                          Text('أو قم بالتسجيل باستخدام', style: TextStyle(color: Colors.white)).animate().fadeIn(delay: 900.ms),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            icon: FaIcon(FontAwesomeIcons.google, color: Colors.white),
                            label: Text('المتابعة باستخدام Google', style: TextStyle(color: Colors.white)),
                            onPressed: () async {
                              final authService = Provider.of<AuthService>(context, listen: false);
                              try {
                                await authService.signInWithGoogle();
                                if (authService.userRole == UserRole.seller) context.go('/seller');
                                else if (authService.userRole == UserRole.buyer) context.go('/buyer');
                                else if (authService.userRole == UserRole.admin || authService.userRole == UserRole.superAdmin) context.go('/admin');
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التسجيل باستخدام Google: $e')));
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(double.infinity, 50),
                              side: BorderSide(color: Colors.white),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                          ).animate().fadeIn(delay: 1000.ms),
                          if (Theme.of(context).platform == TargetPlatform.iOS) const SizedBox(height: 16),
                          if (Theme.of(context).platform == TargetPlatform.iOS)
                            OutlinedButton.icon(
                              icon: FaIcon(FontAwesomeIcons.apple, color: Colors.white),
                              label: Text('المتابعة باستخدام Apple', style: TextStyle(color: Colors.white)),
                              onPressed: () async {
                                final authService = Provider.of<AuthService>(context, listen: false);
                                try {
                                  await authService.signInWithApple();
                                  if (authService.userRole == UserRole.seller) context.go('/seller');
                                  else if (authService.userRole == UserRole.buyer) context.go('/buyer');
                                  else if (authService.userRole == UserRole.admin || authService.userRole == UserRole.superAdmin) context.go('/admin');
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التسجيل باستخدام Apple: $e')));
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(double.infinity, 50),
                                side: BorderSide(color: Colors.white),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                            ).animate().fadeIn(delay: 1100.ms),
                          const SizedBox(height: 16),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'لديك حساب بالفعل؟ ',
                                  style: TextStyle(color: Colors.white),
                                ),
                                TextSpan(
                                  text: 'تسجيل الدخول',
                                  style: TextStyle(color: Colors.white, decoration: TextDecoration.underline),
                                  recognizer: TapGestureRecognizer()..onTap = () => context.push('/login'),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 1200.ms),
                        ],
                      ),
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