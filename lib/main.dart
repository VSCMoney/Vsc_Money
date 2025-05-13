import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vscmoney/screens/presentation/auth/profile_screen.dart';
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
import 'controllers/auth_controller.dart';
import 'controllers/session_manager.dart';
import 'core/helpers/themes.dart';
import 'firebase_options.dart';


final sl = GetIt.instance;

void setupDependencies() {
  sl.registerLazySingleton<ApiService>(() => ApiService());
}

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
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
  runApp( MyApp());
  //FlutterNativeSplash.remove();
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
    final themeService = GetIt.I<ThemeService>();

    return StreamBuilder<AppTheme>(
      stream: themeService.themeStream.distinct(),
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
              scaffoldBackgroundColor: theme.background,
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
  final AuthService _authService = locator<AuthService>();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack)),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
       // secureSplashRouting(); // 🧠 biometric only after full splash animation
     _handleSessionCheck();
      });
    });
  }

  void secureSplashRouting() async {
    final prefs = await SharedPreferences.getInstance();
    final isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    final themeService = locator<ThemeService>();
    await themeService.loadThemeFromPrefs();

    if (isBiometricEnabled) {
      final securityService = SecurityService();
      final success = await securityService.authenticate();
      if (!success) {
        exit(0);
        return;
      }
    }

    final isLoggedIn = await SessionManager.isLoggedIn();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (isLoggedIn) {
        context.go('/home');

        // 🔄 Refresh user profile silently
        final refreshed = await SessionManager.checkTokenValidityAndRefresh();
        if (refreshed) {
          await locator<AuthService>().fetchUserProfile();
        } else {
          await locator<AuthService>().logout();
          context.go('/phone_otp');
        }
      } else {
        context.go('/phone_otp');
      }
    });
  }



  void _handleSessionCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;

    if (isBiometricEnabled) {
      final securityService = SecurityService();
      final success = await securityService.authenticate();

      if (!success) {
        exit(0);
        return;
      }
    }

    // ✅ After biometric success → continue routing
    _authService.handleSessionCheck((flow) {
      switch (flow) {
        case AuthFlow.login:
          _navigateToPath('/phone_otp');
          break;
        case AuthFlow.nameEntry:
          _navigateToPath('/enter_name');
          break;
        case AuthFlow.home:
          _navigateToPath('/home');
          break;
      }
    });
  }


  void _navigateToPath(String path) {
    if (_navigated) return;
    _navigated = true;

    Future.delayed(const Duration(milliseconds: 600), () {
      context.go(path); // from go_router
    });
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

    return Scaffold(
      backgroundColor: Colors.white,
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
                      'assets/images/splash_logo.png',
                      width: screenWidth * 0.4,
                      height: screenHeight * 0.25,
                    ),
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





class RouterApp extends StatelessWidget {
  const RouterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
    );
  }
}



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
      child: Scaffold(
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
        body: const Center(
          child: Text("Main Content"),
        ),
      ),

      // ✅ this is your bottom sheet
      bottomSheet: Container(
        height: 760,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
  final Widget child; // your main screen
  final Widget bottomSheet; // your custom bottom sheet

  const ChatGPTBottomSheetWrapper({
    super.key,
    required this.child,
    required this.bottomSheet,
  });

  @override
  State<ChatGPTBottomSheetWrapper> createState() =>
      _ChatGPTBottomSheetWrapperState();
}

class _ChatGPTBottomSheetWrapperState extends State<ChatGPTBottomSheetWrapper>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

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
  }

  void _openSheet() {
    setState(() => _isSheetOpen = true);
    _controller.forward();
  }

  void _closeSheet() async {
    await _controller.reverse();
    if (mounted) setState(() => _isSheetOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:  _isSheetOpen ? SystemUiOverlayStyle.light :  SystemUiOverlayStyle.dark, // dark icons on white background
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) =>
            Column(
              children: [
                // Fixed: system status bar spacing
                Container(
                  height: 40,
                  color: _isSheetOpen ? Colors.black : Colors.white,
                ),
                Expanded(
                  child:
                  // AnimatedBuilder(
                  //   animation: _controller,
                  //   builder: (context, child) => Transform.scale(
                  //     scale:  _isSheetOpen ?_scaleAnimation.value - 0.07 : _scaleAnimation.value,
                  //     alignment: Alignment.topCenter,
                  //     child: ClipRRect(
                  //       borderRadius: _isSheetOpen
                  //           ? BorderRadius.circular(20)
                  //           : BorderRadius.zero, // ✅ Apply rounded corners only during sheet open
                  //       child: AbsorbPointer(
                  //         absorbing: _isSheetOpen,
                  //         child: widget.child,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // AnimatedBuilder(
                  //   animation: _controller,
                  //   builder: (context, child) {
                  //     final slideY = Tween<double>(
                  //       begin: 0.0,
                  //       end: 0.0,
                  //     ).transform(_controller.value);
                  //
                  //     return Transform.translate(
                  //       offset: Offset(0, slideY),
                  //       child: Container(
                  //         decoration: BoxDecoration(
                  //           color: Colors.white,
                  //           borderRadius: _isSheetOpen ?BorderRadius.circular(20) : null
                  //         ),
                  //         height: MediaQuery.of(context).padding.top,
                  //        // 👈 ChatGPT-style overlay
                  //       ),
                  //     );
                  //   },
                  // ),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final slideY = Tween<double>(
                        begin: 0.0,
                        end: 0.0,
                      ).transform(_controller.value);

                      final scaleX = Tween<double>(
                        begin: 1.0,
                        end: 0.91, // 👈 width shrink like ChatGPT
                      ).transform(_controller.value);

                      return Transform(
                        alignment: Alignment.topCenter,
                        transform: Matrix4.identity()
                          ..translate(0.0, slideY)
                          ..scale(scaleX, 1.0), // ✅ shrink only width
                        child: Container(
                          height: MediaQuery.of(context).padding.top,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: _isSheetOpen
                                ? BorderRadius.circular(20)
                                : null,
                          ),
                        ),
                      );
                    },
                  ),


                ),
              ],
            )

          ),

          // Dimmed background
          if (_isSheetOpen)
            GestureDetector(
              onTap: _closeSheet,
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),

          // Bottom Sheet
          if (_isSheetOpen)
            SlideTransition(
              position: _slideAnimation,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea( // ✅ Bottom padding for notched phones
                  top: false,
                  bottom: false,
                  child: widget.bottomSheet,
                ),
              ),
            ),

          // FAB or trigger
          Positioned(
            bottom: 40,
            right: 24,
            child: FloatingActionButton.extended(
              onPressed: _openSheet,
              icon: const Icon(Icons.add),
              label: const Text("Open Sheet"),
            ),
          ),
        ],
      ),
    );
  }
}



