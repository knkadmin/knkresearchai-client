import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_stripe_web/flutter_stripe_web.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:fa_ai_agent/pages/sign_in_page.dart';
import 'package:fa_ai_agent/pages/sign_up_page.dart';
import 'package:fa_ai_agent/pages/dashboard_page.dart';
import 'package:fa_ai_agent/pages/pricing_page.dart';
import 'package:fa_ai_agent/pages/hedge_fund_wizard_page.dart';
import 'package:fa_ai_agent/pages/share_content_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart' show HiveWebStorage;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fa_ai_agent/services/auth_service.dart';
import 'package:fa_ai_agent/services/firestore_service.dart';
import 'package:fa_ai_agent/pages/error_page.dart';
import 'package:fa_ai_agent/pages/payment_success_page.dart';
import 'package:fa_ai_agent/pages/payment_cancel_page.dart';
import 'package:fa_ai_agent/config/environment.dart';
import 'package:fa_ai_agent/config/environments.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment based on FLUTTER_ENV or debug mode
  const isStaging =
      bool.fromEnvironment('FLUTTER_ENV_STAGING', defaultValue: false);
  const isProduction =
      bool.fromEnvironment('FLUTTER_ENV_PRODUCTION', defaultValue: false);

  if (isStaging) {
    EnvironmentConfig.setEnvironment(Environment.staging);
  } else if (isProduction) {
    EnvironmentConfig.setEnvironment(Environment.production);
  } else if (kDebugMode) {
    EnvironmentConfig.setEnvironment(Environment.development);
  } else {
    EnvironmentConfig.setEnvironment(Environment.production);
  }

  setPathUrlStrategy();
  if (kIsWeb) {
    // Register the web implementation
    StripePlatform.instance = WebStripe.instance;
  }
  Stripe.publishableKey =
      'pk_test_51R8fetCX57jNO1ch1M1g0zFMEWkyd9MQazUTh3FXA1G7gR2UXPLcnNoGdz0L3aRiPssRiGkph7eQeZxacrF6yecx00EuucSjhX';
  // Initialize Stripe for web
  await Stripe.instance.applySettings();

  // Initialize Hive with proper configuration for web
  if (kIsWeb) {
    // For web, we need to use a different path
    await Hive.initFlutter('web_storage');
  } else {
    await Hive.initFlutter();
  }

  // Open the settings box
  await Hive.openBox('settings');
  // Open the report section cache box
  await Hive.openBox<String>('report_section_cache');

  try {
    // Initialize Firebase with environment-specific options
    FirebaseOptions firebaseOptions;

    if (isStaging || kDebugMode) {
      firebaseOptions = const FirebaseOptions(
          apiKey: "AIzaSyAMuu7xA038G02LXURG-eyyfDS-kSz4Fag",
          authDomain: "knkresearchai-staging.firebaseapp.com",
          projectId: "knkresearchai-staging",
          storageBucket: "knkresearchai-staging.firebasestorage.app",
          messagingSenderId: "57077865056",
          appId: "1:57077865056:web:a83baa56f428add233c105",
          measurementId: "G-Z7967LYT1Z");
    } else {
      // Production configuration
      firebaseOptions = const FirebaseOptions(
          apiKey: "AIzaSyCfP_7S5823KOdftkK2z_UyZ6aRvr8kZZU",
          authDomain: "knkresearchai.com",
          projectId: "knkresearchai",
          storageBucket: "knkresearchai.com",
          messagingSenderId: "1067859590559",
          appId: "1:1067859590559:web:0c9ae04b3b08b215338598",
          measurementId: "G-T9CGSRZCR2");
    }

    await Firebase.initializeApp(options: firebaseOptions);
    print(
        'Firebase initialized successfully with ${firebaseOptions.projectId} configuration');

    // Configure Firestore settings
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        sslEnabled: true,
      );
      print('Firestore settings configured for web');
    }

    // Set persistence after Firebase is initialized
    if (kIsWeb) {
      try {
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
        print('Firebase Auth persistence set to LOCAL');
      } catch (e) {
        print('Error setting persistence: $e');
      }
    }

    // Check for redirect result on web platform
    if (kIsWeb) {
      try {
        print("Checking for sign-in redirect result...");
        final authService = AuthService();
        final result = await authService.getRedirectResult();
        if (result != null) {
          print(
              "Successfully signed in after redirect: ${result.user?.displayName}");

          // Wait for auth state to be ready
          await Future.delayed(const Duration(milliseconds: 500));

          // Create or update user profile in Firestore
          final firestoreService = FirestoreService();
          await firestoreService.createOrUpdateUserProfile(
              // Assuming redirect result is from Google.
              // If other providers are used, this needs to be determined dynamically.
              signInMethod: 'google');
        }
      } catch (e) {
        print("Error handling redirect result: $e");
      }
    }
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  runApp(const MyApp());
}

enum Language {
  chinese('Chinese'),
  english('English');

  final String value;
  const Language(this.value);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: EnvironmentConfig.current.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E2C3D),
          primary: const Color(0xFF1E2C3D),
          secondary: const Color(0xFF2E4B6F),
          surface: Colors.white,
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E2C3D),
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E2C3D),
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            color: Colors.grey[800],
          ),
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => NoTransitionPage<void>(
              child: const DashboardPage(),
            ),
          ),
          GoRoute(
            path: '/signin',
            pageBuilder: (context, state) => NoTransitionPage<void>(
              child: const SignInPage(),
            ),
          ),
          GoRoute(
            path: '/signup',
            pageBuilder: (context, state) => NoTransitionPage<void>(
              child: const SignUpPage(),
            ),
          ),
          GoRoute(
            path: '/report/:ticker',
            pageBuilder: (context, state) => NoTransitionPage<void>(
              child: const DashboardPage(),
            ),
          ),
          GoRoute(
            path: '/pricing',
            pageBuilder: (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child: const PricingPage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 200),
            ),
          ),
          GoRoute(
            path: '/payment-success',
            pageBuilder: (context, state) => NoTransitionPage<void>(
              child: const PaymentSuccessPage(),
            ),
          ),
          GoRoute(
            path: '/payment-cancel',
            pageBuilder: (context, state) => NoTransitionPage<void>(
              child: const PaymentCancelPage(),
            ),
          ),
          GoRoute(
            path: '/hedge-fund-wizard',
            pageBuilder: (context, state) => NoTransitionPage<void>(
              child: const HedgeFundWizardPage(),
            ),
          ),
          GoRoute(
            path: '/share/:documentId',
            pageBuilder: (context, state) => NoTransitionPage<void>(
              child: ShareContentPage(
                documentId: state.pathParameters['documentId']!,
              ),
            ),
          ),
        ],
        errorBuilder: (context, state) => ErrorPage(
          errorMessage: 'The page "${state.uri.path}" could not be found.',
        ),
      ),
    );
  }
}
