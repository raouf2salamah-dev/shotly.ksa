import 'package:flutter/material.dart';

class SocialAuthButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;
  
  const SocialAuthButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(16.0),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light
                ? Colors.white
                : Colors.grey.shade800,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: theme.brightness == Brightness.light
                  ? Colors.grey.shade300
                  : Colors.grey.shade700,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.brightness == Brightness.light
                    ? Colors.grey.shade200
                    : Colors.black12,
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            width: 60.0,
            height: 60.0,
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    height: 24.0,
                    width: 24.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    size: 24.0,
                    color: theme.brightness == Brightness.light
                        ? Colors.black87
                        : Colors.white,
                  ),
          ),
        ),
      ),
    );
  }
}