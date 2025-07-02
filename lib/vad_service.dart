import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:vscmoney/webrtc_vad.dart';
import 'dart:math';

class VADService {
  final Pointer<Void> _vad;
  final int sampleRate = 16000;
  final int frameSize = 160; // 10ms of audio at 16kHz

  VADService() : _vad = vadCreate() {
    vadInit(_vad, sampleRate);
    const mode = 3; // ✅ Most aggressive: avoids background hum
    final result = vadSetMode(_vad, mode);
    print('🛠️ VAD mode set to $mode → result = $result');
  }

  bool isSpeech(Uint8List pcmBytes) {
    final ptr = calloc<Int16>(frameSize);
    final byteData = ByteData.sublistView(pcmBytes);
    for (int i = 0; i < frameSize; i++) {
      ptr[i] = byteData.getInt16(i * 2, Endian.little);
    }
    final result = vadProcess(_vad, sampleRate, ptr, frameSize);
    calloc.free(ptr);
    return result == 1;
  }

  void dispose() {
    vadFree(_vad);
  }
}
