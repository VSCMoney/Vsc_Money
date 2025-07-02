import 'package:flutter_test/flutter_test.dart';
import 'package:yamnet_vad/yamnet_vad.dart';
import 'package:yamnet_vad/yamnet_vad_platform_interface.dart';
import 'package:yamnet_vad/yamnet_vad_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockYamnetVadPlatform
    with MockPlatformInterfaceMixin
    implements YamnetVadPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final YamnetVadPlatform initialPlatform = YamnetVadPlatform.instance;

  test('$MethodChannelYamnetVad is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelYamnetVad>());
  });

  test('getPlatformVersion', () async {
    YamnetVad yamnetVadPlugin = YamnetVad();
    MockYamnetVadPlatform fakePlatform = MockYamnetVadPlatform();
    YamnetVadPlatform.instance = fakePlatform;

    expect(await yamnetVadPlugin.getPlatformVersion(), '42');
  });
}
