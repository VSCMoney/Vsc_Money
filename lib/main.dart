import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:gif/gif.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vscmoney/screens/presentation/auth/profile_screen.dart';
import 'package:vscmoney/screens/widgets/common_button.dart';
import 'package:vscmoney/services/api_service.dart';
import 'package:vscmoney/services/auth_service.dart';
import 'package:vscmoney/services/biometric_service.dart';
import 'package:vscmoney/services/locator.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:http/http.dart'as http;
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:vscmoney/routes/AppRoutes.dart';
import 'package:vscmoney/screens/presentation/home/home_screen.dart';
import 'package:vscmoney/services/theme_service.dart';
import 'package:vscmoney/testpage.dart';
import 'controllers/auth_controller.dart';
import 'controllers/session_manager.dart';
import 'core/helpers/themes.dart';
import 'firebase_options.dart';


final sl = GetIt.instance;

void setupDependencies() {
  sl.registerLazySingleton<ApiService>(() => ApiService());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ this fixes the binding error

  WidgetsBinding.instance.deferFirstFrame();
  setupDependencies();
  await SessionManager.loadTokens();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
  );

  //FlutterNativeSplash.preserve(widgetsBinding: binding);

  // Firebase options (if needed)
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  setupLocator();
  final prefs = await SharedPreferences.getInstance();
  //final isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
  await locator<ThemeService>().loadThemeFromPrefs();
  // if (isBiometricEnabled) {
  //   final securityService = SecurityService();
  //   final success = await securityService.authenticate();
  //
  //   if (!success) {
  //     // Exit app or redirect to locked screen
  //    exit(0);
  //     return;
  await locator<ThemeService>().loadThemeFromPrefs();
  runApp( MyApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    WidgetsBinding.instance.allowFirstFrame();
  });
}

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Vitty.ai',
//       home: const SplashScreen(),
//       // theme: ThemeData.light(),
//       // darkTheme: ThemeData.dark(),
//       theme: ThemeData(
//         primarySwatch: Colors.deepOrange,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//     );
//   }
// }
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeService = locator<ThemeService>();


    return StreamBuilder<AppTheme>(
      stream: locator<ThemeService>().themeStream,
      builder: (context, snapshot) {
        final theme = snapshot.data ?? AppTheme.light;


        print("🟢 Theme changed: ${theme == AppTheme.dark ? "Dark" : "Light"}");

        return HeroControllerScope(
          controller: MaterialApp.createMaterialHeroController(),
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Vitty.ai',
            routerConfig: AppRouter.router,
            // home: const SplashScreen(),
            theme: ThemeData(
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
              // textTheme: TextTheme(
              //   bodyText1: TextStyle(color: theme.text),
              //   bodyText2: TextStyle(color: theme.text),
              // ),
            ),
          ),
        );
      },
    );
  }
}

// class SplashDecider extends StatefulWidget {
//   const SplashDecider({Key? key}) : super(key: key);
//
//   @override
//   State<SplashDecider> createState() => _SplashDeciderState();
// }
//
// class _SplashDeciderState extends State<SplashDecider> {
//   final BiometricService _biometricService = BiometricService();
//
//   @override
//   void initState() {
//     super.initState();
//     _checkAuthAndNavigate();
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
//     Future.delayed(const Duration(seconds: 2), () {
//       Navigator.pop(context); // Or exit the app
//     });
//   }
//
//
//   Future<void> _checkAuthAndNavigate() async {
//     final controller = Provider.of<AuthController>(context, listen: false);
//     final user = FirebaseAuth.instance.currentUser;
//
//     if (user != null) {
//       try {
//         final idToken = await user.getIdToken();
//         await controller.verifyPhoneOtp(idToken ?? "", context);
//       } catch (e) {
//         await SessionManager.clearToken();
//         _navigateTo(RouterApp());
//       }
//     } else {
//       await SessionManager.clearToken();
//       _navigateTo(RouterApp());
//     }
//   }
//
//   void _navigateTo(Widget screen) {
//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(builder: (_) => screen),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: SizedBox() // Simple loader
//     );
//   }
// }



