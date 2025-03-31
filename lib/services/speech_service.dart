// lib/services/speech_service.dart
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  Function(String)? onResult;

  SpeechService() {
    _speech = stt.SpeechToText();
  }

  Future<bool> initialize() async {
    return await _speech.initialize();
  }

  bool get isListening => _isListening;

  Future<void> startListening({Function(String)? onResultCallback}) async {
    bool available = await _speech.initialize();
    if (available) {
      _isListening = true;
      onResult = onResultCallback;

      _speech.listen(
        onResult: (result) {
          if (onResult != null) {
            onResult!(result.recognizedWords);
          }
        },
      );
    }
  }

  void stopListening() {
    if (_isListening) {
      _isListening = false;
      _speech.stop();
    }
  }
}