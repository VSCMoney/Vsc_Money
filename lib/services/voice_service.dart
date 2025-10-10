// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart';
// import 'package:record/record.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'package:rxdart/rxdart.dart';
//
// class AudioService {
//   static AudioService? _instance;
//   static AudioService get instance => _instance ??= AudioService._();
//   AudioService._();
//
//   // Audio recorder
//   final AudioRecorder _audioRecorder = AudioRecorder();
//
//   double _rmsThreshold = 0.015;
//   int _speechFrameCount = 0;
//   int _silenceFrameCount = 0;
//   int _minSpeechFrames = 2;
//   int _minSilenceFrames = 8;
//   bool _isSpeechActive = false;
//
//   // ✅ ADD: RMS smoothing parameters
//   double _lastSignificantRms = 0.0;
//   DateTime _lastRmsUpdate = DateTime.now();
//   static const int _rmsUpdateIntervalMs = 50;
//   final List<double> _rmsBuffer = [];
//   static const int _rmsBufferSize = 5;
//
//   // Platform channels
//   static const _androidMethodChannel = MethodChannel('native_vad');
//   static const _androidEventChannel = EventChannel('native_vad/events');
//   static const _iosMethodChannel = MethodChannel('yamnet_channel');
//   static const _iosEventChannel = EventChannel('yamnet_event_channel');
//
//   // Streams for reactive state management
//   final BehaviorSubject<bool> _isListeningSubject = BehaviorSubject<bool>.seeded(false);
//   final BehaviorSubject<bool> _isTranscribingSubject = BehaviorSubject<bool>.seeded(false);
//   final BehaviorSubject<bool> _isSpeakingSubject = BehaviorSubject<bool>.seeded(false);
//   final BehaviorSubject<double> _currentRmsSubject = BehaviorSubject<double>.seeded(0.0);
//   final BehaviorSubject<double> _displayedRmsSubject = BehaviorSubject<double>.seeded(0.0);
//   final BehaviorSubject<String> _transcriptSubject = BehaviorSubject<String>.seeded('');
//   final BehaviorSubject<String> _recordingDurationSubject = BehaviorSubject<String>.seeded('00:00');
//   final BehaviorSubject<String> _errorSubject = BehaviorSubject<String>.seeded('');
//
//   // Public streams
//   Stream<bool> get isListening$ => _isListeningSubject.stream;
//   Stream<bool> get isTranscribing$ => _isTranscribingSubject.stream;
//   Stream<bool> get isSpeaking$ => _isSpeakingSubject.stream;
//   Stream<double> get currentRms$ => _currentRmsSubject.stream;
//   Stream<double> get displayedRms$ => _displayedRmsSubject.stream;
//   Stream<String> get transcript$ => _transcriptSubject.stream;
//   Stream<String> get recordingDuration$ => _recordingDurationSubject.stream;
//   Stream<String> get error$ => _errorSubject.stream;
//
//   // Getters for current values
//   bool get isListening => _isListeningSubject.value;
//   bool get isTranscribing => _isTranscribingSubject.value;
//   bool get isSpeaking => _isSpeakingSubject.value;
//   double get currentRms => _currentRmsSubject.value;
//   double get displayedRms => _displayedRmsSubject.value;
//   String get transcript => _transcriptSubject.value;
//   String get recordingDuration => _recordingDurationSubject.value;
//
//   // Private variables
//   StreamSubscription? _vadSubscription;
//   Timer? _rmsTimer;
//   Timer? _durationTimer;
//   Stopwatch _speechTimer = Stopwatch();
//   String _recordingPath = '';
//   String _recognizedBackupText = '';
//
//   // Configuration
//  //static const String _baseUrl = 'http://127.0.0.1:8000';
//   //static const String _baseUrl = 'http://192.168.1.2:8000';
//    static const String _baseUrl = "https://fastapi-app-130321581049.asia-south1.run.app";
//
//   /// Initialize the audio service
//   Future<void> initialize() async {
//     _startRmsSmoothing();
//   }
//
//   /// Start recording with VAD
//   Future<bool> startRecording({String? existingText}) async {
//     try {
//       if (!await _audioRecorder.hasPermission()) {
//         _errorSubject.add('Microphone permission not granted');
//         return false;
//       }
//
//       _recognizedBackupText = existingText ?? '';
//
//       final dir = await getTemporaryDirectory();
//       _recordingPath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav';
//
//       // ✅ UPDATED: Better recording config
//       final recordConfig = RecordConfig(
//         encoder: AudioEncoder.wav,
//         bitRate: 64000,        // Reduced from 128000
//         sampleRate: 16000,     // Reduced from 44100
//         numChannels: 1,
//       );
//
//       await _audioRecorder.start(recordConfig, path: _recordingPath);
//
//       // ✅ NEW: Reset VAD state
//       _resetVadState();
//
//       await _startNativeVad();
//       _startDurationTimer();
//
//       _isListeningSubject.add(true);
//       _isTranscribingSubject.add(false);
//       _recordingDurationSubject.add('00:00');
//
//       debugPrint('🎤 Recording started with optimized settings: $_recordingPath');
//       return true;
//     } catch (e) {
//       debugPrint('❌ Error starting recording: $e');
//       _errorSubject.add('Failed to start recording: $e');
//       return false;
//     }
//   }
//
//   void _resetVadState() {
//     _speechFrameCount = 0;
//     _silenceFrameCount = 0;
//     _isSpeechActive = false;
//     _lastSignificantRms = 0.0;
//     _rmsBuffer.clear();
//   }
//
//
//
//   Future<void> _startNativeVad() async {
//     try {
//       await _vadSubscription?.cancel();
//
//       final EventChannel eventChannel = Platform.isIOS ? _iosEventChannel : _androidEventChannel;
//       final MethodChannel methodChannel = Platform.isIOS ? _iosMethodChannel : _androidMethodChannel;
//
//       _vadSubscription = eventChannel.receiveBroadcastStream().listen((event) {
//         final rawIsSpeech = event['isSpeech'] ?? event['state'] == 'speech_detected' || false;
//         final rawRms = (event['rms'] ?? event['rms_db'] ?? 0.0).toDouble();
//
//         // ✅ NEW: Platform-specific processing
//         if (Platform.isAndroid) {
//           _processAndroidVadEvent(rawIsSpeech, rawRms);
//         } else {
//           _processIosVadEvent(rawIsSpeech, rawRms);
//         }
//       });
//
//       await methodChannel.invokeMethod('start');
//     } catch (e) {
//       debugPrint('❌ startNativeVad error: $e');
//       _errorSubject.add('Failed to start voice detection: $e');
//     }
//   }
//
// // ✅ 5. ADD: Android-specific VAD processing
//   void _processAndroidVadEvent(bool rawIsSpeech, double rawRms) {
//     final now = DateTime.now();
//
//     // Apply RMS threshold filtering
//     final effectiveRms = rawRms > _rmsThreshold ? rawRms : 0.0;
//
//     // Add to moving average buffer
//     _rmsBuffer.add(effectiveRms);
//     if (_rmsBuffer.length > _rmsBufferSize) {
//       _rmsBuffer.removeAt(0);
//     }
//
//     // Calculate moving average
//     final avgRms = _rmsBuffer.reduce((a, b) => a + b) / _rmsBuffer.length;
//
//     // Rate limiting
//     final timeSinceLastUpdate = now.difference(_lastRmsUpdate).inMilliseconds;
//     if (timeSinceLastUpdate < _rmsUpdateIntervalMs) {
//       return;
//     }
//
//     // Significant change detection
//     final rmsDifference = (avgRms - _lastSignificantRms).abs();
//     if (rmsDifference < 0.005 && avgRms < 0.02) {
//       return;
//     }
//
//     // Update RMS
//     _currentRmsSubject.add(avgRms);
//     _lastSignificantRms = avgRms;
//     _lastRmsUpdate = now;
//
//     // Speech detection with frame counting
//     final shouldBeSpeech = rawIsSpeech && avgRms > _rmsThreshold;
//
//     if (shouldBeSpeech) {
//       _speechFrameCount++;
//       _silenceFrameCount = 0;
//
//       if (_speechFrameCount >= _minSpeechFrames && !_isSpeechActive) {
//         _isSpeechActive = true;
//         _isSpeakingSubject.add(true);
//         debugPrint('🎙️ ANDROID SPEECH START => frames=$_speechFrameCount | avgRms=${avgRms.toStringAsFixed(3)}');
//       }
//     } else {
//       _silenceFrameCount++;
//       _speechFrameCount = 0;
//
//       if (_silenceFrameCount >= _minSilenceFrames && _isSpeechActive) {
//         _isSpeechActive = false;
//         _isSpeakingSubject.add(false);
//         debugPrint('🔇 ANDROID SPEECH END => silence_frames=$_silenceFrameCount');
//       }
//     }
//   }
//
// // ✅ 6. ADD: iOS-specific VAD processing
//   void _processIosVadEvent(bool rawIsSpeech, double rawRms) {
//     final now = DateTime.now();
//     final timeSinceLastUpdate = now.difference(_lastRmsUpdate).inMilliseconds;
//
//     if (timeSinceLastUpdate >= _rmsUpdateIntervalMs) {
//       final effectiveRms = rawRms > _rmsThreshold ? rawRms : 0.0;
//       _currentRmsSubject.add(effectiveRms);
//       _isSpeakingSubject.add(rawIsSpeech && effectiveRms > _rmsThreshold);
//       _lastRmsUpdate = now;
//
//       debugPrint('🎙️ iOS VAD => isSpeech=$rawIsSpeech | rms=${effectiveRms.toStringAsFixed(3)}');
//     }
//   }
//
//   /// Stop recording and transcribe
//   Future<void> stopRecordingAndTranscribe() async {
//     try {
//       _isTranscribingSubject.add(true);
//
//       // Stop timers
//       _stopDurationTimer();
//
//       // Stop recording
//       final path = await _audioRecorder.stop();
//       if (path != null) _recordingPath = path;
//
//       // Stop VAD
//       await _stopNativeVad();
//
//       // Transcribe audio
//       await _transcribeAudio();
//
//     } catch (e) {
//       debugPrint('❌ Error stopping recording: $e');
//       _errorSubject.add('Failed to stop recording: $e');
//     } finally {
//       _isListeningSubject.add(false);
//       _isTranscribingSubject.add(false);
//     }
//   }
//
//   /// Cancel recording without transcription
//   Future<void> cancelRecording() async {
//     try {
//       // Stop timers
//       _stopDurationTimer();
//
//       // Stop recording
//       await _audioRecorder.stop();
//
//       // Stop VAD
//       await _stopNativeVad();
//
//       // Restore backup text if any
//       if (_recognizedBackupText.isNotEmpty) {
//         _transcriptSubject.add(_recognizedBackupText);
//       }
//
//     } catch (e) {
//       debugPrint('❌ Error canceling recording: $e');
//       _errorSubject.add('Failed to cancel recording: $e');
//     } finally {
//       _isListeningSubject.add(false);
//       _isTranscribingSubject.add(false);
//       _recognizedBackupText = '';
//     }
//   }
//
//   /// Update transcript manually (for external speech recognition)
//   void updateTranscript(String text) {
//     _transcriptSubject.add(text);
//   }
//
//   /// Clear transcript
//   void clearTranscript() {
//     _transcriptSubject.add('');
//   }
//
//   /// Clear error
//   void clearError() {
//     _errorSubject.add('');
//   }
//
//   // Private methods
//
//   // Future<void> _startNativeVad() async {
//   //   try {
//   //     await _vadSubscription?.cancel();
//   //
//   //     final EventChannel eventChannel = Platform.isIOS ? _iosEventChannel : _androidEventChannel;
//   //     final MethodChannel methodChannel = Platform.isIOS ? _iosMethodChannel : _androidMethodChannel;
//   //
//   //     _vadSubscription = eventChannel.receiveBroadcastStream().listen((event) {
//   //       final isSpeech = event['isSpeech'] ?? event['state'] == 'speech_detected' || false;
//   //       final rms = (event['rms'] ?? event['rms_db'] ?? 0.0).toDouble();
//   //
//   //       debugPrint('🎙️ VAD => isSpeech=$isSpeech | rms=${rms.toStringAsFixed(2)}');
//   //
//   //       _isSpeakingSubject.add(isSpeech);
//   //       _currentRmsSubject.add(rms);
//   //     });
//   //
//   //     await methodChannel.invokeMethod('start');
//   //   } catch (e) {
//   //     debugPrint('❌ startNativeVad error: $e');
//   //     _errorSubject.add('Failed to start voice detection: $e');
//   //   }
//   // }
//
//   Future<void> _stopNativeVad() async {
//     try {
//       final MethodChannel methodChannel = Platform.isIOS ? _iosMethodChannel : _androidMethodChannel;
//       await methodChannel.invokeMethod('stop');
//       await _vadSubscription?.cancel();
//       _vadSubscription = null;
//
//       // ✅ NEW: Reset VAD state
//       _resetVadState();
//       _isSpeakingSubject.add(false);
//       _currentRmsSubject.add(0.0);
//       _displayedRmsSubject.add(0.0);
//     } catch (e) {
//       debugPrint('❌ stopNativeVad error: $e');
//     }
//   }
//
// // ✅ 8. UPDATE: _startRmsSmoothing function
//   void _startRmsSmoothing() {
//     _rmsTimer?.cancel();
//
//     // Platform-specific smoothing
//     final smoothingFactor = Platform.isAndroid ? 0.25 : 0.2;
//     final updateIntervalMs = Platform.isAndroid ? 50 : 33;
//
//     _rmsTimer = Timer.periodic(Duration(milliseconds: updateIntervalMs), (timer) {
//       final currentRms = _currentRmsSubject.value;
//       final displayedRms = _displayedRmsSubject.value;
//       final difference = (currentRms - displayedRms).abs();
//
//       if (difference > 0.003) {
//         double newDisplayedRms = displayedRms + (currentRms - displayedRms) * smoothingFactor;
//
//         // Snap to zero if very close
//         if (newDisplayedRms < 0.008) {
//           newDisplayedRms = 0.0;
//         }
//
//         _displayedRmsSubject.add(newDisplayedRms);
//       }
//     });
//   }
//
//   void _stopRmsSmoothing() {
//     _rmsTimer?.cancel();
//     _rmsTimer = null;
//   }
//
//   void _startDurationTimer() {
//     _speechTimer.reset();
//     _speechTimer.start();
//
//     _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
//       _recordingDurationSubject.add(_formatDuration(_speechTimer.elapsed));
//     });
//   }
//
//   void _stopDurationTimer() {
//     _durationTimer?.cancel();
//     _speechTimer.stop();
//   }
//
//   String _formatDuration(Duration d) {
//     final minutes = d.inMinutes;
//     final seconds = d.inSeconds % 60;
//
//     if (minutes < 10) {
//       return "${minutes}:${seconds.toString().padLeft(2, '0')}";
//     } else {
//       return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
//     }
//   }
//
//
//
//    String _openAIApiKey = "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";
//
//   MediaType _guessMediaTypeForPath(String path) {
//     final lower = path.toLowerCase();
//     if (lower.endsWith('.m4a')) return MediaType('audio', 'm4a');
//     if (lower.endsWith('.mp3')) return MediaType('audio', 'mpeg');
//     if (lower.endsWith('.wav')) return MediaType('audio', 'wav');
//     if (lower.endsWith('.aac')) return MediaType('audio', 'aac');
//     return MediaType('application', 'octet-stream');
//   }
//
//   Future<void> _transcribeAudio() async {
//     debugPrint("🎤 Starting transcription (frontend → OpenAI)");
//
//     if (_openAIApiKey.isEmpty) {
//       _errorSubject.add('OPENAI_API_KEY missing (use --dart-define).');
//       return;
//     }
//     if (_recordingPath.isEmpty) {
//       _errorSubject.add('No recording found');
//       return;
//     }
//
//     final file = File(_recordingPath);
//     if (!file.existsSync()) {
//       _errorSubject.add('Recording file not found');
//       return;
//     }
//
//     final fileSize = await file.length();
//     debugPrint("📁 File size: $fileSize bytes");
//
//     try {
//       final uri = Uri.parse('https://api.openai.com/v1/audio/transcriptions');
//       final req = http.MultipartRequest('POST', uri)
//         ..headers['Authorization'] = 'Bearer $_openAIApiKey'
//       // Let MultipartRequest set its own Content-Type with boundary
//         ..fields['model'] = 'whisper-1'
//         ..fields['response_format'] = 'json'
//         ..fields['temperature'] = '0'
//         ..fields['language'] = 'en'; // optional, helps latency
//
//       final contentType = _guessMediaTypeForPath(file.path);
//
//       req.files.add(await http.MultipartFile.fromPath(
//         'file',
//         file.path,
//         contentType: contentType,
//         filename: file.uri.pathSegments.last,
//       ));
//
//       // Give Whisper some time — mobile uplinks can be slow
//       final streamed = await req.send().timeout(const Duration(seconds: 90));
//       final body = await streamed.stream.bytesToString();
//
//       debugPrint('✅ OpenAI status: ${streamed.statusCode}');
//       debugPrint('📩 OpenAI body: $body');
//
//       if (streamed.statusCode == 200) {
//         final jsonResp = jsonDecode(body) as Map<String, dynamic>;
//         final transcript = (jsonResp['text'] ?? '').toString();
//
//         if (transcript.trim().isEmpty) {
//           _errorSubject.add('No speech detected.');
//           return;
//         }
//
//         final existingText = _recognizedBackupText.trim();
//         final newText = existingText.isEmpty ? transcript : '$existingText $transcript';
//         _transcriptSubject.add(newText);
//         _recognizedBackupText = '';
//       } else if (streamed.statusCode == 413) {
//         _errorSubject.add('Audio too large. Try a shorter recording.');
//       } else if (streamed.statusCode == 429) {
//         _errorSubject.add('Rate limited by OpenAI. Try again in a moment.');
//       } else {
//         // Try to surface OpenAI error message if present
//         try {
//           final err = jsonDecode(body);
//           _errorSubject.add('OpenAI error: ${err['error']?['message'] ?? body}');
//         } catch (_) {
//           _errorSubject.add('Transcription failed (${streamed.statusCode}).');
//         }
//       }
//     } on SocketException {
//       _errorSubject.add('Network error. Check your internet connection.');
//     } on TimeoutException {
//       _errorSubject.add('Upload/processing timed out. Try a shorter clip.');
//     } catch (e) {
//       debugPrint('🔥 Exception during transcription: $e');
//       _errorSubject.add('Transcription error: $e');
//     }
//   }
//
//
//   // Future<void> _transcribeAudio() async {
//   //   debugPrint("🎤 Starting transcription process");
//   //
//   //   if (_recordingPath.isEmpty) {
//   //     debugPrint("❌ Recording path is empty");
//   //     _errorSubject.add('No recording found');
//   //     return;
//   //   }
//   //
//   //   final file = File(_recordingPath);
//   //   if (!file.existsSync()) {
//   //     debugPrint("❌ File not found at: $_recordingPath");
//   //     _errorSubject.add('Recording file not found');
//   //     return;
//   //   }
//   //
//   //   debugPrint("📁 File size: ${file.lengthSync()} bytes");
//   //
//   //   try {
//   //     debugPrint("⏳ Sending file to transcription API");
//   //
//   //     var request = http.MultipartRequest(
//   //       'POST',
//   //       Uri.parse('$_baseUrl/speech/transcribe'),
//   //     );
//   //
//   //     var multipartFile = await http.MultipartFile.fromPath(
//   //       'file',
//   //       file.path,
//   //       contentType: MediaType('audio', 'wav'),
//   //     );
//   //
//   //     debugPrint('📤 Uploading file: ${multipartFile.filename}, size: ${multipartFile.length}');
//   //     request.files.add(multipartFile);
//   //
//   //     var response = await request.send();
//   //     debugPrint('✅ Response status: ${response.statusCode}');
//   //
//   //     final responseBody = await response.stream.bytesToString();
//   //     debugPrint('📩 Response body: $responseBody');
//   //
//   //     if (response.statusCode == 200) {
//   //       final jsonResponse = jsonDecode(responseBody);
//   //       final transcript = jsonResponse['transcript'] ?? '';
//   //       debugPrint('📄 Transcript received: $transcript');
//   //
//   //       if (transcript.isNotEmpty &&
//   //           transcript != 'No speech detected. Please speak clearly and try again.') {
//   //
//   //         // Combine with existing text if any
//   //         final existingText = _recognizedBackupText.trim();
//   //         final newText = existingText.isEmpty ? transcript : '$existingText $transcript';
//   //
//   //         _transcriptSubject.add(newText);
//   //         _recognizedBackupText = '';
//   //
//   //       } else {
//   //         // Keep backup text if transcription failed
//   //         if (_recognizedBackupText.isNotEmpty) {
//   //           _transcriptSubject.add(_recognizedBackupText);
//   //         } else {
//   //           _errorSubject.add('Could not transcribe audio. Please try again.');
//   //         }
//   //       }
//   //     } else {
//   //       debugPrint('❌ Transcription failed with status: ${response.statusCode}');
//   //       _errorSubject.add('Transcription failed. Please try again.');
//   //     }
//   //   } catch (e) {
//   //     debugPrint('🔥 Exception during transcription: $e');
//   //     _errorSubject.add('Transcription error: $e');
//   //   }
//   // }
//
//   /// Check if microphone permission is granted
//   Future<bool> hasPermission() async {
//     return await _audioRecorder.hasPermission();
//   }
//
//   /// Request microphone permission
//   Future<bool> requestPermission() async {
//     return await _audioRecorder.hasPermission();
//   }
//
//   /// Get current recording file path
//   String get recordingPath => _recordingPath;
//
//   /// Check if currently recording
//   bool get hasActiveRecording => _recordingPath.isNotEmpty && isListening;
//
//   /// Set custom transcription URL
//   void setTranscriptionUrl(String url) {
//     // You can make _baseUrl non-const and allow customization
//   }
//
//   /// Pause recording (if supported by your audio recorder)
//   Future<void> pauseRecording() async {
//     try {
//       await _audioRecorder.pause();
//       _stopDurationTimer();
//     } catch (e) {
//       debugPrint('❌ Error pausing recording: $e');
//     }
//   }
//
//   /// Resume recording (if supported by your audio recorder)
//   Future<void> resumeRecording() async {
//     try {
//       await _audioRecorder.resume();
//       _startDurationTimer();
//     } catch (e) {
//       debugPrint('❌ Error resuming recording: $e');
//     }
//   }
//
//   /// Get recording amplitude for waveform visualization
//   Stream<double> getAmplitudeStream() {
//     // If your audio recorder supports amplitude monitoring
//     // return _audioRecorder.amplitudeStream;
//     return _currentRmsSubject.stream;
//   }
//
//   /// Clean up old recording files
//   Future<void> cleanupOldRecordings() async {
//     try {
//       final dir = await getTemporaryDirectory();
//       final files = dir.listSync().where((file) =>
//       file.path.contains('audio_') && file.path.endsWith('.wav'));
//
//       for (var file in files) {
//         try {
//           await file.delete();
//         } catch (e) {
//           debugPrint('Could not delete file: ${file.path}');
//         }
//       }
//     } catch (e) {
//       debugPrint('Error cleaning up recordings: $e');
//     }
//   }
//
//   /// Dispose all resources
//   void dispose() {
//     _vadSubscription?.cancel();
//     _rmsTimer?.cancel();
//     _durationTimer?.cancel();
//     _audioRecorder.dispose();
//
//     _isListeningSubject.close();
//     _isTranscribingSubject.close();
//     _isSpeakingSubject.close();
//     _currentRmsSubject.close();
//     _displayedRmsSubject.close();
//     _transcriptSubject.close();
//     _recordingDurationSubject.close();
//     _errorSubject.close();
//   }
// }



