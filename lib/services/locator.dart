// lib/core/setup_locator.dart
import 'package:get_it/get_it.dart';
import 'package:vscmoney/services/asset_service.dart';

import 'package:vscmoney/services/theme_service.dart';
import 'package:vscmoney/services/voice_service.dart';
import '../services/auth_service.dart';
import 'api_service.dart';
import 'chat_service.dart';
import 'conversation_service.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<EndPointService>(() => EndPointService());
  locator.registerLazySingleton<AuthService>(() => AuthService());
  locator.registerFactory<ConversationsService>(() => ConversationsService());
  locator.registerLazySingleton<ChatService>(() => ChatService());
  locator.registerLazySingleton<ThemeService>(() => ThemeService());
  locator.registerLazySingleton<AssetService>(() => AssetService());
  locator.registerSingleton<AudioService>(AudioService.instance);
}

