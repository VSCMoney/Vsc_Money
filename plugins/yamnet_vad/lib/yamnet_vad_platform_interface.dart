import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'yamnet_vad_method_channel.dart';

abstract class YamnetVadPlatform extends PlatformInterface {
  /// Constructs a YamnetVadPlatform.
  YamnetVadPlatform() : super(token: _token);

  static final Object _token = Object();

  static YamnetVadPlatform _instance = MethodChannelYamnetVad();

  /// The default instance of [YamnetVadPlatform] to use.
  ///
  /// Defaults to [MethodChannelYamnetVad].
  static YamnetVadPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [YamnetVadPlatform] when
  /// they register themselves.
  static set instance(YamnetVadPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
