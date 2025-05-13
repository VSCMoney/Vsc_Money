// lib/config/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vscmoney/screens/presentation/auth/auth_screen.dart';
import 'package:vscmoney/screens/presentation/auth/phone_otp_scree.dart';
import 'package:vscmoney/screens/presentation/auth/profile_screen.dart';

import '../main.dart';
import '../screens/presentation/onboarding/onoarding_page.dart';


import 'package:vscmoney/screens/presentation/auth/otp_screen.dart';
import 'package:vscmoney/screens/presentation/home/assets.dart';
import 'package:vscmoney/screens/presentation/home/chat_screen.dart';
import 'package:vscmoney/screens/presentation/home/home_screen.dart';
import 'package:vscmoney/screens/presentation/home/portfolio_screen.dart';
import 'package:vscmoney/screens/presentation/onboarding/onboarding_screen_1.dart';
import 'package:vscmoney/screens/presentation/onboarding/onboarding_screen_2.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');


class AppRouter {
  static final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: slideUpTransition,
        ),
      ),
      // GoRoute(
      //   path: '/splash',
      //   pageBuilder: (context, state) => const MaterialPage(
      //     child: SplashScreen(),
      //     maintainState: true,
      //   ),
      // ),
      // Onboarding flow
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingPage(),
          transitionsBuilder: slideUpTransition,
        ),
      ),
      GoRoute(
        path: '/onboarding/1',
        name: 'onboarding1',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const InvestmentPlanScreen(),
          transitionsBuilder: slideUpTransition,
        ),
      ),
      GoRoute(
        path: '/onboarding/2',
        name: 'onboarding2',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: slideLeftTransition,
        ),
      ),

      // Auth flow
      GoRoute(
        path: '/auth',
        name: 'auth',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AuthScreen(),
          transitionsBuilder: slideLeftTransition,
        ),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        pageBuilder: (context, state) {
          final extra = state.extra as Map?;
          final phone = extra?['phone'] as String?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: OtpVerification(phoneNumber: phone),
            transitionsBuilder: slideLeftTransition,
          );
        },
      ),
      // Home flow
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DashboardScreen(),
          transitionsBuilder: fadeTransition,
        ),
      ),
      // GoRoute(
      //   path: '/home',
      //   pageBuilder: (context, state) {
      //     return CustomTransitionPage(
      //       key: state.pageKey,
      //       child: const DashboardScreen(),
      //       transitionsBuilder: (context, animation, secondaryAnimation, child) {
      //         return FadeTransition(
      //           opacity: animation,
      //           child: child,
      //         );
      //       },
      //     );
      //   },
      // ),




      GoRoute(
        path: '/chat',
        name: 'chat',
        pageBuilder: (context, state) {
          final extra = state.extra as Map?;
          if (extra == null || !extra.containsKey('session') || !extra.containsKey('chatService')) {
            return _errorPage(state, 'ChatSession or ChatService missing');
          }

          return CustomTransitionPage(
            key: state.pageKey,
            child: ChatScreen(
              session: extra['session'],
              chatService: extra['chatService'],
            ),
            transitionsBuilder: slideLeftTransition,
          );
        },
      ),
      GoRoute(
        path: '/portfolio',
        name: 'portfolio',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: GoalsPage(),
          transitionsBuilder: slideLeftTransition,
        ),
      ),
      GoRoute(
        path: '/assets',
        name: 'assets',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Assets(),
          transitionsBuilder: slideLeftTransition,
        ),
      ),
      GoRoute(
        path: '/phone_otp',
        name: 'phone_otp',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PhoneOtpScreen(),
          transitionsBuilder: slideLeftTransition,
        ),
      ),
      GoRoute(
        path: '/enter_name',
        name: 'enter_name',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EnterNameScreen(),
          transitionsBuilder: slideLeftTransition,
        ),
      ),
    ],

    errorPageBuilder: (context, state) => _errorPage(state, state.error.toString()),

    redirect: (context, state) {
      // Add logic here for auth or onboarding state
      return null;
    },
  );

  static Page<dynamic> _errorPage(GoRouterState state, String message) {
    return MaterialPage(
      key: state.pageKey,
      child: Scaffold(
        body: Center(
          child: Text('Error: $message'),
        ),
      ),
    );
  }
}








// Fade transition
Widget fadeTransition(BuildContext context, Animation<double> animation,
    Animation<double> secondaryAnimation, Widget child) {
  return FadeTransition(
    opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
    child: child,
  );
}

// Slide up transition
Widget slideUpTransition(BuildContext context, Animation<double> animation,
    Animation<double> secondaryAnimation, Widget child) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutQuart,
    )),
    child: child,
  );
}

// Slide left transition
Widget slideLeftTransition(BuildContext context, Animation<double> animation,
    Animation<double> secondaryAnimation, Widget child) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    )),
    child: child,
  );
}

// Scale and fade transition
Widget scaleTransition(BuildContext context, Animation<double> animation,
    Animation<double> secondaryAnimation, Widget child) {
  return ScaleTransition(
    scale: CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ),
    child: FadeTransition(
      opacity: CurveTween(curve: Curves.easeIn).animate(animation),
      child: child,
    ),
  );
}

// Shared axis transition (horizontal)
Widget sharedAxisTransition(BuildContext context, Animation<double> animation,
    Animation<double> secondaryAnimation, Widget child) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      return FadeTransition(
        opacity: animation,
        child: Transform.translate(
          offset: Offset(100 * (1 - animation.value), 0),
          child: child,
        ),
      );
    },
    child: child,
  );
}