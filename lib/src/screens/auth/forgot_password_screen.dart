import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../l10n/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
  
  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      await authService.resetPassword(_emailController.text.trim());
      
      if (!mounted) return;
      
      setState(() {
        _emailSent = true;
      });
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reset email: ${e.toString()}'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Icon(
                    Icons.lock_reset,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ).animate().scale(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                  ),
                  const SizedBox(height: 24),
                  
                  if (!_emailSent) ...[  
                    // Title
                    Text(
                      'Forgot Your Password?',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    Text(
                      'Enter your email address and we\'ll send you a link to reset your password.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 400),
                    ),
                    const SizedBox(height: 32),
                    
                    // Email Field
                    CustomTextField(
                      controller: _emailController,
                      hintText: AppLocalizations.of(context)!.translate('email'),
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.translate('emailRequired');
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return AppLocalizations.of(context)!.translate('emailInvalid');
                        }
                        return null;
                      },
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 600),
                    ),
                    const SizedBox(height: 32),
                    
                    // Reset Button
                    CustomButton(
                      text: AppLocalizations.of(context)!.translate('sendResetLink'),
                      isLoading: authService.isLoading,
                      onPressed: _handleResetPassword,
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 800),
                    ),
                  ] else ...[  
                    // Success Message
                    Text(
                      AppLocalizations.of(context)!.translate('resetLinkSent'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      AppLocalizations.of(context)!.translate('resetLinkSentTo'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                    ),
                    const SizedBox(height: 8),
                    
                    Text(
                      _emailController.text.trim(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 400),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      AppLocalizations.of(context)!.translate('checkEmailForInstructions'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 600),
                    ),
                    const SizedBox(height: 32),
                    
                    // Back to Login Button
                    CustomButton(
                      text: AppLocalizations.of(context)!.translate('backToLogin'),
                      onPressed: () => context.go('/login'),
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 800),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Back to Login Link (only shown before email is sent)
                  if (!_emailSent)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate('rememberPassword'),
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            context.go('/login');
                          },
                          child: Text(
                            AppLocalizations.of(context)!.translate('signIn'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 1000),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}