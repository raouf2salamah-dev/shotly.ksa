import 'package:flutter/material.dart';

/// A widget that provides custom page transitions using AnimatedSwitcher
/// This can be used for smoother transitions between screens or widgets
class CustomPageTransition extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Widget? placeholder;
  final Curve curve;

  const CustomPageTransition({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.placeholder,
    this.curve = Curves.easeInOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// A widget that provides a fade transition between two screens
class FadePageTransition extends StatelessWidget {
  final Widget child;
  final Duration duration;
  
  const FadePageTransition({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: child,
    );
  }
}

/// A widget that provides a slide transition between two screens
class SlidePageTransition extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Offset beginOffset;
  
  const SlidePageTransition({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.beginOffset = const Offset(1.0, 0.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      },
      child: child,
    );
  }
}