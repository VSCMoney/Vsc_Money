// // main.dart
// import 'dart:async';
// import 'dart:io';
//
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:flutter/services.dart';
//
// // External packages
// import 'package:firebase_app_check/firebase_app_check.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:get_it/get_it.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:vscmoney/controllers/session_manager.dart';
//
// // Local imports
// import 'constants/colors.dart';
// import 'core/helpers/themes.dart';
// import 'firebase_options.dart';
// import 'routes/AppRoutes.dart';
// import 'services/locator.dart';
// import 'services/theme_service.dart';
//
// final sl = GetIt.instance;
//
// void main() async {
//   print('🔍 MAIN: Starting app - ${DateTime.now()}');
//
//   // Suppress keyboard event assertions during development
//   if (kDebugMode) {
//     FlutterError.onError = (FlutterErrorDetails details) {
//       if (details.toString().contains('KeyUpEvent') ||
//           details.toString().contains('_pressedKeys.containsKey')) {
//         debugPrint('Suppressed keyboard event error: ${details.summary}');
//         return;
//       }
//       FlutterError.presentError(details);
//     };
//   }
//
//   runZonedGuarded(() async {
//     print('🔍 MAIN: About to call AppInitializer.initialize()');
//     await AppInitializer.initialize();
//     print('🔍 MAIN: AppInitializer.initialize() completed');
//     runApp(const MyApp());
//     print('🔍 MAIN: runApp() called');
//   }, (error, stack) {
//     debugPrint('🔴 Global error caught: $error');
//     debugPrint('Stack trace: $stack');
//   });
// }
//
// /// Handles all app initialization logic
// class AppInitializer {
//   static int _initializeCallCount = 0;
//   static bool _isInitializing = false;
//   static bool _isInitialized = false;
//
//   static Future<void> initialize() async {
//     _initializeCallCount++;
//     print('🔍 INIT: AppInitializer.initialize() called - Count: $_initializeCallCount');
//     print('🔍 INIT: Stack trace: ${StackTrace.current}');
//
//     if (_isInitializing) {
//       print('⚠️ INIT: Already initializing, waiting...');
//       while (_isInitializing) {
//         await Future.delayed(const Duration(milliseconds: 100));
//       }
//       return;
//     }
//     if (_isInitialized) {
//       print('✅ INIT: Already initialized, skipping');
//       return;
//     }
//
//     _isInitializing = true;
//
//     try {
//       debugPrint('🚀 Starting app initialization...');
//
//       // Core Flutter setup
//       WidgetsFlutterBinding.ensureInitialized();
//       WidgetsBinding.instance.deferFirstFrame();
//
//       // Setup dependencies and services
//       await _setupDependencies();
//       await _initializeFirebase();
//       await _loadUserPreferences();
//
//       // ✅ Edge-to-edge & show status bar with safe defaults (dark icons on light bg)
//       // await SystemChrome.setEnabledSystemUIMode(
//       //   SystemUiMode.edgeToEdge,
//       //   overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
//       // );
//       // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
//       //   statusBarColor: Colors.transparent,
//       //   statusBarBrightness: Brightness.light,   // iOS: dark glyphs
//       //   statusBarIconBrightness: Brightness.dark, // Android: dark glyphs
//       //   systemNavigationBarColor: Colors.transparent,
//       //   systemNavigationBarIconBrightness: Brightness.dark,
//       // ));
//
//       await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//
//       await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//       SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
//         statusBarColor: Colors.transparent,
//         statusBarBrightness: Brightness.light,
//         statusBarIconBrightness: Brightness.dark,
//         systemNavigationBarColor: Colors.transparent, // Use transparent
//         systemNavigationBarIconBrightness: Brightness.dark,
//         systemNavigationBarDividerColor: Colors.transparent, // Match transparency
//         systemNavigationBarContrastEnforced: false,
//         systemStatusBarContrastEnforced: false,
//       ));
//
//
//       // Allow UI to render
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         WidgetsBinding.instance.allowFirstFrame();
//       });
//
//       _isInitialized = true;
//       debugPrint('✅ App initialization completed successfully');
//     } catch (error, stackTrace) {
//       debugPrint('❌ App initialization failed: $error');
//       debugPrint('Stack trace: $stackTrace');
//       rethrow;
//     } finally {
//       _isInitializing = false;
//     }
//   }
//
//   static Future<void> _setupDependencies() async {
//     debugPrint('🔧 Setting up dependencies...');
//     setupLocator();
//     debugPrint('✅ Dependencies setup completed');
//   }
//
//   static Future<void> _initializeFirebase() async {
//     print('🔍 FIREBASE: _initializeFirebase() called');
//     print('🔍 FIREBASE: Firebase.apps.length = ${Firebase.apps.length}');
//
//     if (Firebase.apps.isNotEmpty) {
//       print('🔍 FIREBASE: Existing apps:');
//       for (var app in Firebase.apps) {
//         print('  - App name: ${app.name}, options: ${app.options}');
//       }
//     }
//
//     debugPrint('🔥 Initializing Firebase...');
//
//     try {
//       FirebaseApp? app;
//
//       if (Firebase.apps.isEmpty) {
//         print('🔍 FIREBASE: No existing apps, creating new one');
//         app = await Firebase.initializeApp(
//           options: DefaultFirebaseOptions.currentPlatform,
//         );
//         debugPrint('✅ Firebase app created successfully: ${app.name}');
//       } else {
//         print('🔍 FIREBASE: Using existing app');
//         app = Firebase.app();
//         debugPrint('✅ Using existing Firebase app: ${app.name}');
//       }
//
//       // Setup App Check
//       try {
//         await FirebaseAppCheck.instance.activate(
//           androidProvider: AndroidProvider.playIntegrity,
//           appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
//         );
//         debugPrint('✅ Firebase App Check activated');
//       } catch (appCheckError) {
//         debugPrint('⚠️ Firebase App Check failed: $appCheckError');
//       }
//
//       debugPrint('✅ Firebase initialization completed');
//     } catch (error) {
//       debugPrint('❌ Firebase initialization failed: $error');
//
//       if (error.toString().contains('duplicate-app')) {
//         debugPrint('🔥 Handling duplicate app error...');
//         print('🔍 FIREBASE: Current apps after error:');
//         for (var app in Firebase.apps) {
//           print('  - App: ${app.name}');
//         }
//         return;
//       }
//
//       debugPrint('⚠️ Continuing without Firebase...');
//     }
//   }
//
//   static Future<void> _loadUserPreferences() async {
//     debugPrint('📱 Loading user preferences...');
//
//     try {
//       await SessionManager.loadTokens();
//       await locator<ThemeService>().loadThemeFromPrefs();
//
//       final prefs = await SharedPreferences.getInstance();
//       final isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
//
//       debugPrint('✅ User preferences loaded (biometric: $isBiometricEnabled)');
//     } catch (error) {
//       debugPrint('❌ Failed to load user preferences: $error');
//     }
//   }
//
//   // ✅ Debug methods
//   static void printDebugInfo() {
//     print('🔍 DEBUG INFO:');
//     print('  - Initialize call count: $_initializeCallCount');
//     print('  - Is initializing: $_isInitializing');
//     print('  - Is initialized: $_isInitialized');
//     print('  - Firebase apps count: ${Firebase.apps.length}');
//   }
//
//   static void reset() {
//     _initializeCallCount = 0;
//     _isInitializing = false;
//     _isInitialized = false;
//   }
// }
//
// /// Main application widget
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return AppThemeBuilder(
//       builder: (context, theme) {
//         final isLight = theme == AppTheme.light;
//         final overlay = SystemUiOverlayStyle(
//           statusBarColor: Colors.transparent,
//           statusBarBrightness: isLight ? Brightness.light : Brightness.dark,   // iOS
//           statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light, // Android
//           systemNavigationBarColor: Colors.transparent,
//           systemNavigationBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
//           systemNavigationBarContrastEnforced: false,   // 👈
//           systemStatusBarContrastEnforced: false,
//         );
//
//         return HeroControllerScope(
//           controller: MaterialApp.createMaterialHeroController(),
//           child: AnnotatedRegion<SystemUiOverlayStyle>(
//             value: overlay,
//             child: MaterialApp.router(
//               debugShowCheckedModeBanner: false,
//               title: 'Vitty.ai',
//               routerConfig: AppRouter.router,
//               theme: _buildThemeData(theme, overlay),
//               builder: (context, child) => AppWrapper(child: child),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   ThemeData _buildThemeData(AppTheme appTheme, SystemUiOverlayStyle overlay) {
//     final isLight = appTheme == AppTheme.light;
//
//     // Start from the base scheme, then override brand colors
//     final baseScheme = isLight
//         ? const ColorScheme.light()
//         : const ColorScheme.dark();
//
//     // Your brand color (you likely already use this elsewhere)
//     final brandPrimary = AppColors.primary; // e.g. Color(0xFFF66A00)
//
//     return ThemeData(
//       scaffoldBackgroundColor: appTheme.bottombackground,
//       appBarTheme: AppBarTheme(
//         backgroundColor: appTheme.background,
//         iconTheme: IconThemeData(color: appTheme.icon),
//         titleTextStyle: TextStyle(
//           color: appTheme.text,
//           fontSize: 18,
//           fontWeight: FontWeight.bold,
//         ),
//         systemOverlayStyle: overlay,
//         elevation: 0,
//       ),
//       iconTheme: IconThemeData(color: appTheme.icon),
//       extensions: [AppThemeExtension(appTheme)],
//       textTheme: TextTheme(
//         bodyLarge: TextStyle(color: appTheme.text),
//         bodyMedium: TextStyle(color: appTheme.text),
//         bodySmall: TextStyle(color: appTheme.text),
//         titleLarge: TextStyle(color: appTheme.text),
//         titleMedium: TextStyle(color: appTheme.text),
//         titleSmall: TextStyle(color: appTheme.text),
//       ),
//       bottomAppBarTheme: const BottomAppBarTheme(color: Colors.transparent, elevation: 0),
//
//       // 🔶 Ensure spinners/“typing” use your brand (not purple)
//       colorScheme: baseScheme.copyWith(
//         primary: brandPrimary,
//         secondary: brandPrimary,
//         surface: appTheme.background,
//         onSurface: appTheme.text,
//         background: appTheme.background,
//         onBackground: appTheme.text,
//       ),
//       progressIndicatorTheme: ProgressIndicatorThemeData(
//         color: brandPrimary,
//       ),
//     );
//   }
//
// }
//
// /// Reactive theme builder widget
// class AppThemeBuilder extends StatefulWidget {
//   final Widget Function(BuildContext context, AppTheme theme) builder;
//
//   const AppThemeBuilder({
//     super.key,
//     required this.builder,
//   });
//
//   @override
//   State<AppThemeBuilder> createState() => _AppThemeBuilderState();
// }
//
// class _AppThemeBuilderState extends State<AppThemeBuilder> {
//   late final ThemeService _themeService;
//   late StreamSubscription<AppTheme> _themeSubscription;
//   AppTheme _currentTheme = AppTheme.light;
//
//   @override
//   void initState() {
//     super.initState();
//     _themeService = locator<ThemeService>();
//     _currentTheme = _themeService.currentTheme;
//
//     // Apply initial System UI for current theme
//     _applySystemUiForTheme(_currentTheme);
//
//     // React to theme changes
//     _themeSubscription = _themeService.themeStream.listen((theme) {
//       if (mounted && _currentTheme != theme) {
//         setState(() {
//           _currentTheme = theme;
//         });
//         _applySystemUiForTheme(theme);
//         if (kDebugMode) {
//           debugPrint("🎨 Theme changed: ${theme == AppTheme.dark ? "Dark" : "Light"}");
//         }
//       }
//     });
//   }
//
//   void _applySystemUiForTheme(AppTheme theme) {
//     final isLight = theme == AppTheme.light;
//     SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
//       statusBarColor: Colors.transparent,
//       statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
//       statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
//       systemNavigationBarColor: Colors.transparent, // Use transparent
//       systemNavigationBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
//       systemNavigationBarDividerColor: Colors.transparent, // Match transparency
//       systemNavigationBarContrastEnforced: false,
//       systemStatusBarContrastEnforced: false,
//     ));
//   }
//
//   @override
//   void dispose() {
//     _themeSubscription.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return widget.builder(context, _currentTheme);
//   }
// }
//
// /// App-wide wrapper for global functionality
// class AppWrapper extends StatelessWidget {
//   final Widget? child;
//
//   const AppWrapper({super.key, this.child});
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       // Dismiss keyboard when tapping outside
//       onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
//       child: child ?? const SizedBox.shrink(),
//     );
//   }
// }
//
// /// Error handling wrapper widget
// class AppErrorBoundary extends StatefulWidget {
//   final Widget child;
//   final Widget Function(Object error)? errorBuilder;
//
//   const AppErrorBoundary({
//     super.key,
//     required this.child,
//     this.errorBuilder,
//   });
//
//   @override
//   State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
// }
//
// class _AppErrorBoundaryState extends State<AppErrorBoundary> {
//   Object? _error;
//
//   @override
//   Widget build(BuildContext context) {
//     if (_error != null) {
//       return widget.errorBuilder?.call(_error!) ?? _buildDefaultErrorWidget();
//     }
//     return widget.child;
//   }
//
//   Widget _buildDefaultErrorWidget() {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.error_outline, size: 64, color: Colors.red),
//             const SizedBox(height: 16),
//             const Text('Oops! Something went wrong',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             const Text(
//               'Please restart the app or contact support if the problem persists.',
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () => setState(() => _error = null),
//               child: const Text('Try Again'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     FlutterError.onError = (FlutterErrorDetails details) {
//       if (mounted) {
//         setState(() => _error = details.exception);
//       }
//     };
//   }
// }
//
// /// Development helper functions
// class DevTools {
//   static void logPerformance(String operation, VoidCallback callback) {
//     if (!kDebugMode) {
//       callback();
//       return;
//     }
//     final stopwatch = Stopwatch()..start();
//     callback();
//     stopwatch.stop();
//     debugPrint('⏱️ $operation took ${stopwatch.elapsedMilliseconds}ms');
//   }
//
//   static void logMemoryUsage() {
//     if (!kDebugMode) return;
//     final info = ProcessInfo.currentRss;
//     debugPrint('💾 Memory usage: ${(info / 1024 / 1024).toStringAsFixed(2)} MB');
//   }
// }
//
// /// App configuration constants
// class AppConfig {
//   static const String appName = 'Vitty.ai';
//   static const String version = '1.0.0';
//   static const bool enableAnalytics = true;
//   static const bool enableCrashReporting = true;
//
//   // Theme settings
//   static const Duration themeAnimationDuration = Duration(milliseconds: 300);
//
//   // Network settings
//   static const Duration networkTimeout = Duration(seconds: 30);
//   static const int maxRetryAttempts = 3;
// }
//
// /// Extension for better error handling
// extension SafeAsyncOperation on Future {
//   Future<T?> safely<T>() async {
//     try {
//       return await this as T;
//     } catch (error, stackTrace) {
//       debugPrint('🔴 Safe async operation failed: $error');
//       if (kDebugMode) {
//         debugPrint('Stack trace: $stackTrace');
//       }
//       return null;
//     }
//   }
// }




// main.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

// External packages
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:vscmoney/services/api_service.dart';

// Local imports
import 'controllers/session_manager.dart';
import 'constants/colors.dart';
import 'core/helpers/themes.dart';
import 'firebase_options.dart';
import 'routes/AppRoutes.dart';
import 'services/locator.dart';
import 'services/theme_service.dart';

final sl = GetIt.instance;

void main() async {
  print('🔍 MAIN: Starting app - ${DateTime.now()}');

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
    print('🔍 MAIN: About to call AppInitializer.initialize()');
    await AppInitializer.initialize();
    print('🔍 MAIN: AppInitializer.initialize() completed');
    runApp(const MyApp());
    print('🔍 MAIN: runApp() called');
  }, (error, stack) {
    debugPrint('🔴 Global error caught: $error');
    debugPrint('Stack trace: $stack');
  });
}

