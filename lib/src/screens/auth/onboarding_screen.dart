import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _numPages = 4;

  List<Map<String, dynamic>> _getPages(BuildContext context) {
    final AppLocalizations? localizations = AppLocalizations.of(context);
    
    return [
      {
        'title': localizations?.translate('onboarding_title_1') ?? 'AI at Your Service',
        'description': localizations?.translate('onboarding_desc_1') ?? 'The app uses AI to help you find the best deals quickly and accurately.',
        'svgAsset': 'assets/images/ai.svg',
      },
      {
        'title': localizations?.translate('onboarding_title_2') ?? 'Reliability and Security',
        'description': localizations?.translate('onboarding_desc_2') ?? 'We ensure a safe environment for buying and selling with fraud protection.',
        'svgAsset': 'assets/images/security.svg',
      },
      {
        'title': localizations?.translate('onboarding_title_3') ?? 'Fast and Easy Experience',
        'description': localizations?.translate('onboarding_desc_3') ?? 'From registration to deal completion, everything is designed to save your time.',
        'svgAsset': 'assets/images/easy.svg',
      },
      {
        'title': localizations?.translate('onboarding_title_4') ?? 'Start Now',
        'description': localizations?.translate('onboarding_desc_4') ?? 'Join our community and experience the power of AI in buying and selling.',
        'svgAsset': 'assets/images/start.svg',
      },
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
  }

  void _onNextPage() {
    if (_currentPage < _numPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _markOnboardingComplete();
      context.go('/login');
    }
  }

  void _onSkip() {
    _markOnboardingComplete();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final AppLocalizations? localizations = AppLocalizations.of(context);
    final pages = _getPages(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _onSkip,
                  child: Text(
                    localizations?.translate('onboarding_skip') ?? 'Skip',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _numPages,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(
                    title: pages[index]['title'],
                    description: pages[index]['description'],
                    svgAsset: pages[index]['svgAsset'],
                    theme: theme,
                    size: size,
                  );
                },
              ),
            ),

            // Page indicator and next button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicator
                  Row(
                    children: List.generate(
                      _numPages,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        height: 8.0,
                        width: index == _currentPage ? 24.0 : 8.0,
                        decoration: BoxDecoration(
                          color: index == _currentPage
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ),
                  ),

                  // Next button
                  ElevatedButton(
                    onPressed: _onNextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 12.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: Text(
                      _currentPage < _numPages - 1 
                        ? (localizations?.translate('onboarding_next') ?? 'Next')
                        : (localizations?.translate('onboarding_start') ?? 'Start'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String description,
    required String svgAsset,
    required ThemeData theme,
    required Size size,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          // SVG Image
          Container(
            width: size.width * 0.5,
            height: size.width * 0.5,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: EdgeInsets.all(size.width * 0.1),
              child: SvgPicture.asset(
                svgAsset,
                colorFilter: ColorFilter.mode(
                  theme.colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ).animate().scale(
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 48.0),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
          ).animate().fadeIn(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 200),
              ),
          const SizedBox(height: 16.0),

          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.7),
              height: 1.5,
            ),
          ).animate().fadeIn(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 400),
              ),
        ],
      ),
    ),
    );
  }
}