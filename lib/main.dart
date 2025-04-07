import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vscmoney/providers/auth_provider.dart';
import 'package:vscmoney/routes/AppRoutes.dart';
import 'package:vscmoney/screens/presentation/auth/auth_screen.dart';
import 'package:vscmoney/screens/presentation/home/home_screen.dart';
import 'package:vscmoney/screens/presentation/onboarding/onoarding_page.dart';


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
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2000), () => _handleSessionCheck());
  }

  Future<void> _handleSessionCheck() async {
    // final isLoggedIn = await SessionManager.isLoggedIn();
    // final refreshed = await SessionManager.tryRefreshToken();
    //
    // if (isLoggedIn && refreshed) {
    //   _navigateTo(const DashboardScreen());
    // } else {
    //   await SessionManager.clearToken();
    //   _navigateTo(const RouterApp());
    // }8

    final controller = Provider.of<AuthController>(context, listen: false);
    final refreshed = await controller.checkTokenValidityAndRefresh();
    if (refreshed && controller.currentUser != null) {
      _navigateTo(const DashboardScreen());
    } else {
      _navigateTo(const RouterApp());
    }

  }

  void _navigateTo(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

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
          builder: (_, child) {
            return FadeTransition(
              opacity: _opacityAnimation,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Hero(
                  tag: 'penny_logo',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/Group.png', width: 100, height: 100),
                      const SizedBox(width: 16),
                      const Text(
                        'Penny',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE97733),
                        ),
                      ),
                    ],
                  ),
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