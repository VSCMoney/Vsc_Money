import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:vscmoney/providers/auth_provider.dart';
import 'package:vscmoney/routes/AppRoutes.dart';
import 'package:vscmoney/screens/presentation/auth/auth_screen.dart';
import 'package:vscmoney/screens/presentation/home/home_screen.dart';
import 'package:vscmoney/screens/presentation/onboarding/onoarding_page.dart';
import 'package:vscmoney/services/chat_service.dart';


import 'controllers/auth_controller.dart';
import 'controllers/session_manager.dart';
import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await SessionManager.loadTokens();

  // For iOS, you need to provide the correct options from your Firebase console
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AuthProvider(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Penny App',
        home: SplashScreen(),
        theme: ThemeData(
          primarySwatch: Colors.deepOrange,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
      ),
    );
  }
}



class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Give time for animations to complete
    Future.delayed(const Duration(milliseconds: 2500), _handleSessionCheck);
  }

  Future<void> _handleSessionCheck() async {
    final controller = Provider.of<AuthController>(context, listen: false);
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser != null) {
      try {
        final idToken = await firebaseUser.getIdToken();
        print("MY FIREBASE ID TOKEN");
        print(idToken);
        await controller.verifyPhoneOtp(idToken ?? "", context);
        if (!mounted) return;
       // _navigateTo(const DashboardScreen());
      } catch (e) {
        await SessionManager.clearToken();
        _navigateTo(const RouterApp());
      }
    } else {
      await SessionManager.clearToken();
      _navigateTo(const RouterApp());
    }
  }

  bool _navigated = false;

  void _navigateTo(Widget screen) {
    if (_navigated) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }



  // void navigateToDashboard(BuildContext context) async {
  //   // ✅ Firebase user already verified at this point
  //   final user = FirebaseAuth.instance.currentUser;
  //   final idToken = await user?.getIdToken();
  //   final token = SessionManager.token;
  //
  //   if (idToken != null) {
  //     // Save token locally if needed
  //     await SessionManager.saveTokens(token!,user?.uid ?? "");
  //
  //     // 💬 Create new chat session automatically
  //     final newSession = await ChatService(authToken: token).createSession("New Chat");
  //
  //     // ✅ Navigate to dashboard and pass the session
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(
  //         builder: (_) => DashboardScreen(initialSession: newSession),
  //       ),
  //     );
  //   } else {
  //     Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RouterApp()));
  //   }
  // }



  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Hero(
                      tag: 'penny_logo',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/images/new_app_logo.png', width:100, height: 80),
                          const SizedBox(width: 16),
                          Image.asset('assets/images/Vitty.ai.png', width: 150, height: 100),
                        ],
                      ),
                    ),

                    const Text(
                      'वित्तीय',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFE83F04),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}




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