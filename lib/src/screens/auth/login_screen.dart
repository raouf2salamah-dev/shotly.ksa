import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  final _formKey = GlobalKey<FormState>();

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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/images/shotly_logo.svg',
                          width: 120,
                          height: 120,
                        ).animate().fadeIn(duration: 600.ms).slideY(),
                        const SizedBox(height: 16),
                        Text('تسجيل الدخول إلى Shotly', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)).animate().fadeIn(delay: 300.ms),
                        const SizedBox(height: 32),
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
                        ).animate().fadeIn(delay: 400.ms).slideX(),
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
                          validator: (value) => value!.isEmpty ? 'Please enter your password' : null,
                        ).animate().fadeIn(delay: 500.ms).slideX(),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final authService = Provider.of<AuthService>(context, listen: false);
                              try {
                                await authService.signInWithEmailAndPassword(email: _emailController.text, password: _passwordController.text);
                                if (authService.userRole == UserRole.seller) context.go('/seller');
                                else if (authService.userRole == UserRole.buyer) context.go('/buyer');
                                else if (authService.userRole == UserRole.admin || authService.userRole == UserRole.superAdmin) context.go('/admin');
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل تسجيل الدخول: $e')));
                              }
                            }
                          },
                          child: Text('تسجيل الدخول', style: TextStyle(color: Colors.blue)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ).animate().fadeIn(delay: 600.ms),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: Text('نسيت كلمة المرور؟', style: TextStyle(color: Colors.white)),
                        ).animate().fadeIn(delay: 700.ms),
                        const SizedBox(height: 24),
                        Text('أو قم بالتسجيل باستخدام', style: TextStyle(color: Colors.white)).animate().fadeIn(delay: 800.ms),
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
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل تسجيل الدخول باستخدام Google: $e')));
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                            side: BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ).animate().fadeIn(delay: 900.ms),
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
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل تسجيل الدخول باستخدام Apple: $e')));
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(double.infinity, 50),
                              side: BorderSide(color: Colors.white),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                          ).animate().fadeIn(delay: 1000.ms),
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