/// Handles all app initialization logic
class AppInitializer {
  static int _initializeCallCount = 0;
  static bool _isInitializing = false;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    _initializeCallCount++;
    print('🔍 INIT: AppInitializer.initialize() called - Count: $_initializeCallCount');

    if (_isInitializing) {
      print('⚠️ INIT: Already initializing, waiting...');
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }
    if (_isInitialized) {
      print('✅ INIT: Already initialized, skipping');
      return;
    }

    _isInitializing = true;

    try {
      debugPrint('🚀 Starting app initialization...');

      // Core Flutter setup
      WidgetsFlutterBinding.ensureInitialized();
      WidgetsBinding.instance.deferFirstFrame();

      // Setup dependencies and services
      await _setupDependencies();
      await _initializeFirebase();
      await _loadUserPreferences();

      // Initialize network monitoring early
      await _initializeNetworkServices();

      // System UI setup
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        systemStatusBarContrastEnforced: false,
      ));

      // Allow UI to render
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.allowFirstFrame();
      });

      _isInitialized = true;
      debugPrint('✅ App initialization completed successfully');
    } catch (error, stackTrace) {
      debugPrint('❌ App initialization failed: $error');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  static Future<void> _setupDependencies() async {
    debugPrint('🔧 Setting up dependencies...');
    setupLocator();
    debugPrint('✅ Dependencies setup completed');
  }

  // Network initialization
  static Future<void> _initializeNetworkServices() async {
    debugPrint('📡 Initializing network services...');
    try {
      // Initialize EndPointService (which sets up network monitoring)
      final endPointService = EndPointService();

      // Check initial connectivity status
      final connectivity = Connectivity();
      final connectivityResult = await connectivity.checkConnectivity()
          .timeout(const Duration(seconds: 5));

      debugPrint('📡 Initial connectivity: $connectivityResult');
      debugPrint('✅ Network services initialized');
    } catch (error) {
      debugPrint('⚠️ Network services initialization failed: $error');
      // Continue without network monitoring rather than crash
    }
  }

  static Future<void> _initializeFirebase() async {
    print('🔍 FIREBASE: _initializeFirebase() called');

    if (Firebase.apps.isNotEmpty) {
      print('🔍 FIREBASE: Using existing Firebase app');
      return;
    }

    debugPrint('🔥 Initializing Firebase...');

    try {
      final app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 15));
      debugPrint('✅ Firebase app created successfully: ${app.name}');

      // Setup App Check with timeout
      try {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
        ).timeout(const Duration(seconds: 10));
        debugPrint('✅ Firebase App Check activated');
      } catch (appCheckError) {
        debugPrint('⚠️ Firebase App Check failed: $appCheckError');
      }

      debugPrint('✅ Firebase initialization completed');
    } on TimeoutException {
      debugPrint('⏰ Firebase initialization timed out');
      debugPrint('⚠️ Continuing without Firebase...');
    } catch (error) {
      debugPrint('❌ Firebase initialization failed: $error');

      if (error.toString().contains('duplicate-app')) {
        debugPrint('🔥 Handling duplicate app error...');
        return;
      }

      debugPrint('⚠️ Continuing without Firebase...');
    }
  }

  static Future<void> _loadUserPreferences() async {
    debugPrint('📱 Loading user preferences...');

    try {
      // Add timeout to prevent blocking
      await Future.wait([
        SessionManager.loadTokens(),
        locator<ThemeService>().loadThemeFromPrefs(),
      ]).timeout(const Duration(seconds: 5));

      final prefs = await SharedPreferences.getInstance();
      final isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;

      debugPrint('✅ User preferences loaded (biometric: $isBiometricEnabled)');
    } on TimeoutException {
      debugPrint('⏰ User preferences loading timed out');
      // Continue with defaults
    } catch (error) {
      debugPrint('❌ Failed to load user preferences: $error');
      // Continue with defaults rather than crash
    }
  }

  static void printDebugInfo() {
    print('🔍 DEBUG INFO:');
    print('  - Initialize call count: $_initializeCallCount');
    print('  - Is initializing: $_isInitializing');
    print('  - Is initialized: $_isInitialized');
    print('  - Firebase apps count: ${Firebase.apps.length}');
  }

  static void reset() {
    _initializeCallCount = 0;
    _isInitializing = false;
    _isInitialized = false;
  }
}

