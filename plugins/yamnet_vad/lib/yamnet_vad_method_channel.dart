import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'yamnet_vad_platform_interface.dart';

/// An implementation of [YamnetVadPlatform] that uses method channels.
class MethodChannelYamnetVad extends YamnetVadPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('yamnet_vad');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
