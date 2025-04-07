// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';

class AuthProvider extends StatelessWidget {
  final Widget child;
  const AuthProvider({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthController>(
      create: (_) => AuthController()..autoLogin(),
      child: child,
    );
  }
}