/// Main application widget with network status integration
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppThemeBuilder(
      builder: (context, theme) {
        final isLight = theme == AppTheme.light;
        final overlay = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
          statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
          systemNavigationBarContrastEnforced: false,
          systemStatusBarContrastEnforced: false,
        );

        return HeroControllerScope(
          controller: MaterialApp.createMaterialHeroController(),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlay,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Vitty.ai',
              routerConfig: AppRouter.router,
              theme: _buildThemeData(theme, overlay),
              // Add global network awareness wrapper
              builder: (context, child) => NetworkAwareWrapper(
                child: AppWrapper(child: child),
              ),
            ),
          ),
        );
      },
    );
  }

  ThemeData _buildThemeData(AppTheme appTheme, SystemUiOverlayStyle overlay) {
    final isLight = appTheme == AppTheme.light;
    final baseScheme = isLight ? const ColorScheme.light() : const ColorScheme.dark();
    final brandPrimary = AppColors.primary;

    return ThemeData(
      scaffoldBackgroundColor: appTheme.bottombackground,
      appBarTheme: AppBarTheme(
        backgroundColor: appTheme.background,
        iconTheme: IconThemeData(color: appTheme.icon),
        titleTextStyle: TextStyle(
          color: appTheme.text,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        systemOverlayStyle: overlay,
        elevation: 0,
      ),
      iconTheme: IconThemeData(color: appTheme.icon),
      extensions: [AppThemeExtension(appTheme)],
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: appTheme.text),
        bodyMedium: TextStyle(color: appTheme.text),
        bodySmall: TextStyle(color: appTheme.text),
        titleLarge: TextStyle(color: appTheme.text),
        titleMedium: TextStyle(color: appTheme.text),
        titleSmall: TextStyle(color: appTheme.text),
      ),
      bottomAppBarTheme: const BottomAppBarTheme(color: Colors.transparent, elevation: 0),
      colorScheme: baseScheme.copyWith(
        primary: brandPrimary,
        secondary: brandPrimary,
        surface: appTheme.background,
        onSurface: appTheme.text,
        background: appTheme.background,
        onBackground: appTheme.text,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: brandPrimary,
      ),
    );
  }
}