// class SplashDecider extends StatefulWidget {
//   const SplashDecider({Key? key}) : super(key: key);
//
//   @override
//   State<SplashDecider> createState() => _SplashDeciderState();
// }
//
// class _SplashDeciderState extends State<SplashDecider> {
//   final BiometricService _biometricService = BiometricService();
//
//   @override
//   void initState() {
//     super.initState();
//     _checkAuthAndNavigate();
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
//     Future.delayed(const Duration(seconds: 2), () {
//       Navigator.pop(context); // Or exit the app
//     });
//   }
//
//   Future<void> _checkAuthAndNavigate() async {
//     final controller = Provider.of<AuthController>(context, listen: false);
//     final user = FirebaseAuth.instance.currentUser;
//
//     if (user != null) {
//       try {
//         final idToken = await user.getIdToken();
//         await controller.verifyPhoneOtp(idToken ?? "",(route) => na,);
//
//         // ✅ Firebase verify success ke baad ab biometric check
//         await _performBiometricAuth();
//       } catch (e) {
//         await SessionManager.clearToken();
//         _navigateTo(RouterApp());
//       }
//     } else {
//       await SessionManager.clearToken();
//       _navigateTo(RouterApp());
//     }
//   }
//
//   Future<void> _performBiometricAuth() async {
//     bool hasSupport = await _biometricService.hasBiometricSupport();
//     if (!hasSupport) {
//       _showError('Your device does not support biometrics.');
//       return;
//     }
//
//     bool isAuthenticated = await _biometricService.authenticateUser();
//     if (isAuthenticated) {
//       _navigateTo(RouterApp()); // ✅ After biometric success
//     } else {
//       _showError('Biometric authentication failed.');
//     }
//   }
//
//   void _navigateTo(Widget screen) {
//     if (!mounted) return;
//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(builder: (_) => screen),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(child: CircularProgressIndicator(color: Colors.black)),
//     );
//   }
// }