import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:rxdart/rxdart.dart';
import 'package:vscmoney/constants/secrets.dart';

class AudioService {
  static AudioService? _instance;
  static AudioService get instance => _instance ??= AudioService._();
  AudioService._();

  // Audio recorder
  final AudioRecorder _audioRecorder = AudioRecorder();

  // VAD speech detection parameters (no RMS thresholds)
  int _speechFrameCount = 0;
  int _silenceFrameCount = 0;
  int _minSpeechFrames = 2;
  int _minSilenceFrames = 8;
  bool _isSpeechActive = false;

  // ✅ PURE RMS PROCESSING: Only rate limiting, no thresholds
  double _lastRawRms = 0.0;
  DateTime _lastRmsUpdate = DateTime.now();

  // Platform-specific rate limiting to control waveform frequency
  static const int _waveformUpdateIntervalMs = 33; // 30fps for smooth waveforms

  // Simple smoothing buffer (optional, for visual smoothness only)
  final List<double> _rmsBuffer = [];
  static const int _rmsBufferSize = 3;

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

  // ✅ DEDICATED WAVEFORM STREAM: Pure RMS values at controlled rate
  final BehaviorSubject<double> _waveformRmsSubject = BehaviorSubject<double>.seeded(0.0);

  // Public streams
  Stream<bool> get isListening$ => _isListeningSubject.stream;
  Stream<bool> get isTranscribing$ => _isTranscribingSubject.stream;
  Stream<bool> get isSpeaking$ => _isSpeakingSubject.stream;
  Stream<double> get currentRms$ => _currentRmsSubject.stream;
  Stream<double> get displayedRms$ => _displayedRmsSubject.stream;
  Stream<String> get transcript$ => _transcriptSubject.stream;
  Stream<String> get recordingDuration$ => _recordingDurationSubject.stream;
  Stream<String> get error$ => _errorSubject.stream;

  // ✅ PURE WAVEFORM STREAM: For real-time waveform visualization
  Stream<double> get waveformRms$ => _waveformRmsSubject.stream;

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
  static const String _baseUrl = "https://fastapi-app-130321581049.asia-south1.run.app";

  /// Initialize the audio service
  Future<void> initialize() async {
    _startRmsSmoothing();
  }

  /// Start recording with VAD
  Future<bool> startRecording({String? existingText}) async {
    try {
      // ✅ Quick checks
      if (!await _audioRecorder.hasPermission()) {
        _errorSubject.add('Microphone permission not granted');
        return false;
      }

      _recognizedBackupText = existingText ?? '';

      // ✅ UI state IMMEDIATELY update (ye instant hai)
      _isListeningSubject.add(true);
      _isTranscribingSubject.add(false);
      _recordingDurationSubject.add('00:00');
      _resetVadState();

      // ✅ Heavy operations PARALLEL mein
      await Future.wait([
        _prepareRecording(),  // File path setup
        _startNativeVad(),     // VAD initialization
      ]);

     // _startDurationTimer();

      debugPrint('🎤 Recording started');
      return true;
    } catch (e) {
      debugPrint('❌ Error: $e');
      _errorSubject.add('Failed to start recording: $e');
      _isListeningSubject.add(false);
      return false;
    }
  }

  Future<void> _prepareRecording() async {
    final dir = await getTemporaryDirectory();
    _recordingPath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav';

    final recordConfig = RecordConfig(
      encoder: AudioEncoder.wav,
      bitRate: 64000,
      sampleRate: 16000,
      numChannels: 1,
    );

    await _audioRecorder.start(recordConfig, path: _recordingPath);
  }

  void _resetVadState() {
    _speechFrameCount = 0;
    _silenceFrameCount = 0;
    _isSpeechActive = false;
    _lastRawRms = 0.0;
    _rmsBuffer.clear();
  }

  Future<void> _startNativeVad() async {
    try {
      await _vadSubscription?.cancel();

      final EventChannel eventChannel = Platform.isIOS ? _iosEventChannel : _androidEventChannel;
      final MethodChannel methodChannel = Platform.isIOS ? _iosMethodChannel : _androidMethodChannel;

      _vadSubscription = eventChannel.receiveBroadcastStream().listen((event) {
        final rawIsSpeech = event['isSpeech'] ?? event['state'] == 'speech_detected' || false;
        final rawRms = (event['rms'] ?? event['rms_db'] ?? 0.0).toDouble();

        if (Platform.isAndroid) {
          _processAndroidVadEvent(rawIsSpeech, rawRms);
        } else {
          _processIosVadEvent(rawIsSpeech, rawRms);
        }
      });

      await methodChannel.invokeMethod('start');
    } catch (e) {
      debugPrint('❌ startNativeVad error: $e');
      _errorSubject.add('Failed to start voice detection: $e');
    }
  }

  void _processAndroidVadEvent(bool rawIsSpeech, double rawRms) {
    final now = DateTime.now();
    final timeSinceLastUpdate = now.difference(_lastRmsUpdate).inMilliseconds;

    if (timeSinceLastUpdate >= _waveformUpdateIntervalMs) {
      final amp = _normalizeRms(rawRms);

      // ✅ Larger buffer = smoother transitions between loud/quiet
      _rmsBuffer.add(amp);
      if (_rmsBuffer.length > 5) _rmsBuffer.removeAt(0); // Increased from 3 to 5

      final avg = _rmsBuffer.reduce((a, b) => a + b) / _rmsBuffer.length;

      _currentRmsSubject.add(avg);
      _waveformRmsSubject.add(avg);
      _lastRawRms = avg;
      _lastRmsUpdate = now;

      debugPrint('🎙️ ANDROID RMS => ${avg.toStringAsFixed(4)} | isSpeech=$rawIsSpeech');
    }

    // VAD logic unchanged
    if (rawIsSpeech) {
      _speechFrameCount++;
      _silenceFrameCount = 0;
      if (_speechFrameCount >= _minSpeechFrames && !_isSpeechActive) {
        _isSpeechActive = true;
        _isSpeakingSubject.add(true);
      }
    } else {
      _silenceFrameCount++;
      _speechFrameCount = 0;
      if (_silenceFrameCount >= _minSilenceFrames && _isSpeechActive) {
        _isSpeechActive = false;
        _isSpeakingSubject.add(false);
      }
    }
  }

// ✅ iOS: Similar improvements
  void _processIosVadEvent(bool rawIsSpeech, double rawRms) {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRmsUpdate).inMilliseconds;

    if (elapsed >= _waveformUpdateIntervalMs) {
      final amp = _normalizeRms(rawRms);
      _currentRmsSubject.add(amp);
      _waveformRmsSubject.add(amp);
      _lastRmsUpdate = now;

      debugPrint('🎙️ iOS RMS => ${amp.toStringAsFixed(4)} | isSpeech=$rawIsSpeech');
    }

    _isSpeakingSubject.add(rawIsSpeech);
  }


  // // ✅ ANDROID VAD: Pure RMS with rate limiting only
  // void _processAndroidVadEvent(bool rawIsSpeech, double rawRms) {
  //   final now = DateTime.now();
  //
  //   // Rate limiting for waveforms (Android sends too frequently)
  //   final timeSinceLastUpdate = now.difference(_lastRmsUpdate).inMilliseconds;
  //   if (timeSinceLastUpdate >= _waveformUpdateIntervalMs) {
  //
  //     // ✅ PURE RMS: Take absolute value, no other filtering
  //     final pureRms = rawRms.abs();
  //
  //     // Optional: Add to buffer for slight smoothing (purely visual)
  //     _rmsBuffer.add(pureRms);
  //     if (_rmsBuffer.length > _rmsBufferSize) {
  //       _rmsBuffer.removeAt(0);
  //     }
  //
  //     // Calculate simple moving average for smoother visuals
  //     final avgRms = _rmsBuffer.isNotEmpty
  //         ? _rmsBuffer.reduce((a, b) => a + b) / _rmsBuffer.length
  //         : pureRms;
  //
  //     // ✅ UPDATE ALL RMS STREAMS with pure values
  //     _currentRmsSubject.add(avgRms);
  //     _waveformRmsSubject.add(avgRms);  // Dedicated waveform stream
  //     _lastRawRms = avgRms;
  //     _lastRmsUpdate = now;
  //
  //     debugPrint('🎙️ ANDROID RMS => ${avgRms.toStringAsFixed(4)} | isSpeech=$rawIsSpeech');
  //   }
  //
  //   // Speech detection based on native VAD decision
  //   if (rawIsSpeech) {
  //     _speechFrameCount++;
  //     _silenceFrameCount = 0;
  //
  //     if (_speechFrameCount >= _minSpeechFrames && !_isSpeechActive) {
  //       _isSpeechActive = true;
  //       _isSpeakingSubject.add(true);
  //       debugPrint('🎙️ ANDROID SPEECH START');
  //     }
  //   } else {
  //     _silenceFrameCount++;
  //     _speechFrameCount = 0;
  //
  //     if (_silenceFrameCount >= _minSilenceFrames && _isSpeechActive) {
  //       _isSpeechActive = false;
  //       _isSpeakingSubject.add(false);
  //       debugPrint('🔇 ANDROID SPEECH END');
  //     }
  //   }
  // }
  //
  // // ✅ iOS VAD: Pure RMS with rate limiting
  // void _processIosVadEvent(bool rawIsSpeech, double rawRms) {
  //   final now = DateTime.now();
  //   final timeSinceLastUpdate = now.difference(_lastRmsUpdate).inMilliseconds;
  //
  //   if (timeSinceLastUpdate >= _waveformUpdateIntervalMs) {
  //
  //     // ✅ PURE RMS: Take absolute value, no filtering
  //     final pureRms = rawRms.abs();
  //
  //     // ✅ UPDATE ALL RMS STREAMS with pure values
  //     _currentRmsSubject.add(pureRms);
  //     _waveformRmsSubject.add(pureRms);  // Dedicated waveform stream
  //     _lastRmsUpdate = now;
  //
  //     debugPrint('🎙️ iOS RMS => ${pureRms.toStringAsFixed(4)} | isSpeech=$rawIsSpeech');
  //   }
  //
  //   // Speech detection based on native VAD decision
  //   _isSpeakingSubject.add(rawIsSpeech);
  // }

  /// Stop recording and transcribe
  Future<void> stopRecordingAndTranscribe() async {
    try {
      _isTranscribingSubject.add(true);

      _stopDurationTimer();

      final path = await _audioRecorder.stop();
      if (path != null) _recordingPath = path;

      await _stopNativeVad();
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
      _stopDurationTimer();
      await _audioRecorder.stop();
      await _stopNativeVad();

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

  Future<void> _stopNativeVad() async {
    try {
      final MethodChannel methodChannel = Platform.isIOS ? _iosMethodChannel : _androidMethodChannel;
      await methodChannel.invokeMethod('stop');
      await _vadSubscription?.cancel();
      _vadSubscription = null;

      _resetVadState();
      _isSpeakingSubject.add(false);
      _currentRmsSubject.add(0.0);
      _waveformRmsSubject.add(0.0);  // Reset waveform
      _displayedRmsSubject.add(0.0);
    } catch (e) {
      debugPrint('❌ stopNativeVad error: $e');
    }
  }

  // ✅ SIMPLIFIED RMS SMOOTHING: Only for display, not for thresholding
  void _startRmsSmoothing() {
    _rmsTimer?.cancel();

    const smoothingFactor = 0.3;  // Gentle smoothing for display
    const updateIntervalMs = 16;  // 60fps

    _rmsTimer = Timer.periodic(Duration(milliseconds: updateIntervalMs), (timer) {
      final currentRms = _currentRmsSubject.value;
      final displayedRms = _displayedRmsSubject.value;

      // Simple exponential smoothing for display only
      final newDisplayedRms = displayedRms + (currentRms - displayedRms) * smoothingFactor;
      _displayedRmsSubject.add(newDisplayedRms);
    });
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

  // ✅ WAVEFORM HELPER METHODS

  /// Get real-time RMS stream for waveform visualization
  /// Returns pure RMS values from native VAD at controlled 30fps
  Stream<double> getWaveformStream() {
    return _waveformRmsSubject.stream.distinct();
  }

  /// Get current RMS value for immediate waveform updates
  double getWaveformRms() {
    return _waveformRmsSubject.value;
  }

  /// Get smoothed RMS stream for UI elements that need stable values
  Stream<double> getSmoothedRmsStream() {
    return _displayedRmsSubject.stream.distinct();
  }

  // Utility methods
  void updateTranscript(String text) => _transcriptSubject.add(text);
  void clearTranscript() => _transcriptSubject.add('');
  void clearError() => _errorSubject.add('');

  Future<bool> hasPermission() async => await _audioRecorder.hasPermission();
  String get recordingPath => _recordingPath;
  bool get hasActiveRecording => _recordingPath.isNotEmpty && isListening;

  // [Rest of transcription methods remain the same...]

  String _openAIApiKey = ApiConstants.openAIApiKey;

  MediaType _guessMediaTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.m4a')) return MediaType('audio', 'm4a');
    if (lower.endsWith('.mp3')) return MediaType('audio', 'mpeg');
    if (lower.endsWith('.wav')) return MediaType('audio', 'wav');
    if (lower.endsWith('.aac')) return MediaType('audio', 'aac');
    return MediaType('application', 'octet-stream');
  }

  Future<void> _transcribeAudio() async {
    debugPrint("🎤 Starting transcription (frontend → OpenAI)");

    if (_openAIApiKey.isEmpty) {
      _errorSubject.add('OPENAI_API_KEY missing (use --dart-define).');
      return;
    }
    if (_recordingPath.isEmpty) {
      _errorSubject.add('No recording found');
      return;
    }

    final file = File(_recordingPath);
    if (!file.existsSync()) {
      _errorSubject.add('Recording file not found');
      return;
    }

    final fileSize = await file.length();
    debugPrint("📁 File size: $fileSize bytes");

    try {
      final uri = Uri.parse('https://api.openai.com/v1/audio/transcriptions');
      final req = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $_openAIApiKey'
        ..fields['model'] = 'whisper-1'
        ..fields['response_format'] = 'json'
        ..fields['temperature'] = '0'
        ..fields['language'] = 'en';

      final contentType = _guessMediaTypeForPath(file.path);

      req.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: contentType,
        filename: file.uri.pathSegments.last,
      ));

      final streamed = await req.send().timeout(const Duration(seconds: 90));
      final body = await streamed.stream.bytesToString();

      debugPrint('✅ OpenAI status: ${streamed.statusCode}');
      debugPrint('📩 OpenAI body: $body');

      if (streamed.statusCode == 200) {
        final jsonResp = jsonDecode(body) as Map<String, dynamic>;
        final transcript = (jsonResp['text'] ?? '').toString();

        if (transcript.trim().isEmpty) {
          _errorSubject.add('No speech detected.');
          return;
        }

        final existingText = _recognizedBackupText.trim();
        final newText = existingText.isEmpty ? transcript : '$existingText $transcript';
        _transcriptSubject.add(newText);
        _recognizedBackupText = '';
      } else if (streamed.statusCode == 413) {
        _errorSubject.add('Audio too large. Try a shorter recording.');
      } else if (streamed.statusCode == 429) {
        _errorSubject.add('Rate limited by OpenAI. Try again in a moment.');
      } else {
        try {
          final err = jsonDecode(body);
          _errorSubject.add('OpenAI error: ${err['error']?['message'] ?? body}');
        } catch (_) {
          _errorSubject.add('Transcription failed (${streamed.statusCode}).');
        }
      }
    } on SocketException {
      _errorSubject.add('Network error. Check your internet connection.');
    } on TimeoutException {
      _errorSubject.add('Upload/processing timed out. Try a shorter clip.');
    } catch (e) {
      debugPrint('🔥 Exception during transcription: $e');
      _errorSubject.add('Transcription error: $e');
    }
  }






  double _normalizeRms(num raw) {
    double v = raw.toDouble();

    // Convert dB to linear if needed
    if (v < 0 && v >= -120.0) {
      v = math.pow(10.0, v / 20.0).toDouble(); // -> 0..1 for -∞..0 dB
    }

    if (v.isNaN || v.isInfinite) v = 0.0;
    v = v.abs();
    v = v.clamp(0.0, 1.0);

    // ✅ MUCH LIGHTER compression - preserves amplitude dynamics
    // Changed from 0.6 to 0.85 for better loudness variation
    v = math.pow(v, 0.85).toDouble();

    return v;
  }




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
    _waveformRmsSubject.close();  // Don't forget the waveform stream
    _transcriptSubject.close();
    _recordingDurationSubject.close();
    _errorSubject.close();
  }
}