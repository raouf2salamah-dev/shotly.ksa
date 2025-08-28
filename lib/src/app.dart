import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show
  DefaultMaterialLocalizations,
  DefaultWidgetsLocalizations;
import 'package:flutter/cupertino.dart' show DefaultCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart' show
  GlobalMaterialLocalizations,
  GlobalWidgetsLocalizations,
  GlobalCupertinoLocalizations;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'examples/heavy_feature_example.dart';
import 'examples/webp_conversion_example.dart';
import 'screens/security_examples_menu.dart';
import 'screens/examples/screenshot_protection_demo.dart';
import 'screens/examples/sensitive_data_demo.dart';
import 'screens/examples/inactivity_timeout_demo.dart';
import 'examples/auth_interceptor_example.dart';
import 'examples/signed_api_example.dart';
import 'examples/security_dialog_example.dart';
import 'examples/security_intro_example.dart';
import 'examples/app_initialization_example.dart';
import 'examples/sensitive_screen_dialog_example.dart';
import 'l10n/app_localizations.dart';
import 'widgets/floating_language_toggle.dart';
import 'widgets/translation_debug_widget.dart';
import 'widgets/custom_page_transitions.dart';
import 'utils/lazy_loading_manager.dart';
import 'utils/deep_link_handler.dart';
import 'utils/go_router_observer.dart';
import 'providers/lazy_loading_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/recent_views_provider.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/shared/splash_screen.dart';
import 'screens/shared/terms_of_service_screen.dart';
import 'screens/shared/privacy_policy_screen.dart';
import 'screens/shared/settings_screen.dart';
import 'screens/shared/help_center_page.dart';
import 'screens/shared/contact_support_screen.dart';
import 'screens/shared/hive_cache_demo.dart';
import 'screens/shared/simple_cache_demo.dart';
import 'screens/shared/favorites_demo.dart';
import 'screens/shared/recent_views_demo.dart';
import 'screens/recent_favorites_demo.dart';
import 'screens/buyer/buyer_home_screen.dart';
import 'screens/buyer/content_details_screen.dart';
import 'screens/buyer/search_screen.dart';
import '../tts_test.dart';
import 'screens/buyer/favorites_screen.dart';
import 'screens/buyer/profile_screen.dart';
import 'screens/buyer/recent_views_screen.dart';
import 'screens/seller/seller_home_screen.dart';
import 'screens/seller/upload_content_screen.dart';
import 'screens/seller/analytics_screen.dart';
import 'screens/seller/analytics_page.dart';
import 'screens/seller/manage_content_screen.dart';
import 'screens/seller/earnings_screen.dart';
import 'screens/seller/seller_profile_screen.dart';
import 'screens/seller/seller_ai_assistant.dart';
import 'screens/seller/prompt_cache_demo.dart';
import 'screens/shared/firestore_cache_demo.dart';
import 'screens/gemini_demo_screen.dart';
import 'screens/gemini_chat_demo_screen.dart';
import 'screens/vertex_recommendations_screen.dart';
import 'screens/recommendations_demo_widget.dart';
import 'screens/sync_demo_screen.dart';
import 'examples/optimized_query_example.dart';
import 'examples/asset_optimization_example.dart';
import 'examples/asset_preloading_example.dart';
import 'screens/ai_usage_dashboard.dart';
import 'screens/bundle_download_example.dart';
import 'screens/optimization_examples_menu.dart';
import 'screens/examples/loading_error_example.dart';
import 'screens/shared/transitions_demo_screen.dart';
import 'screens/media_demo_screen.dart';
import 'screens/upload_screen.dart';
// Admin Screens
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_user_management_screen.dart';
import 'screens/admin/admin_content_management_screen.dart';
import 'screens/admin/admin_settings_screen.dart';
import 'screens/admin/create_super_admin_screen.dart';

