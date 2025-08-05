import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

// External packages
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:gif/gif.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vscmoney/controllers/session_manager.dart';

// Local imports
import 'core/helpers/themes.dart';
import 'firebase_options.dart';
import 'routes/AppRoutes.dart';
import 'services/locator.dart';
import 'services/theme_service.dart';

final sl = GetIt.instance;

void main() async {
  // Suppress keyboard event assertions during development
  if (kDebugMode) {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.toString().contains('KeyUpEvent') ||
          details.toString().contains('_pressedKeys.containsKey')) {
        debugPrint('Suppressed keyboard event error: ${details.summary}');
        return;
      }
      FlutterError.presentError(details);
    };
  }

  runZonedGuarded(() async {
    await AppInitializer.initialize();
    runApp(const MyApp());
  }, (error, stack) {
    debugPrint('🔴 Global error caught: $error');
    debugPrint('Stack trace: $stack');
  });
}

/// Handles all app initialization logic
class AppInitializer {
  static Future<void> initialize() async {
    try {
      debugPrint('🚀 Starting app initialization...');

      // Core Flutter setup
      WidgetsFlutterBinding.ensureInitialized();
      WidgetsBinding.instance.deferFirstFrame();

      // Setup dependencies and services
      await _setupDependencies();
      await _initializeFirebase();
      await _loadUserPreferences();

      // Allow UI to render
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.allowFirstFrame();
      });

      debugPrint('✅ App initialization completed successfully');
    } catch (error, stackTrace) {
      debugPrint('❌ App initialization failed: $error');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> _setupDependencies() async {
    debugPrint('🔧 Setting up dependencies...');

    // Register core services
   // sl.registerLazySingleton<EndPointService>(() => EndPointService());

    // Setup locator with all services
    setupLocator();

    debugPrint('✅ Dependencies setup completed');
  }

  static Future<void> _initializeFirebase() async {
    debugPrint('🔥 Initializing Firebase...');

    try {
      // Initialize Firebase if not already done
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // Setup App Check for security
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
      );

      debugPrint('✅ Firebase initialization completed');
    } catch (error) {
      debugPrint('❌ Firebase initialization failed: $error');
      // Don't rethrow - app can work without Firebase in some cases
    }
  }

  static Future<void> _loadUserPreferences() async {
    debugPrint('📱 Loading user preferences...');


    try {

      await SessionManager.loadTokens();

      // Load theme preferences
      await locator<ThemeService>().loadThemeFromPrefs();

      // Load other preferences
      final prefs = await SharedPreferences.getInstance();
      final isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;

      debugPrint('✅ User preferences loaded (biometric: $isBiometricEnabled)');
    } catch (error) {
      debugPrint('❌ Failed to load user preferences: $error');
      // Continue execution with default preferences
    }
  }
}

/// Main application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppThemeBuilder(
      builder: (context, theme) => HeroControllerScope(
        controller: MaterialApp.createMaterialHeroController(),
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Vitty.ai',
          routerConfig: AppRouter.router,
          theme: _buildThemeData(theme),
          builder: (context, child) => AppWrapper(child: child),
        ),
      ),
    );
  }

  ThemeData _buildThemeData(AppTheme theme) {
    return ThemeData(
      scaffoldBackgroundColor: theme.bottombackground,
      appBarTheme: AppBarTheme(
        backgroundColor: theme.background,
        iconTheme: IconThemeData(color: theme.icon),
        titleTextStyle: TextStyle(
          color: theme.text,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      iconTheme: IconThemeData(color: theme.icon),
      extensions: [AppThemeExtension(theme)],
      // Modern text theme
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: theme.text),
        bodyMedium: TextStyle(color: theme.text),
        bodySmall: TextStyle(color: theme.text),
        titleLarge: TextStyle(color: theme.text),
        titleMedium: TextStyle(color: theme.text),
        titleSmall: TextStyle(color: theme.text),
      ),
    );
  }
}

/// Reactive theme builder widget
class AppThemeBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, AppTheme theme) builder;

  const AppThemeBuilder({
    super.key,
    required this.builder,
  });

  @override
  State<AppThemeBuilder> createState() => _AppThemeBuilderState();
}

class _AppThemeBuilderState extends State<AppThemeBuilder> {
  late final ThemeService _themeService;
  late StreamSubscription<AppTheme> _themeSubscription;
  AppTheme _currentTheme = AppTheme.light;

  @override
  void initState() {
    super.initState();
    _themeService = locator<ThemeService>();
    _currentTheme = _themeService.currentTheme;

    // Setup subscription to theme changes
    _themeSubscription = _themeService.themeStream.listen((theme) {
      if (mounted && _currentTheme != theme) {
        setState(() {
          _currentTheme = theme;
        });

        if (kDebugMode) {
          debugPrint("🎨 Theme changed: ${theme == AppTheme.dark ? "Dark" : "Light"}");
        }
      }
    });
  }

  @override
  void dispose() {
    _themeSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _currentTheme);
  }
}

/// App-wide wrapper for global functionality
class AppWrapper extends StatelessWidget {
  final Widget? child;

  const AppWrapper({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return SafeArea(
      top: false,
      bottom: false, // you can set to true if you want to cut off below gesture bar
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}


/// Error handling wrapper widget
class AppErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error)? errorBuilder;

  const AppErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<AppErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!) ?? _buildDefaultErrorWidget();
    }

    return widget.child;
  }

  Widget _buildDefaultErrorWidget() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please restart the app or contact support if the problem persists.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => _error = null),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Catch errors that occur during build
    FlutterError.onError = (FlutterErrorDetails details) {
      if (mounted) {
        setState(() => _error = details.exception);
      }
    };
  }
}

/// Development helper functions
class DevTools {
  static void logPerformance(String operation, VoidCallback callback) {
    if (!kDebugMode) {
      callback();
      return;
    }

    final stopwatch = Stopwatch()..start();
    callback();
    stopwatch.stop();

    debugPrint('⏱️ $operation took ${stopwatch.elapsedMilliseconds}ms');
  }

  static void logMemoryUsage() {
    if (!kDebugMode) return;

    final info = ProcessInfo.currentRss;
    debugPrint('💾 Memory usage: ${(info / 1024 / 1024).toStringAsFixed(2)} MB');
  }
}

/// App configuration constants
class AppConfig {
  static const String appName = 'Vitty.ai';
  static const String version = '1.0.0';
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;

  // Theme settings
  static const Duration themeAnimationDuration = Duration(milliseconds: 300);

  // Network settings
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
}

/// Extension for better error handling
extension SafeAsyncOperation on Future {
  Future<T?> safely<T>() async {
    try {
      return await this as T;
    } catch (error, stackTrace) {
      debugPrint('🔴 Safe async operation failed: $error');
      if (kDebugMode) {
        debugPrint('Stack trace: $stackTrace');
      }
      return null;
    }
  }
}





























