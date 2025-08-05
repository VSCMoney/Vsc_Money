import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:rxdart/rxdart.dart';

class AudioService {
  static AudioService? _instance;
  static AudioService get instance => _instance ??= AudioService._();
  AudioService._();

  // Audio recorder
  final AudioRecorder _audioRecorder = AudioRecorder();

  // Platform channels
  static const _androidMethodChannel = MethodChannel('native_vad');
  static const _androidEventChannel = EventChannel('native_vad/events');
  static const _iosMethodChannel = MethodChannel('yamnet_channel');
  static const _iosEventChannel = EventChannel('yamnet_event_channel');

  // Streams for reactive state management
  final BehaviorSubject<bool> _isListeningSubject = BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<bool> _isTranscribingSubject = BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<bool> _isSpeakingSubject = BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<double> _currentRmsSubject = BehaviorSubject<double>.seeded(0.0);
  final BehaviorSubject<double> _displayedRmsSubject = BehaviorSubject<double>.seeded(0.0);
  final BehaviorSubject<String> _transcriptSubject = BehaviorSubject<String>.seeded('');
  final BehaviorSubject<String> _recordingDurationSubject = BehaviorSubject<String>.seeded('00:00');
  final BehaviorSubject<String> _errorSubject = BehaviorSubject<String>.seeded('');

  // Public streams
  Stream<bool> get isListening$ => _isListeningSubject.stream;
  Stream<bool> get isTranscribing$ => _isTranscribingSubject.stream;
  Stream<bool> get isSpeaking$ => _isSpeakingSubject.stream;
  Stream<double> get currentRms$ => _currentRmsSubject.stream;
  Stream<double> get displayedRms$ => _displayedRmsSubject.stream;
  Stream<String> get transcript$ => _transcriptSubject.stream;
  Stream<String> get recordingDuration$ => _recordingDurationSubject.stream;
  Stream<String> get error$ => _errorSubject.stream;

  // Getters for current values
  bool get isListening => _isListeningSubject.value;
  bool get isTranscribing => _isTranscribingSubject.value;
  bool get isSpeaking => _isSpeakingSubject.value;
  double get currentRms => _currentRmsSubject.value;
  double get displayedRms => _displayedRmsSubject.value;
  String get transcript => _transcriptSubject.value;
  String get recordingDuration => _recordingDurationSubject.value;

  // Private variables
  StreamSubscription? _vadSubscription;
  Timer? _rmsTimer;
  Timer? _durationTimer;
  Stopwatch _speechTimer = Stopwatch();
  String _recordingPath = '';
  String _recognizedBackupText = '';

  // Configuration
  //static const String _baseUrl = 'http://127.0.0.1:8000';
  static const String _baseUrl = 'http://192.168.1.2:8000';
  // static const String _baseUrl = "https://fastapi-chatbot-717280964807.asia-south1.run.app";

  /// Initialize the audio service
  Future<void> initialize() async {
    _startRmsSmoothing();
  }