// Services
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'services/search_service.dart';
import 'services/locale_service.dart';
import 'services/simple_cache_service.dart';
import 'services/recent_views_service.dart';
import 'services/sync_service.dart';
import 'services/security_service.dart';
import 'services/device_security_service.dart';
import 'services/secure_storage_service.dart';
import 'security/security_dialog_manager.dart';
import 'security/security_intro_dialog.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Schedule the security features dialog to be shown after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSecurityFeaturesDialog();
    });
  }
  
  // Show the security features dialog and check device security when the app starts
  void _showSecurityFeaturesDialog() async {
    // Use a delay to ensure the app is fully initialized
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (navigatorKey.currentContext != null) {
        // Show security features dialog
        SecurityService().showNewSecurityFeaturesDialog(navigatorKey.currentContext!);
        SecurityService().checkAndShowSecurityDialog(navigatorKey.currentContext!);
        
        // Check for jailbroken/rooted device
        DeviceSecurityService().checkAndShowWarningIfNeeded(navigatorKey.currentContext!);
        
        // Show security intro dialog only once using SecurityDialogManager
        await SecurityDialogManager.showDialogIfNeeded(
          navigatorKey.currentContext!,
          'security_intro_dialog',
          () => const SecurityIntroDialog(
            title: 'Welcome to Shotly Security',
            features: [
              SecurityFeature(
                icon: Icons.security,
                title: 'Device Integrity',
                description: 'We check if your device is secure and not compromised',
              ),
              SecurityFeature(
                icon: Icons.lock,
                title: 'Secure Storage',
                description: 'Your sensitive data is encrypted and stored securely',
              ),
              SecurityFeature(
                icon: Icons.verified_user,
                title: 'API Protection',
                description: 'All communications with our servers are signed and verified',
              ),
            ],
          ),
        );
      }
    });
  }
  
  // Global navigator key for accessing context anywhere
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => SearchService()),
        ChangeNotifierProvider(create: (_) => LocaleService()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) {
          final cacheService = SimpleCacheService(maxItems: 50);
          // Initialize synchronously for provider
          cacheService.init();
          final recentViewsService = RecentViewsService(cacheService);
          return RecentViewsProvider(recentViewsService);
        }),
      ],
      child: LazyLoadingProvider(
        manager: LazyLoadingManager(),
        child: Consumer2<ThemeService, LocaleService>(
          builder: (context, themeService, localeService, child) {
            return MaterialApp.router(
              title: 'Shotly',
              debugShowCheckedModeBanner: false,
              theme: _buildTheme(Brightness.light),
              darkTheme: _buildTheme(Brightness.dark),
              themeMode: themeService.themeMode,
              routerConfig: _getRouter(),
              locale: localeService.locale, // متغير اللغة الحالي
              supportedLocales: const [
                Locale('en'), // الإنجليزية
                Locale('ar'), // العربية
              ],
              localizationsDelegates: [
                AppLocalizations.delegate, // أضف Localizations delegate الخاص بك هنا لو عندك ملفات ترجمة
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                DefaultMaterialLocalizations.delegate,
                DefaultWidgetsLocalizations.delegate,
                DefaultCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                // Add the floating language toggle button to all screens
                return StreamBuilder<ConnectivityResult>(
                  stream: SyncService().connectivityStream,
                  builder: (context, snapshot) {
                    final isOnline = snapshot.data != ConnectivityResult.none;
                    
                    return Stack(
                      children: [
                        if (!isOnline)
                          Banner(
                            message: 'Offline Mode',
                            location: BannerLocation.topStart,
                            color: Colors.orange,
                            child: child!,
                          )
                        else
                          child!,
                        // Import this at the top: import 'widgets/floating_language_toggle.dart';
                        const FloatingLanguageToggle(),
                        // Add a floating button to navigate to TTS test page
                        Positioned(
                          bottom: 80,
                          right: 16,
                          child: FloatingActionButton(
                            heroTag: 'ttsTestButton',
                            backgroundColor: Colors.purple,
                            onPressed: () {
                              context.go('/tts-test');
                            },
                            child: const Icon(Icons.record_voice_over),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              localeResolutionCallback: (locale, supportedLocales) {
                // Check if the current device locale is supported
                for (var supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode == locale?.languageCode) {
                    return supportedLocale;
                  }
                }
                // If the locale of the device is not supported, use the first one
                // from the list (English, in this case).
                return supportedLocales.first;
              },
            );
          },
        ),
      ),
    );
  }
  
  GoRouter _getRouter() {
  final initialLocation = '/splash';

  return GoRouter(
    initialLocation: initialLocation,
    debugLogDiagnostics: true,
    navigatorKey: _MyAppState.navigatorKey,
    redirect: (context, state) {
      final authService = Provider.of<AuthService>(context);

      // 1. If user is authenticated but their data is still loading,
      // keep them on the splash screen.
      if (authService.isLoggedIn && authService.isUserDataLoading) {
        return '/splash';
      }

      final isLoggedIn = authService.isLoggedIn;
      final isLoginRoute = state.uri.toString() == '/login';
      final isSplashRoute = state.uri.toString() == '/splash';
      final isRegisterRoute = state.uri.toString() == '/register';

      // 2. Handle unauthenticated users
      if (!isLoggedIn) {
        // Allow navigation to login, register, and splash pages
        if (isLoginRoute || isRegisterRoute || isSplashRoute) {
          return null; // Go to the requested page
        }
        return '/login'; // Redirect all other requests to login
      }

      // 3. Handle authenticated users
      if (isLoggedIn) {
        // If they are on a login, register, or splash page,
        // redirect them to their home based on role.
        if (isLoginRoute || isRegisterRoute || isSplashRoute) {
          if (authService.isSeller) {
            return '/seller';
          } else if (authService.isBuyer) {
            return '/buyer';
          } else if (authService.isSuperAdmin) {
            return '/admin';
          }
          return '/'; // Default if userType is not found
        }
      }

      // 4. If authenticated and not on a login/splash page,
      // proceed with normal navigation.
      return null;
    },
    errorBuilder: (context, state) => const Scaffold(
      body: Center(
        child: Text('Route not found!', style: TextStyle(fontSize: 20)),
      ),
    ),
    routes: _routes,
    observers: [GoRouterObserver()],
  );
}


  // List of all routes
  static final List<RouteBase> _routes = [
      // Debug Routes
      GoRoute(
        path: '/debug/translations',
        builder: (context, state) => const TranslationDebugWidget(),
      ),
      GoRoute(
        path: '/tts-test',
        builder: (context, state) => const TtsTestPage(),
      ),
      
      // Auth & Onboarding Routes
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Buyer Routes
      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(
            body: child,
          );
        },
        routes: [
          GoRoute(
            path: '/buyer',
            builder: (context, state) => const BuyerHomeScreen(),
          ),
          GoRoute(
            path: '/buyer/content/:id',
            builder: (context, state) => ContentDetailsScreen(
              contentId: state.pathParameters['id'] ?? '',
            ),
          ),
          GoRoute(
            path: '/buyer/search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/buyer/favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: '/buyer/recent-views',
            builder: (context, state) => const RecentViewsScreen(),
          ),
          GoRoute(
            path: '/buyer/profile',
            builder: (context, state) => const BuyerProfileScreen(),
          ),
          GoRoute(
            path: '/buyer/edit-profile',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/buyer/purchases',
            builder: (context, state) => const BuyerProfileScreen(),
          ),
          GoRoute(
            path: '/buyer/purchase-history',
            builder: (context, state) => const BuyerProfileScreen(),
          ),
          GoRoute(
            path: '/buyer/payment-methods',
            builder: (context, state) => const BuyerProfileScreen(),
          ),
        ],
      ),
      
      // Seller Routes
      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(
            body: child,
          );
        },
        routes: [
          GoRoute(
            path: '/seller',
            builder: (context, state) => const SellerHomeScreen(),
          ),
          GoRoute(
            path: '/seller/upload',
            builder: (context, state) => const UploadContentScreen(),
          ),
          GoRoute(
            path: '/seller/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/seller/analytics-page',
            builder: (context, state) => const AnalyticsPage(),
          ),
          GoRoute(
            path: '/seller/manage',
            builder: (context, state) => const ManageContentScreen(),
          ),
          GoRoute(
            path: '/seller/earnings',
            builder: (context, state) => const EarningsScreen(),
          ),
          GoRoute(
            path: '/seller/profile',
            builder: (context, state) => const SellerProfileScreen(),
          ),
          GoRoute(
            path: '/seller/ai-assistant',
            builder: (context, state) => const SellerAIAssistant(),
          ),
          GoRoute(
            path: '/seller/prompt-cache-demo',
            builder: (context, state) => const PromptCacheDemo(),
          ),
        ],
      ),
      
      // Settings Routes
      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(
            body: child,
          );
        },
        routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings/profile',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings/password',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings/payment',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings/notifications',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      
      // Admin Routes
      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(
            body: child,
          );
        },
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const AdminUserManagementScreen(),
          ),
          GoRoute(
            path: '/admin/content',
            builder: (context, state) => const AdminContentManagementScreen(),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (context, state) => const AdminSettingsScreen(),
          ),
          GoRoute(
            path: '/admin/create-super-admin',
            builder: (context, state) => const CreateSuperAdminScreen(),
          ),
        ],
      ),
      
      // Legal Routes
      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(
            body: child,
          );
        },
        routes: [
          GoRoute(
            path: '/terms',
            builder: (context, state) => const TermsOfServiceScreen(),
          ),
          GoRoute(
            path: '/privacy',
            builder: (context, state) => const PrivacyPolicyScreen(),
          ),
          GoRoute(
            path: '/help',
            builder: (context, state) => const HelpCenterPage(),
          ),
          GoRoute(
            path: '/contact',
            builder: (context, state) => const ContactSupportScreen(),
          ),
          GoRoute(
            path: '/hive-cache-demo',
            builder: (context, state) => const HiveCacheDemo(),
          ),
          GoRoute(
            path: '/firestore-cache-demo',
            builder: (context, state) => const FirestoreCacheDemo(),
          ),
          GoRoute(
            path: '/simple-cache-demo',
            builder: (context, state) => const SimpleCacheDemo(),
          ),
          GoRoute(
            path: '/favorites-demo',
            builder: (context, state) => const FavoritesDemo(),
          ),
          GoRoute(
            path: '/heavy-feature-example',
            builder: (context, state) => const HeavyFeatureExample(),
          ),
          GoRoute(
            path: '/recent-views-demo',
            builder: (context, state) => const RecentViewsDemo(),
          ),
          GoRoute(
            path: '/recent-favorites-demo',
            builder: (context, state) => const RecentFavoritesDemoScreen(),
          ),
          GoRoute(
            path: '/gemini-demo',
            builder: (context, state) => const GeminiDemoScreen(),
          ),
          GoRoute(
            path: '/vertex-recommendations',
            builder: (context, state) => const VertexRecommendationsScreen(),
          ),
          GoRoute(
            path: '/ai-usage',
            builder: (context, state) => const AIUsageDashboard(),
          ),
          GoRoute(
            path: '/recommendations-demo',
            builder: (context, state) => const RecommendationsDemoWidget(),
          ),
          GoRoute(
            path: '/gemini-chat',
            builder: (context, state) => const GeminiChatDemoScreen(),
          ),
          GoRoute(
            path: '/bundle-download',
            builder: (context, state) => const BundleDownloadExample(),
          ),
          GoRoute(
            path: '/sync-demo',
            builder: (context, state) => const SyncDemoScreen(),
          ),
          GoRoute(
            path: '/optimization-examples',
            builder: (context, state) => const OptimizationExamplesMenu(),
          ),
          GoRoute(
            path: '/optimized-query-example',
            builder: (context, state) => const OptimizedQueryExample(),
          ),
          GoRoute(
            path: '/asset-optimization-example',
            builder: (context, state) => const AssetOptimizationExample(),
          ),
          GoRoute(
            path: '/webp-conversion-example',
            builder: (context, state) => const WebpConversionExample(),
          ),
          GoRoute(
            path: '/asset-preloading-example',
            builder: (context, state) => const AssetPreloadingExample(),
          ),
          GoRoute(
            path: '/loading-error-example',
            builder: (context, state) => const LoadingErrorExample(),
          ),
          GoRoute(
            path: '/security-examples',
            builder: (context, state) => const SecurityExamplesMenu(),
          ),
          GoRoute(
            path: '/screenshot-protection-demo',
            builder: (context, state) => const ScreenshotProtectionDemo(),
          ),
          GoRoute(
            path: '/sensitive-data-demo',
            builder: (context, state) => const SensitiveDataDemo(),
          ),
          GoRoute(
            path: '/inactivity-timeout-demo',
            builder: (context, state) => const InactivityTimeoutDemo(),
          ),
          GoRoute(
            path: '/auth-interceptor-example',
            builder: (context, state) => const AuthInterceptorExample(),
          ),
          GoRoute(
            path: '/signed-api-example',
            builder: (context, state) => const SignedApiExample(),
          ),
          GoRoute(
            path: '/security-dialog-example',
            builder: (context, state) => const SecurityDialogExample(),
          ),
          GoRoute(
            path: '/security-intro-example',
            builder: (context, state) => const SecurityIntroExample(),
          ),
          GoRoute(
            path: '/app-initialization-example',
            builder: (context, state) => const AppInitializationExample(),
          ),
          GoRoute(
            path: '/sensitive-screen-dialog-example',
            builder: (context, state) => const SensitiveScreenDialogExample(),
          ),
          GoRoute(
            path: '/media-demo',
            builder: (context, state) => const MediaDemoScreen(),
          ),
          GoRoute(
            path: '/upload-screen',
            builder: (context, state) => const UploadScreen(),
          ),
          GoRoute(
            path: '/transitions-demo',
            pageBuilder: (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child: const TransitionsDemoScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ),
          GoRoute(
            path: '/transitions-example/:type',
            pageBuilder: (context, state) {
              final type = state.pathParameters['type'] ?? 'fade';
              return CustomTransitionPage<void>(
                key: state.pageKey,
                child: TransitionsDemoScreen(transitionType: type),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              );
            },
          ),
        ],
      ),
    ];
  

  // Theme configuration
  ThemeData _buildTheme(Brightness brightness) {
    // Modern business color palette
    const primaryColor = Color(0xFF2E5077); // Deep blue
    const secondaryColor = Color(0xFF5A8F7B); // Teal green
    const accentColor = Color(0xFFE67E22); // Warm orange
    const neutralColor = Color(0xFF4A4A4A); // Dark gray
    
    // For web, we're using system fonts to avoid asset loading issues
    // For mobile, we're using local font assets
    var baseTheme = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: kIsWeb ? null : 'Poppins', // Use system fonts for web
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        brightness: brightness,
      ),
    );

    // For mobile, use local Poppins font
    // For web, use system fonts to avoid asset loading issues
    final textTheme = kIsWeb 
      ? baseTheme.textTheme // Use system fonts for web
      : baseTheme.textTheme.copyWith(
          displayLarge: baseTheme.textTheme.displayLarge?.copyWith(fontFamily: 'Poppins'),
          displayMedium: baseTheme.textTheme.displayMedium?.copyWith(fontFamily: 'Poppins'),
          displaySmall: baseTheme.textTheme.displaySmall?.copyWith(fontFamily: 'Poppins'),
          headlineLarge: baseTheme.textTheme.headlineLarge?.copyWith(fontFamily: 'Poppins'),
          headlineMedium: baseTheme.textTheme.headlineMedium?.copyWith(fontFamily: 'Poppins'),
          headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(fontFamily: 'Poppins'),
          titleLarge: baseTheme.textTheme.titleLarge?.copyWith(fontFamily: 'Poppins'),
          titleMedium: baseTheme.textTheme.titleMedium?.copyWith(fontFamily: 'Poppins'),
          titleSmall: baseTheme.textTheme.titleSmall?.copyWith(fontFamily: 'Poppins'),
          bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(fontFamily: 'Poppins'),
          bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(fontFamily: 'Poppins'),
          bodySmall: baseTheme.textTheme.bodySmall?.copyWith(fontFamily: 'Poppins'),
          labelLarge: baseTheme.textTheme.labelLarge?.copyWith(fontFamily: 'Poppins'),
          labelMedium: baseTheme.textTheme.labelMedium?.copyWith(fontFamily: 'Poppins'),
          labelSmall: baseTheme.textTheme.labelSmall?.copyWith(fontFamily: 'Poppins'),
        );
    
    return baseTheme.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: brightness == Brightness.light
            ? const Color(0xFFF8F9FA) // Light gray for light mode
            : const Color(0xFF1E3A5F), // Darker shade of primary for dark mode
        foregroundColor: brightness == Brightness.light
            ? const Color(0xFF2E5077) // Primary color for light mode
            : Colors.white, // White text for dark mode
        iconTheme: IconThemeData(
          color: brightness == Brightness.light
              ? const Color(0xFF2E5077) // Primary color for light mode
              : Colors.white, // White icons for dark mode
        ),
      ),
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF8F9FA) // Light gray background for light mode
          : const Color(0xFF121C26), // Dark blue-gray for dark mode
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF1E3A5F), // Darker shade of primary for dark mode
        shadowColor: brightness == Brightness.light
            ? const Color(0xFF2E5077).withOpacity(0.1) // Subtle primary shadow
            : Colors.black38,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF2E5077), // Primary color
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF2E5077), // Primary color
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF2E5077)), // Primary color
          foregroundColor: const Color(0xFF2E5077), // Primary color
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? const Color(0xFFEEF2F6) // Light blue-gray
            : const Color(0xFF1E3A5F).withOpacity(0.5), // Semi-transparent dark blue
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFF5A8F7B), // Secondary color (teal)
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.all(16),
        hintStyle: TextStyle(
          color: brightness == Brightness.light
              ? const Color(0xFF4A4A4A).withOpacity(0.5) // Neutral color with opacity
              : Colors.white70,
        ),
        labelStyle: TextStyle(
          color: brightness == Brightness.light
              ? const Color(0xFF2E5077) // Primary color
              : Colors.white,
        ),
      ),
    );
  }
}