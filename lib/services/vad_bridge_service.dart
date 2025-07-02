import 'package:flutter/services.dart';

class VadBridge {
  static const MethodChannel _channel = MethodChannel('webrtc_vad');

  static Future<bool> isVoice(List<double> pcm) async {
    try {
      final result = await _channel.invokeMethod('detectVoice', {
        'pcm': pcm,
      });
      return result == true;
    } catch (e) {
      print("VAD error: $e");
      return false;
    }
  }
}
