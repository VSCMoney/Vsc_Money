
import 'yamnet_vad_platform_interface.dart';

class YamnetVad {
  Future<String?> getPlatformVersion() {
    return YamnetVadPlatform.instance.getPlatformVersion();
  }
}
