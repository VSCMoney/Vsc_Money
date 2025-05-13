// lib/core/setup_locator.dart
import 'package:get_it/get_it.dart';
import 'package:vscmoney/services/api_service.dart';
import 'package:vscmoney/services/biometric_service.dart';
import 'package:vscmoney/services/theme_service.dart';
import '../services/auth_service.dart';
import '../controllers/auth_controller.dart';
import 'chat_service.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<AuthService>(() => AuthService());
  locator.registerLazySingleton<ChatService>(() => ChatService(authToken: ""));
  locator.registerLazySingleton<SecurityService>(() => SecurityService());
  locator.registerLazySingleton<ThemeService>(() => ThemeService());

}
