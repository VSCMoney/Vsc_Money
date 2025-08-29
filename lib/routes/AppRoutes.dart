import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vscmoney/constants/widgets.dart';
import 'package:vscmoney/screens/presentation/auth/auth_screen.dart';
import 'package:vscmoney/screens/presentation/auth/phone_otp_scree.dart';
import 'package:vscmoney/screens/presentation/auth/profile_screen.dart';
import 'package:vscmoney/screens/presentation/conversations.dart';
import 'package:vscmoney/screens/presentation/search_stock_screen.dart';
import 'package:vscmoney/screens/asset_page/assets_page.dart';

import '../models/chat_session.dart';
import '../screens/presentation/onboarding/onoarding_page.dart';


import 'package:vscmoney/screens/presentation/auth/otp_screen.dart';
import 'package:vscmoney/screens/presentation/home/assets.dart';
import 'package:vscmoney/screens/presentation/home/chat_screen.dart';
import 'package:vscmoney/screens/presentation/home/home_screen.dart';
import 'package:vscmoney/screens/presentation/home/portfolio_screen.dart';
import 'package:vscmoney/screens/presentation/onboarding/onboarding_screen_1.dart';
import 'package:vscmoney/screens/presentation/onboarding/onboarding_screen_2.dart';

import '../screens/presentation/splash_screen.dart';
import '../services/chat_service.dart';
import '../services/conversation_service.dart';
import '../services/locator.dart';
import '../testpage.dart';

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
          child: SplashScreen(),
         // child:  StockDetailPage(stockName: "Zomato", stockSymbol: "Zomato", onClose: (){}),
          transitionsBuilder: dissolveTransition,
        ),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          transitionDuration: Duration(milliseconds: 900),
          key: state.pageKey,
          child: const OnboardingPage(),
          transitionsBuilder: dissolveTransition,
        ),
      ),
      GoRoute(
        path: '/conversations',
        name: 'conversations',
        pageBuilder: (context, state) {
          final onSessionTap = state.extra as void Function(ChatSession)?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: Conversations(
              onSessionTap: onSessionTap,
              //onCreateNewChat: () {}, // optional
            ),
            transitionsBuilder: slideLeftTransition,
            fullscreenDialog: true,
          );
        },
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
      // GoRoute(
      //   path: '/otp',
      //   name: 'otp',
      //   pageBuilder: (context, state) {
      //     final extra = state.extra as Map?;
      //     final phone = extra?['phone'] as String?;
      //     return CustomTransitionPage(
      //       key: state.pageKey,
      //       child: OtpVerification(phoneNumber: phone),
      //       transitionsBuilder: slideLeftTransition,
      //     );
      //   },
      // ),
      // GoRoute(
      //   path: '/home',
      //   name: 'home',
      //   pageBuilder: (context, state) {
      //     final extra = state.extra as Map<String, dynamic>?;
      //     // final session = extra?['session'] as ChatSession?;
      //     final sessionId = state.uri.queryParameters['sessionId'];
      //
      //     return CustomTransitionPage(
      //       key: state.pageKey,
      //       child: HomeScreen(initialSession: sessionId), // ✅ no chatService or callback
      //       transitionDuration: const Duration(milliseconds: 300),
      //       transitionsBuilder: (context, animation, secondaryAnimation, child) {
      //         return FadeTransition(
      //           opacity: CurvedAnimation(
      //             parent: animation,
      //             curve: Curves.easeOut,
      //           ),
      //           child: child,
      //         );
      //       },
      //     );
      //   },
      // ),

// 1. Fix your GoRouter configuration
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) {
          // ✅ FIX: Get sessionId from query parameters
          final sessionId = state.uri.queryParameters['sessionId'];

          print("🔗 Router: Navigating to home with sessionId: $sessionId");

          return CustomTransitionPage(
            key: state.pageKey,
            child: HomeScreen(initialSession: sessionId), // ✅ FIXED: Use initialSessionId
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: child,
              );
            },
          );
        },
      ),







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
          child: PortfolioScreen(),
          transitionsBuilder: slideLeftTransition,
        ),
      ),
      GoRoute(
        path: '/goals',
        name: 'goals',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const GoalsPage(),
          transitionsBuilder: slideLeftTransition,
        ),
      ),
      GoRoute(
        path: '/phone_otp',
        name: 'phone_otp',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SignInPage(),
          transitionsBuilder: dissolveTransition,
        ),
      ),
      GoRoute(
        path: '/enter_name',
        name: 'enter_name',
        pageBuilder: (context, state) => CustomTransitionPage(
          transitionDuration: Duration(seconds:1 ),
          key: state.pageKey,
          child: const EnterNameScreen(),
          transitionsBuilder: dissolveTransition,
        ),
      ),
      GoRoute(
        path: '/premium',
        name: 'premium',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PremiumAccessScreen(),
          transitionsBuilder: slideLeftTransition,
        ),
      ),
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WebViewPage(
            url: 'https://piyushvitty.github.io/vitty-privacy/',
            title: 'Privacy Policy',
          ),
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







Widget dissolveTransition(BuildContext context, Animation<double> animation,
    Animation<double> secondaryAnimation, Widget child) {
  return FadeTransition(
    opacity: animation.drive(
      CurveTween(curve: Curves.easeInOut),
      // 👈 smoother easing
    ),
    child: child,
  );
}


// Fade transition
Widget fadeTransition(BuildContext context, Animation<double> animation,
    Animation<double> secondaryAnimation, Widget child) {
  return FadeTransition(
    opacity: CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut, // ✅ Faster curve
    ),
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

Widget fadeTransitions(BuildContext context, Animation<double> animation,
    Animation<double> secondaryAnimation, Widget child) {
  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: Curves.easeInOut, // ✅ smooth in-out
  );

  return FadeTransition(
    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
    child: child,
  );
}