  /// Start recording with VAD
  Future<bool> startRecording({String? existingText}) async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        _errorSubject.add('Microphone permission not granted');
        return false;
      }

      // Store existing text as backup
      _recognizedBackupText = existingText ?? '';

      // Setup recording path
      final dir = await getTemporaryDirectory();
      _recordingPath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav';

      final recordConfig = RecordConfig(
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      );

      // Start recording
      await _audioRecorder.start(recordConfig, path: _recordingPath);

      // Start VAD
      await _startNativeVad();

      // Start duration timer
      _startDurationTimer();

      // Update state
      _isListeningSubject.add(true);
      _isTranscribingSubject.add(false);
      _recordingDurationSubject.add('00:00');

      debugPrint('🎤 Recording started at: $_recordingPath');
      return true;
    } catch (e) {
      debugPrint('❌ Error starting recording: $e');
      _errorSubject.add('Failed to start recording: $e');
      return false;
    }
  }

  /// Stop recording and transcribe
  Future<void> stopRecordingAndTranscribe() async {
    try {
      _isTranscribingSubject.add(true);

      // Stop timers
      _stopDurationTimer();

      // Stop recording
      final path = await _audioRecorder.stop();
      if (path != null) _recordingPath = path;

      // Stop VAD
      await _stopNativeVad();

      // Transcribe audio
      await _transcribeAudio();

    } catch (e) {
      debugPrint('❌ Error stopping recording: $e');
      _errorSubject.add('Failed to stop recording: $e');
    } finally {
      _isListeningSubject.add(false);
      _isTranscribingSubject.add(false);
    }
  }

  /// Cancel recording without transcription
  Future<void> cancelRecording() async {
    try {
      // Stop timers
      _stopDurationTimer();

      // Stop recording
      await _audioRecorder.stop();

      // Stop VAD
      await _stopNativeVad();

      // Restore backup text if any
      if (_recognizedBackupText.isNotEmpty) {
        _transcriptSubject.add(_recognizedBackupText);
      }

    } catch (e) {
      debugPrint('❌ Error canceling recording: $e');
      _errorSubject.add('Failed to cancel recording: $e');
    } finally {
      _isListeningSubject.add(false);
      _isTranscribingSubject.add(false);
      _recognizedBackupText = '';
    }
  }

  /// Update transcript manually (for external speech recognition)
  void updateTranscript(String text) {
    _transcriptSubject.add(text);
  }

  /// Clear transcript
  void clearTranscript() {
    _transcriptSubject.add('');
  }

  /// Clear error
  void clearError() {
    _errorSubject.add('');
  }

  // Private methods

  Future<void> _startNativeVad() async {
    try {
      await _vadSubscription?.cancel();

      final EventChannel eventChannel = Platform.isIOS ? _iosEventChannel : _androidEventChannel;
      final MethodChannel methodChannel = Platform.isIOS ? _iosMethodChannel : _androidMethodChannel;

      _vadSubscription = eventChannel.receiveBroadcastStream().listen((event) {
        final isSpeech = event['isSpeech'] ?? event['state'] == 'speech_detected' || false;
        final rms = (event['rms'] ?? event['rms_db'] ?? 0.0).toDouble();

        debugPrint('🎙️ VAD => isSpeech=$isSpeech | rms=${rms.toStringAsFixed(2)}');

        _isSpeakingSubject.add(isSpeech);
        _currentRmsSubject.add(rms);
      });

      await methodChannel.invokeMethod('start');
    } catch (e) {
      debugPrint('❌ startNativeVad error: $e');
      _errorSubject.add('Failed to start voice detection: $e');
    }
  }

  Future<void> _stopNativeVad() async {
    try {
      final MethodChannel methodChannel = Platform.isIOS ? _iosMethodChannel : _androidMethodChannel;
      await methodChannel.invokeMethod('stop');
      await _vadSubscription?.cancel();
      _vadSubscription = null;

      _isSpeakingSubject.add(false);
      _currentRmsSubject.add(0.0);
      _displayedRmsSubject.add(0.0);
    } catch (e) {
      debugPrint('❌ stopNativeVad error: $e');
    }
  }

  void _startRmsSmoothing() {
    _rmsTimer?.cancel();
    const smoothingFactor = 0.2;

    _rmsTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      double difference = (_currentRmsSubject.value - _displayedRmsSubject.value).abs();
      if (difference > 0.001) {
        double newDisplayedRms = _displayedRmsSubject.value +
            (_currentRmsSubject.value - _displayedRmsSubject.value) * smoothingFactor;
        _displayedRmsSubject.add(newDisplayedRms);
      }
    });
  }

  void _stopRmsSmoothing() {
    _rmsTimer?.cancel();
    _rmsTimer = null;
  }

  void _startDurationTimer() {
    _speechTimer.reset();
    _speechTimer.start();

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _recordingDurationSubject.add(_formatDuration(_speechTimer.elapsed));
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _speechTimer.stop();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;

    if (minutes < 10) {
      return "${minutes}:${seconds.toString().padLeft(2, '0')}";
    } else {
      return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _transcribeAudio() async {
    debugPrint("🎤 Starting transcription process");

    if (_recordingPath.isEmpty) {
      debugPrint("❌ Recording path is empty");
      _errorSubject.add('No recording found');
      return;
    }

    final file = File(_recordingPath);
    if (!file.existsSync()) {
      debugPrint("❌ File not found at: $_recordingPath");
      _errorSubject.add('Recording file not found');
      return;
    }

    debugPrint("📁 File size: ${file.lengthSync()} bytes");

    try {
      debugPrint("⏳ Sending file to transcription API");

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/audio/transcribe'),
      );

      var multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType('audio', 'wav'),
      );

      debugPrint('📤 Uploading file: ${multipartFile.filename}, size: ${multipartFile.length}');
      request.files.add(multipartFile);

      var response = await request.send();
      debugPrint('✅ Response status: ${response.statusCode}');

      final responseBody = await response.stream.bytesToString();
      debugPrint('📩 Response body: $responseBody');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        final transcript = jsonResponse['transcript'] ?? '';
        debugPrint('📄 Transcript received: $transcript');

        if (transcript.isNotEmpty &&
            transcript != 'No speech detected. Please speak clearly and try again.') {

          // Combine with existing text if any
          final existingText = _recognizedBackupText.trim();
          final newText = existingText.isEmpty ? transcript : '$existingText $transcript';

          _transcriptSubject.add(newText);
          _recognizedBackupText = '';

        } else {
          // Keep backup text if transcription failed
          if (_recognizedBackupText.isNotEmpty) {
            _transcriptSubject.add(_recognizedBackupText);
          } else {
            _errorSubject.add('Could not transcribe audio. Please try again.');
          }
        }
      } else {
        debugPrint('❌ Transcription failed with status: ${response.statusCode}');
        _errorSubject.add('Transcription failed. Please try again.');
      }
    } catch (e) {
      debugPrint('🔥 Exception during transcription: $e');
      _errorSubject.add('Transcription error: $e');
    }
  }

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  /// Request microphone permission
  Future<bool> requestPermission() async {
    return await _audioRecorder.hasPermission();
  }

  /// Get current recording file path
  String get recordingPath => _recordingPath;

  /// Check if currently recording
  bool get hasActiveRecording => _recordingPath.isNotEmpty && isListening;

  /// Set custom transcription URL
  void setTranscriptionUrl(String url) {
    // You can make _baseUrl non-const and allow customization
  }

  /// Pause recording (if supported by your audio recorder)
  Future<void> pauseRecording() async {
    try {
      await _audioRecorder.pause();
      _stopDurationTimer();
    } catch (e) {
      debugPrint('❌ Error pausing recording: $e');
    }
  }

  /// Resume recording (if supported by your audio recorder)
  Future<void> resumeRecording() async {
    try {
      await _audioRecorder.resume();
      _startDurationTimer();
    } catch (e) {
      debugPrint('❌ Error resuming recording: $e');
    }
  }

  /// Get recording amplitude for waveform visualization
  Stream<double> getAmplitudeStream() {
    // If your audio recorder supports amplitude monitoring
    // return _audioRecorder.amplitudeStream;
    return _currentRmsSubject.stream;
  }

  /// Clean up old recording files
  Future<void> cleanupOldRecordings() async {
    try {
      final dir = await getTemporaryDirectory();
      final files = dir.listSync().where((file) =>
      file.path.contains('audio_') && file.path.endsWith('.wav'));

      for (var file in files) {
        try {
          await file.delete();
        } catch (e) {
          debugPrint('Could not delete file: ${file.path}');
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up recordings: $e');
    }
  }

  /// Dispose all resources
  void dispose() {
    _vadSubscription?.cancel();
    _rmsTimer?.cancel();
    _durationTimer?.cancel();
    _audioRecorder.dispose();

    _isListeningSubject.close();
    _isTranscribingSubject.close();
    _isSpeakingSubject.close();
    _currentRmsSubject.close();
    _displayedRmsSubject.close();
    _transcriptSubject.close();
    _recordingDurationSubject.close();
    _errorSubject.close();
  }
}