/// Network-aware wrapper
class NetworkAwareWrapper extends StatefulWidget {
  final Widget? child;

  const NetworkAwareWrapper({super.key, this.child});

  @override
  State<NetworkAwareWrapper> createState() => _NetworkAwareWrapperState();
}

class _NetworkAwareWrapperState extends State<NetworkAwareWrapper> with WidgetsBindingObserver {
  late StreamSubscription<NetworkStatus> _networkSubscription;
  NetworkStatus _currentStatus = NetworkStatus.connected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    try {
      // Listen to network status changes
      final endPointService = EndPointService();
      _currentStatus = endPointService.currentNetworkStatus;

      _networkSubscription = endPointService.networkStatusStream.listen((status) {
        if (mounted && _currentStatus != status) {
          setState(() {
            _currentStatus = status;
          });
        }
      });
    } catch (e) {
      debugPrint('Network monitoring initialization failed: $e');
      // Create a dummy subscription to prevent null errors
      _networkSubscription = Stream<NetworkStatus>.empty().listen((_) {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _networkSubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app lifecycle changes for better network management
    switch (state) {
      case AppLifecycleState.resumed:
      // App came back to foreground - the EndPointService handles this internally
        debugPrint('App resumed from background');
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        debugPrint('App going to background');
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child ?? const SizedBox.shrink(),
        // Optional: Show network status indicator
      ],
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
    try {
      _themeService = locator<ThemeService>();
      _currentTheme = _themeService.currentTheme;

      _applySystemUiForTheme(_currentTheme);

      _themeSubscription = _themeService.themeStream.listen((theme) {
        if (mounted && _currentTheme != theme) {
          setState(() {
            _currentTheme = theme;
          });
          _applySystemUiForTheme(theme);
          if (kDebugMode) {
            debugPrint("🎨 Theme changed: ${theme == AppTheme.dark ? "Dark" : "Light"}");
          }
        }
      });
    } catch (e) {
      debugPrint('Theme service initialization failed: $e');
      // Use default theme and create empty subscription
      _themeSubscription = Stream<AppTheme>.empty().listen((_) {});
    }
  }

  void _applySystemUiForTheme(AppTheme theme) {
    final isLight = theme == AppTheme.light;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
      statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    ));
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
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child ?? const SizedBox.shrink(),
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
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Oops! Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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