class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500), // ✅ Exactly 500ms
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack)),
    );

    _controller.forward().then((_) {
      // ✅ Immediate navigation after 500ms animation
      _instantNavigation();
    });
  }

  void _instantNavigation() async {
    final stopwatch = Stopwatch()..start();

    // ✅ Parallel loading of prefs and theme
    final futures = await Future.wait([
      SharedPreferences.getInstance(),
      locator<ThemeService>().loadThemeFromPrefs(),
    ]);

    final prefs = futures[0] as SharedPreferences;
    final isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;

    // ✅ Handle biometrics if needed
    if (isBiometricEnabled) {
      final securityService = SecurityService();
      final success = await securityService.authenticate();
      if (!success) {
        exit(0);
        return;
      }
    }

    // ✅ Quick token check from memory (no validation)
    final token = prefs.getString("access_token");
    final uid = prefs.getString("uid");

    if (_navigated) return;
    _navigated = true;

    if (token != null && uid != null) {
      // ✅ Token exists - navigate to home immediately
      context.go('/home');

      stopwatch.stop();
      print("⚡ Splash→Home in ${stopwatch.elapsedMilliseconds}ms");

      // ✅ Background token validation (non-blocking)
      _validateTokenInBackground();
    } else {
      // ✅ No token - go to login
      context.go('/phone_otp');

      stopwatch.stop();
      print("🚫 No token. Splash→Login in ${stopwatch.elapsedMilliseconds}ms");
    }
  }

  // ✅ Background token validation - won't block UI
  void _validateTokenInBackground() async {
    try {
      print("🔄 Starting background token validation...");

      // ✅ Load tokens into SessionManager
      await SessionManager.loadTokens();

      // ✅ Check if token is valid
      final token = SessionManager.token;
      if (token != null && !SessionManager.isTokenExpired(token)) {
        print("✅ Token is valid - no refresh needed");

        // ✅ Fetch user profile if needed
        try {
          await locator<AuthService>().fetchUserProfile();
          print("✅ User profile loaded in background");
        } catch (e) {
          print("⚠️ Profile fetch failed: $e");
        }
        return;
      }

      // ✅ Token expired - try refresh
      print("🔄 Token expired, attempting refresh...");
      final refreshed = await SessionManager.tryRefreshToken();

      if (refreshed) {
        print("✅ Background token refresh successful");

        // ✅ Load user profile with new token
        try {
          await locator<AuthService>().fetchUserProfile();
          print("✅ User profile loaded after refresh");
        } catch (e) {
          print("⚠️ Profile fetch failed after refresh: $e");
        }
      } else {
        print("❌ Background token refresh failed");

        // ✅ Silent logout and redirect (only if multiple failures)
        _handleSilentLogout();
      }
    } catch (e) {
      print("❌ Background validation error: $e");
      // ✅ Continue - don't disrupt user experience
    }
  }

  // ✅ Handle silent logout without disrupting UX
  void _handleSilentLogout() async {
    try {
      // ✅ Clear tokens
      await SessionManager.clearToken();

      // ✅ Wait a bit before redirecting (let user see home page first)
      await Future.delayed(Duration(seconds: 2));

      // ✅ Only redirect if user is still on the app
      if (mounted) {
        print("🚪 Redirecting to login due to invalid session");
        context.go('/phone_otp');
      }
    } catch (e) {
      print("❌ Silent logout error: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return Scaffold(
      backgroundColor: theme.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'penny_logo',
                    child: Image.asset(
                      'assets/images/new_app_logo.png',
                      width: screenWidth * 0.4,
                      height: screenHeight * 0.09,
                    ),
                  ),
                  Image.asset(
                    'assets/images/Vitty.ai.png',
                    width: screenWidth * 0.4,
                    height: screenHeight * 0.1,
                  ),
                  Image.asset(
                    'assets/images/वित्तीय.png',
                    width: screenWidth * 0.2,
                    height: screenHeight * 0.020,
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


class HeroLogo extends StatelessWidget {
  final double width;
  final double height;
  final String asset;

  const HeroLogo({
    Key? key,
    required this.width,
    required this.height,
    required this.asset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'penny_logo',
      child: Material(
        color: Colors.transparent,
        child: Image.asset(
          asset,
          width: width,
          height: height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}




// class SplashScreen extends StatefulWidget {
//   const SplashScreen({Key? key}) : super(key: key);
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _opacityAnimation;
//   late Animation<double> _scaleAnimation;
//   late Animation<Offset> _slideAnimation;
//   bool _navigated = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // _controller = AnimationController(
//     //   duration: const Duration(milliseconds: 1500),
//     //   vsync: this,
//     // );
//     //
//     // _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//     //   CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
//     // );
//     //
//     // _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
//     //   CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.8, curve: Curves.easeOutBack)),
//     // );
//     //
//     // _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
//     //   CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0, curve: Curves.easeOut)),
//     // );
//     //
//     // // 👇 Start animation after native splash disappears
//     // Future.delayed(const Duration(milliseconds: 300), () {
//     //   _controller.forward().then((_) => _handleSessionCheck());
//     // });
//
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 1500),
//       vsync: this,
//     );
//
//     _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
//     );
//
//     _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
//       CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack)),
//     );
//
//     // Remove the _slideAnimation completely
//
//     // Start animation after native splash disappears
//     Future.delayed(const Duration(milliseconds: 300), () {
//       _controller.forward().then((_) => _handleSessionCheck());
//     });
//   }
//
//   Future<void> _handleSessionCheck() async {
//     final controller = Provider.of<AuthController>(context, listen: false);
//     final firebaseUser = FirebaseAuth.instance.currentUser;
//     final token = SessionManager.token;
//     print(token);
//
//     if (firebaseUser != null) {
//       try {
//         final idToken = await firebaseUser.getIdToken();
//         await controller.verifyPhoneOtp(idToken ?? "", context);
//       } catch (e) {
//         await SessionManager.clearToken();
//         _navigateTo(const RouterApp());
//       }
//     } else {
//       await SessionManager.clearToken();
//       _navigateTo(const RouterApp());
//     }
//   }
//
//   void _navigateTo(Widget screen) {
//     if (_navigated) return;
//     _navigated = true;
//
//     Navigator.of(context).pushReplacement(
//       PageRouteBuilder(
//         transitionDuration: const Duration(milliseconds: 800),
//         pageBuilder: (_, __, ___) => screen,
//         transitionsBuilder: (_, animation, __, child) => FadeTransition(
//           opacity: animation,
//           child: child,
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: AnimatedBuilder(
//           animation: _controller,
//           builder: (context, child) => Opacity(
//             opacity: _opacityAnimation.value,
//             child: Transform.scale(
//               scale: _scaleAnimation.value,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Hero(
//                     tag: 'penny_logo',
//                     child: Image.asset(
//                       'assets/images/splash_logo.png',
//                       width: screenWidth * 0.4,
//                       height: screenHeight * 0.25,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }





class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    // Force status + nav bars visible
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
      SystemUiOverlay.top,
      SystemUiOverlay.bottom,
    ]);

    // Style them
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChatGPTBottomSheetWrapper(
      // ✅ this is the animated + scalable area
      child: Builder(
        builder: (context) {
          return Scaffold(
            extendBodyBehindAppBar: false,
            backgroundColor: Colors.grey[100],
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                "ChatGPT-Style Sheet",
                style: TextStyle(color: Colors.black),
              ),
              iconTheme: const IconThemeData(color: Colors.black),
            ),
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Text('App Drawer'),
                  ),
                  ListTile(
                    title: const Text('Item 1'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('Item 2'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            body: const Center(
              child: Text("Main Content"),
            ),
          );
        }
      ),

      // ✅ this is your bottom sheet
      bottomSheet: Container(
        height: 890,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
        padding: const EdgeInsets.all(20),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Portfolio Action",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text("Add/remove from your portfolio here."),
          ],
        ),
      ),
    );
  }
}



class ChatGPTBottomSheetWrapper extends StatefulWidget {
  final Widget child;       // Your main screen content
  final Widget bottomSheet; // The animated bottom sheet

  const ChatGPTBottomSheetWrapper({
    super.key,
    required this.child,
    required this.bottomSheet,
  });

  @override
  ChatGPTBottomSheetWrapperState createState() => ChatGPTBottomSheetWrapperState();
}

class ChatGPTBottomSheetWrapperState extends State<ChatGPTBottomSheetWrapper>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _sheetHeightFactor;

  bool _isSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _sheetHeightFactor = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  void openSheet() {
    if (!_isSheetOpen) {
      setState(() => _isSheetOpen = true);
      _controller.forward();
    }
  }

  void closeSheet() async {
    if (_isSheetOpen) {
      await _controller.reverse();
      if (mounted) setState(() => _isSheetOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final screenHeight = mediaQuery.size.height;
    final maxSheetHeight = screenHeight * 0.93;
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    // 80% of screen height

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _isSheetOpen ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Stack(
        children: [
          // Main content with scale and slide animation
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final topPadding = Tween<double>(begin: 0.0, end: 55.0).transform(_controller.value);
              final horizontalPadding = Tween<double>(begin: 0.0, end: 10.0).transform(_controller.value);

              return Padding(
                padding: EdgeInsets.only(
                  top: topPadding,
                  left: horizontalPadding,
                  right: horizontalPadding,
                ),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  alignment: Alignment.topCenter,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_isSheetOpen ? 20 : 0),
                    child: AbsorbPointer(
                      absorbing: _isSheetOpen,
                      child: widget.child,
                    ),
                  ),
                ),
              );
            },
          ),

          // Overlay for dimming
          if (_isSheetOpen)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => GestureDetector(
                onTap: closeSheet,
                child: Container(
                  color: Colors.black.withOpacity(0.3 * _controller.value),
                ),
              ),
            ),

          // Bottom sheet with height animation
          if (_isSheetOpen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final height = maxSheetHeight * _sheetHeightFactor.value;

                  return Container(
                    height: height,
                    decoration:  BoxDecoration(
                      color: theme.background,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 20,
                          bottom: bottomPadding + 20,
                        ),
                        child: widget.bottomSheet,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// class ChatGPTBottomSheetWrapper extends StatefulWidget {
//   final Widget child; // your main screen
//   final Widget bottomSheet; // your custom bottom sheet
//
//   const ChatGPTBottomSheetWrapper({
//     super.key,
//     required this.child,
//     required this.bottomSheet,
//   });
//
//   @override
//   State<ChatGPTBottomSheetWrapper> createState() =>
//       ChatGPTBottomSheetWrapperState();
// }
//
// class ChatGPTBottomSheetWrapperState extends State<ChatGPTBottomSheetWrapper>
//     with TickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _scaleAnimation;
//   late Animation<Offset> _slideAnimation;
//
//   bool _isSheetOpen = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//
//     _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
//     );
//
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 1),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
//   }
//
//   void openSheet() {
//     setState(() => _isSheetOpen = true);
//     _controller.forward();
//   }
//
//   void closeSheet() async {
//     await _controller.reverse();
//     if (mounted) setState(() => _isSheetOpen = false);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value:  _isSheetOpen ? SystemUiOverlayStyle.light :  SystemUiOverlayStyle.dark, // dark icons on white background
//       child: Stack(
//         children: [
//           AnimatedBuilder(
//               animation: _controller,
//               builder: (context, child) =>
//               //     Transform.scale(
//               //   scale: _scaleAnimation.value,
//               //   child: AbsorbPointer(
//               //     absorbing: _isSheetOpen,
//               //     child: widget.child,
//               //   ),
//               // ),
//               Column(
//                 children: [
//                   // Fixed: system status bar spacing
//                   Container(
//                     height: 40,
//                     color: _isSheetOpen ? Colors.black : Colors.white,
//                   ),
//                   Expanded(
//                     child:
//                     // AnimatedBuilder(
//                     //   animation: _controller,
//                     //   builder: (context, child) => Transform.scale(
//                     //     scale:  _isSheetOpen ?_scaleAnimation.value - 0.07 : _scaleAnimation.value,
//                     //     alignment: Alignment.topCenter,
//                     //     child: ClipRRect(
//                     //       borderRadius: _isSheetOpen
//                     //           ? BorderRadius.circular(20)
//                     //           : BorderRadius.zero, // ✅ Apply rounded corners only during sheet open
//                     //       child: AbsorbPointer(
//                     //         absorbing: _isSheetOpen,
//                     //         child: widget.child,
//                     //       ),
//                     //     ),
//                     //   ),
//                     // ),
//                     // AnimatedBuilder(
//                     //   animation: _controller,
//                     //   builder: (context, child) {
//                     //     final slideY = Tween<double>(
//                     //       begin: 0.0,
//                     //       end: 0.0,
//                     //     ).transform(_controller.value);
//                     //
//                     //     return Transform.translate(
//                     //       offset: Offset(0, slideY),
//                     //       child: Container(
//                     //         decoration: BoxDecoration(
//                     //           color: Colors.white,
//                     //           borderRadius: _isSheetOpen ?BorderRadius.circular(20) : null
//                     //         ),
//                     //         height: MediaQuery.of(context).padding.top,
//                     //        // 👈 ChatGPT-style overlay
//                     //       ),
//                     //     );
//                     //   },
//                     // ),
//                     AnimatedBuilder(
//                       animation: _controller,
//                       builder: (context, child) {
//                         final slideY = Tween<double>(
//                           begin: 0.0,
//                           end: 0.0,
//                         ).transform(_controller.value);
//
//                         final scaleX = Tween<double>(
//                           begin: 1.0,
//                           end: 0.91, // 👈 width shrink like ChatGPT
//                         ).transform(_controller.value);
//
//                         return Transform(
//                           alignment: Alignment.topCenter,
//                           transform: Matrix4.identity()
//                             ..translate(0.0, slideY)
//                             ..scale(scaleX, 1.0), // ✅ shrink only width
//                           child: Container(
//                             height: MediaQuery.of(context).padding.top,
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: _isSheetOpen
//                                   ? BorderRadius.circular(20)
//                                   : null,
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//
//
//                   ),
//                 ],
//               )
//
//           ),
//
//           // Dimmed background
//           if (_isSheetOpen)
//             GestureDetector(
//               onTap: closeSheet,
//               child: Container(
//                 color: Colors.black.withOpacity(0.3),
//               ),
//             ),
//
//           // Bottom Sheet
//           if (_isSheetOpen)
//             SlideTransition(
//               position: _slideAnimation,
//               child: Align(
//                 alignment: Alignment.bottomCenter,
//                 child: SafeArea( // ✅ Bottom padding for notched phones
//                   top: false,
//                   bottom: false,
//                   child: widget.bottomSheet,
//                 ),
//               ),
//             ),
//
//           // FAB or trigger
//           Positioned(
//             bottom: 40,
//             right: 24,
//             child: FloatingActionButton.extended(
//               onPressed: openSheet,
//               icon: const Icon(Icons.add),
//               label: const Text("Open Sheet"),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



//
// class ChatPage extends StatefulWidget {
//   const ChatPage({super.key});
//   @override
//   State<ChatPage> createState() => _ChatPageState();
// }
//
// class _ChatPageState extends State<ChatPage> {
//   final ScrollController _scrollController = ScrollController();
//
//   @override
//   void initState() {
//     super.initState();
//     _scrollController.addListener(() {
//       print('🌀 Offset: ${_scrollController.offset}');
//       print('📏 MinExtent: ${_scrollController.position.minScrollExtent}');
//       print('📏 MaxExtent: ${_scrollController.position.maxScrollExtent}');
//     });
//   }
//
//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Chat UI")),
//       body: SingleChildScrollView(
//         controller: _scrollController,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: const [
//             UserMessageBubble(initialHeight: 60, message: "Hi, what's the weather today?"),
//             BotMessageBubble(initialHeight: 60, message: "The weather is sunny with 28°C."),
//             // UserMessageBubble(initialHeight: 60, message: "Thanks! And tomorrow?"),
//             // BotMessageBubble(initialHeight: 60, message: "Tomorrow will be cloudy with a chance of rain."),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class UserMessageBubble extends StatefulWidget {
//   final double initialHeight;
//   final String message;
//
//   const UserMessageBubble({
//     super.key,
//     required this.initialHeight,
//     required this.message,
//   });
//
//   @override
//   State<UserMessageBubble> createState() => _UserMessageBubbleState();
// }
//
// class _UserMessageBubbleState extends State<UserMessageBubble> {
//   late double height;
//
//   @override
//   void initState() {
//     super.initState();
//     height = widget.initialHeight;
//   }
//
//   void _increaseHeight() {
//     setState(() {
//       height += 40;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: Alignment.centerRight,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           AnimatedContainer(
//             duration: const Duration(milliseconds: 300),
//             margin: const EdgeInsets.only(top: 20, right: 16),
//             padding: const EdgeInsets.all(12),
//             height: height,
//             width: MediaQuery.of(context).size.width * 0.7,
//             decoration: BoxDecoration(
//               color: Colors.blue.shade100,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Text(widget.message),
//           ),
//         TextButton(onPressed: _increaseHeight, child: const Text("Increase Height")),
//         ],
//       ),
//     );
//   }
// }
//
// class BotMessageBubble extends StatefulWidget {
//   final double initialHeight;
//   final String message;
//
//   const BotMessageBubble({
//     super.key,
//     required this.initialHeight,
//     required this.message,
//   });
//
//   @override
//   State<BotMessageBubble> createState() => _BotMessageBubbleState();
// }
//
// class _BotMessageBubbleState extends State<BotMessageBubble> {
//   late double height;
//
//   @override
//   void initState() {
//     super.initState();
//     height = widget.initialHeight;
//   }
//
//   void _increaseHeight() {
//     setState(() {
//       height += 40;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           AnimatedContainer(
//             duration: const Duration(milliseconds: 300),
//             margin: const EdgeInsets.only(top: 20, left: 16),
//             padding: const EdgeInsets.all(12),
//             height: height,
//             width: MediaQuery.of(context).size.width * 0.7,
//             decoration: BoxDecoration(
//               color: Colors.grey.shade300,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Text(widget.message),
//           ),
//           TextButton(onPressed: _increaseHeight, child: const Text("Increase Height")),
//         ],
//       ),
//     );
//   }
// }



// class ChatPage extends StatefulWidget {
//   const ChatPage({super.key});
//   @override
//   State<ChatPage> createState() => _ChatPageState();
// }
//
// class _ChatPageState extends State<ChatPage> {
//   final ScrollController _scrollController = ScrollController();
//   final TextEditingController _controller = TextEditingController();
//
//   final List<Map<String, String>> _messages = []; // full list
//   bool _isStreaming = false;
//   bool _showOnlyLatestDuringStreaming = false;
//   double _chatHeight = 0;
//
//   final String _botResponse = '''
// Narendra Damodardas Modi is an Indian politician who has served as the prime minister of India since 2014. Modi was the chief minister of Gujarat from 2001 to 2014 and is the member of parliament for Varanasi. Wikipedia
// नरेन्द्र दामोदरदास मोदी 26 मई 2014 से अब तक लगातार तीसरी बार वे भारत के प्रधानमन्त्री बने हैं तथा वाराणसी से लोकसभा सांसद भी चुने गये हैं। वे भारत के प्रधानमन्त्री पद पर आसीन होने वाले स्वतन्त्र भारत में जन्मे प्रथम व्यक्ति हैं। इससे पहले वे 7 अक्तूबर 2001 से 22 मई 2014 तक गुजरात राज्य के मुख्यमन्त्री रह चुके हैं। विकिपीडिया
// ''';
//
//   void _scrollToLatestLikeChatPage() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final offset = _scrollController.offset;
//       var targetOffset = (offset + _chatHeight).clamp(
//         _scrollController.position.minScrollExtent,
//         _scrollController.position.maxScrollExtent,
//       );
//       _scrollController.animateTo(
//         targetOffset,
//         duration: const Duration(milliseconds: 400),
//         curve: Curves.easeOut,
//       );
//     });
//   }
//
//   void _sendMessage() {
//     final userText = _controller.text.trim();
//     if (userText.isEmpty || _isStreaming) return;
//
//     setState(() {
//       _messages.insert(0, {'role': 'user', 'text': userText});
//       _messages.insert(0, {'role': 'bot', 'text': ''});
//       _isStreaming = true;
//       _showOnlyLatestDuringStreaming = true;
//     });
//
//     _controller.clear();
//
//     _scrollToLatestLikeChatPage(); // 👈 ✅ use new function here
//
//     final lines = _botResponse.trim().split('\n');
//     int i = 0;
//
//     Timer.periodic(const Duration(milliseconds: 400), (timer) {
//       if (i >= lines.length) {
//         timer.cancel();
//         setState(() {
//           _isStreaming = false;
//           _showOnlyLatestDuringStreaming = false;
//         });
//         return;
//       }
//
//       setState(() {
//         _messages[0]['text'] = (_messages[0]['text']! + lines[i] + '\n').trim();
//         i++;
//       });
//     });
//   }
//
//
//   Widget _buildMessage(Map<String, String> msg) {
//     final isUser = msg['role'] == 'user';
//     // final isLatestUser = _showOnlyLatestDuringStreaming &&
//     //     _displayMessages.length >= 2 &&
//     //     msg == _displayMessages[1];
//
//     final isLatestUser = _showOnlyLatestDuringStreaming &&
//         _displayMessages.length >= 2 &&
//         msg == _displayMessages[_displayMessages.length - 2];
//
//     return Column(
//       children: [
//         Align(
//           alignment: isUser
//               ? (isLatestUser ? Alignment.topRight : Alignment.centerRight) // Latest user message top-right position
//               : Alignment.centerLeft,
//           child: Padding(
//             padding:  EdgeInsets.symmetric(vertical: 20),
//             child: Container(
//               margin: isLatestUser
//                   ? const EdgeInsets.only(top: 1, bottom: 1) // More space from top for latest message
//                   : const EdgeInsets.symmetric(vertical: 0,horizontal: 2),
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: isUser ? Colors.blue : Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               child: Text(
//                 msg['text']!,
//                 style: TextStyle(
//                   color: isUser ? Colors.white : Colors.black87,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   List<Map<String, String>> get _displayMessages {
//     if (_showOnlyLatestDuringStreaming && _messages.length >= 2) {
//       return _messages.sublist(0, 2); // only latest user+bot
//     }
//     return _messages;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("ChatGPT-Style Chat")),
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               Expanded(
//                 child: LayoutBuilder(
//           builder: (context, constraints){
//             return ListView.builder(
//               controller: _scrollController,
//               reverse: true,
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               itemCount: _displayMessages.length,
//               itemBuilder: (context, index) {
//                 return  Column(
//                   children: [
//                     _buildMessage(_displayMessages[index]),
//                     SizedBox(
//                 height: 220,
//                 ),
//                   ],
//                 );
//               },
//             );
//           }
//                 ),
//               ),
//               const Divider(height: 1),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         style: TextStyle(color: Colors.black),
//                         controller: _controller,
//                         textInputAction: TextInputAction.send,
//                         onSubmitted: (_) => _sendMessage(),
//                         decoration: const InputDecoration(
//                           hintText: "Type your message...",
//                           border: OutlineInputBorder(),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     IconButton(
//                       icon: const Icon(Icons.send),
//                       onPressed: _sendMessage,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }














