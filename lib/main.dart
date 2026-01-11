import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/constants/app_theme.dart';
import 'core/services/socket_service.dart';
import 'core/services/sentry_service.dart';
import 'data/services/auth_service.dart';
import 'data/repositories/transaction_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/api/api_client.dart';
import 'providers/providers.dart';
import 'screens/auth/login_screen.dart';
import 'screens/pos/pos_screen.dart';

void main() async {
  // Wrap everything in runZonedGuarded for uncaught errors
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize Sentry first
      await SentryService.init();

      // Preserve native splash screen
      FlutterNativeSplash.preserve(
        widgetsBinding: WidgetsFlutterBinding.ensureInitialized(),
      );

      // Initialize date formatting for Indonesian locale
      await initializeDateFormatting('id_ID', null);

      // Initialize auth service
      final authService = AuthService();
      await authService.init();

      // Initialize socket connection for real-time updates
      SocketService().connect();

      // Wrap app with Sentry error boundary
      runApp(
        DefaultAssetBundle(
          bundle: SentryAssetBundle(),
          child: PelarisApp(authService: authService),
        ),
      );
    },
    (error, stackTrace) {
      // Capture uncaught errors
      SentryService.captureException(
        error,
        stackTrace: stackTrace,
        context: 'uncaught_zone_error',
      );
    },
  );
}

class PelarisApp extends StatelessWidget {
  final AuthService authService;

  const PelarisApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Provider
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService)..init(),
        ),
        // Product Provider
        ChangeNotifierProvider(create: (_) => ProductProvider(authService)),
        // Cart Provider
        ChangeNotifierProvider(create: (_) => CartProvider(authService)),
        // Transaction Provider
        ChangeNotifierProvider(
          create: (_) => TransactionProvider(
            TransactionRepository(ApiClient.getInstance(authService)),
          ),
        ),
        // Settings Provider
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            SettingsRepository(ApiClient.getInstance(authService)),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Pelaris.id',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            // Show loading while checking auth
            if (auth.status == AuthStatus.initial ||
                auth.status == AuthStatus.loading) {
              return const _SplashScreen();
            }

            // Navigate based on auth status
            if (auth.isAuthenticated) {
              return const PosScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Remove native splash screen after Flutter is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon
            Image.asset('assets/images/flutter-loading.png', width: 300),
            const SizedBox(height: 48),
            // Loading Indicator
            const CircularProgressIndicator(
              color: Color(0xFF2862ED),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
