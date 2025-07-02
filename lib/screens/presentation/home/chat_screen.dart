// ignore_for_file: unused_field

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
//import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:http_parser/http_parser.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:record/record.dart';
import 'package:vscmoney/constants/colors.dart';

// Import your existing chat service files
import '../../../constants/widgets.dart';
import '../../../models/chat_message.dart';
import '../../../models/chat_session.dart';
import '../../../services/chat_service.dart';
import '../../../services/locator.dart';
import '../../../services/theme_service.dart';
import '../../../testpage.dart';
import '../../stock_detail_screen.dart';
import 'package:http/http.dart' as http;
import 'package:vscmoney/core/helpers/themes.dart';


class ChatScreen extends StatefulWidget {
  final ChatSession session;
  final ChatService chatService;
  final void Function(int)? onNavigateToTab;
  final void Function(bool)? onFirstMessageComplete;
  const ChatScreen({
    Key? key,
    required this.session,
    required this.chatService,
    this.onNavigateToTab,
    this.onFirstMessageComplete
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver,TickerProviderStateMixin{
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
 // late final SpeechService _speechService;
   ScrollController _scrollController = ScrollController();
  final _audioRecorder = AudioRecorder();
  String _recordingPath = '';
  bool _isTranscribing = false;
  Timer? _levelTimer;
  //final FlutterAudioCapture _audioCapture = FlutterAudioCapture();
  Timer? _transcriptionAnimator;
  //final GlobalKey _latestBotMessageKey = GlobalKey();
  bool _isSpeaking = false;
  double _currentRms = 0.0;
  StreamSubscription? _vadSubscription;
  Timer? _rmsTimer;
  final _textFieldKey = GlobalKey();



  static const _androidMethodChannel = MethodChannel('native_vad');
  static const _androidEventChannel = EventChannel('native_vad/events');
  static const _iosMethodChannel = MethodChannel('yamnet_channel');
  static const _iosEventChannel = EventChannel('yamnet_event_channel');

  // static const MethodChannel _methodChannel = MethodChannel('native_vad');
  // static const EventChannel _eventChannel = EventChannel('native_vad/events');

  late MethodChannel _currentMethodChannel;
  late EventChannel _currentEventChannel;
  bool _showExpandedInput = false;
  bool _isTyping = false;
  bool _isListening = false;
  bool _showSpeechBar = false;
  Stopwatch _speechTimer = Stopwatch();
  late Timer _timer;
  String _formattedDuration = '00:00';
  double _chatHeight = 0;
  bool _showBottomSpacer = true;
  String _recognizedBackupText = '';
  bool _isOverwritingTranscript = false;
  double _keyboardInset = 0;
  double _latestUserMessageHeight = 0;
  final GlobalKey _lastUserMessageKey = GlobalKey();
  bool _isRecording = false;
  double _dragOffset = 0;
  double _micButtonOffset = 0;
  late AnimationController _waveAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _topWaveAnimationController;
  double _displayedRms = 0.0;

  late AnimationController _meshController;
  late List<Animation<Offset>> _meshPositions;
  late List<Animation<Color?>> _meshColors;
  // At the top of _ChatScreenState:
  late AnimationController _heartbeatController;
  double _heartbeatValue = 0.0;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;


  void scrollBubbleToStaticPosition(GlobalKey key, double targetY) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context == null) return;

      final box = context.findRenderObject() as RenderBox;
      final bubbleTop = box.localToGlobal(Offset.zero).dy;

      final currentScroll = _scrollController.offset;
      final delta = bubbleTop - targetY;
      final newScrollOffset = (currentScroll + delta).clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );

      _scrollController.animateTo(
        newScrollOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    });
  }




  // JSON se exact keyframes (18 seconds total, 60fps)
  final List<List<double>> layer1Positions = [
    [81.12/375, 333.86/812],   // t=0
    [303.12/375, 326.86/812],  // t=180 (3s)
    [307.12/375, 683.86/812],  // t=360 (6s)
    [84.12/375, 378.86/812],   // t=540 (9s)
    [56.12/375, 679.86/812],   // t=720 (12s)
    [160.12/375, 458.86/812],  // t=900 (15s)
    [81.12/375, 333.86/812],   // t=1080 (18s)
  ];

  final List<List<double>> layer2Positions = [
    [403.93/375, 421.47/812],
    [145.93/375, 712.47/812],
    [56.93/375, 472.47/812],
    [306.93/375, 413.47/812],
    [85.93/375, 386.47/812],
    [41.93/375, 660.47/812],
    [403.93/375, 421.47/812],
  ];

  final List<List<double>> layer3Positions = [
    [294/375, 683.5/812],
    [337/375, 540.5/812],
    [120/375, 755.5/812],
    [271/375, 712.5/812],
    [292/375, 450.5/812],
    [271/375, 692.5/812],
    [294/375, 683.5/812],
  ];

  final List<List<double>> layer4Positions = [
    [30.07/375, 579.46/812],
    [-2.93/375, 451.46/812],
    [314.07/375, 468.46/812],
    [13.07/375, 684.46/812],
    [243.07/375, 756.46/812],
    [227.07/375, 468.46/812],
    [30.07/375, 579.46/812],
  ];

  final List<List<Color>> layerColors = List.generate(4, (_) => [
    const Color(0xFFC06622),
    const Color(0xFF7C5E57),
    const Color(0xFFC06622),
    // Start: brown
    // Mid: orange
    const Color(0xFFC06622), // End: brown again
  ]);

  // JSON se exact colors (RGB values converted)
  // final List<List<Color>> layerColors = [
  //   [
  //     Color(0xFF7C5E57),
  //     Color(0xFFC06622),
  //     Color(0xFF9F4B0C),
  //     Color(0xFF7C5E57),
  //   ],
  //   [
  //     Color(0xFF7C5E57),
  //     Color(0xFFC06622),
  //     Color(0xFF9F4B0C),
  //     Color(0xFF7C5E57),
  //   ],
  //   [
  //     Color(0xFF7C5E57),
  //     Color(0xFFC06622),
  //     Color(0xFF9F4B0C),
  //     Color(0xFF7C5E57),
  //   ],
  //   [
  //     Color(0xFF7C5E57),
  //     Color(0xFFC06622),
  //     Color(0xFF9F4B0C),
  //     Color(0xFF7C5E57),
  //   ],
  // ];


  void _setupMeshAnimation() {
    // 18 seconds total (exactly like JSON: 1080 frames at 60fps)
    _meshController = AnimationController(
      duration: Duration(seconds: 50),
      vsync: this,
    )..addListener(() {
      setState(() {
      });
    });

    // Create position animations for all 4 layers
    _meshPositions = [
      _createPositionAnimation(layer1Positions),
      _createPositionAnimation(layer2Positions),
      _createPositionAnimation(layer3Positions),
      _createPositionAnimation(layer4Positions),
    ];

    // Create color animations for all 4 layers
    _meshColors = [
      _createColorAnimation(layerColors[0]),
      _createColorAnimation(layerColors[1]),
      _createColorAnimation(layerColors[2]),
      _createColorAnimation(layerColors[3]),
    ];

    // Start from orange color (value 0.0)
    _meshController.value = 0.0;
    _meshController.repeat();
  }

// // Fixed animation update method
//   void _updateMeshAnimationSpeed(bool isSpeaking) {
//     // DON'T reset the value - keep current position
//     final currentValue = _meshController.value;
//
//     _meshController.stop();
//
//     // Update duration based on speech state
//     _meshController.duration = isSpeaking
//         ? const Duration(seconds: 10) // Even faster for speech
//         : const Duration(seconds: 500); // Normal speed otherwise
//
//     // Start from current position, not 0.0
//     _meshController.forward(from: currentValue);
//
//     // Continue repeating
//     _meshController.repeat();
//   }

  bool _showStaticGradient = false;

  void _updateMeshAnimationSpeed(bool isSpeaking) {
    final currentValue = _meshController.value;

   // if (isSpeaking) {
      //_showStaticGradient = false;

      _meshController.stop();
      _meshController.duration = const Duration(seconds: 10);
      _meshController.forward(from: currentValue);
      _meshController.repeat();
    //}
    //else {
      //_showStaticGradient = true;

      // _meshController.stop();
      // _meshController.value = 0.0; // optional reset to start
    //}
  }









  Animation<Offset> _createPositionAnimation(List<List<double>> keyframes) {
    return TweenSequence<Offset>([
      for (int i = 0; i < keyframes.length - 1; i++)
        TweenSequenceItem(
          tween: Tween<Offset>(
            begin: Offset(keyframes[i][0], keyframes[i][1]),
            end: Offset(keyframes[i + 1][0], keyframes[i + 1][1]),
          ).chain(CurveTween(curve: Curves.easeInOut)), // JSON ka easing
          weight: 1.0,
        ),
    ]).animate(_meshController);
  }

  // Animation<Color?> _createColorAnimation(List<Color> colors) {
  //   return
  //     TweenSequence<Color?>([
  //     for (int i = 0; i < colors.length - 1; i++)
  //       TweenSequenceItem(
  //         tween: ColorTween(begin: colors[i], end: colors[i + 1]),
  //         weight: 1.0,
  //       ),
  //   ]).animate(_meshController);
  // }

  Animation<Color?> _createColorAnimation(List<Color> colors) {
    assert(colors.length >= 2, "At least 2 colors are required for animation");

    return TweenSequence<Color?>(
      List.generate(colors.length - 1, (i) {
        return TweenSequenceItem(
          tween: ColorTween(
            begin: colors[i],
            end: colors[i + 1],
          ),
          weight: 1,
        );
      }),
    ).animate(_meshController);
  }


  void _animateTranscriptionToInput(String finalText) {
    _transcriptionAnimator?.cancel();

    setState(() {
      _controller.text = finalText;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      _isListening = false;
      _isTranscribing = false;
      _isOverwritingTranscript = false; // reset color flag
    });
  }




  void _scrollToLatestLikeChatPage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final offset = _scrollController.offset;
      var targetOffset = (offset + _chatHeight).clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );
     // var targetOffset = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - 100 - 16;
    //  targetOffset -= MediaQuery.of(context).padding.top + 354 ;
    //   print(targetOffset);
    //   print(offset);
    //   print("Target");
    //   print(_scrollController.position.maxScrollExtent,);
    //   print("Max");
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  // void _scrollToLatestLikeChatPage() {
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (!_scrollController.hasClients) return;
  //
  //     final offset = _scrollController.offset;
  //     final targetOffset = (offset + _chatHeight).clamp(
  //       _scrollController.position.minScrollExtent,
  //       _scrollController.position.maxScrollExtent,
  //     );
  //
  //     _scrollController.animateTo(
  //       targetOffset,
  //       duration: const Duration(milliseconds: 400),
  //       curve: Curves.easeOut,
  //     );
  //   });
  // }



  void _startRmsSmoothing() {
    // Cancel any existing timer first
    _rmsTimer?.cancel();

    const smoothingFactor = 0.2; // Lower = smoother

    _rmsTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Only update if there's a significant difference
      double difference = (_currentRms - _displayedRms).abs();
      if (difference > 0.001) {
        setState(() {
          _displayedRms += (_currentRms - _displayedRms) * smoothingFactor;
        });
      }
    });
  }

  void _stopRmsSmoothing() {
    _rmsTimer?.cancel();
    _rmsTimer = null;
  }



















  Future<void> startNativeVad() async {
    try {

      var timeStamp = DateTime.now();
      await _vadSubscription?.cancel();

      // Platform-wise event channel
      final EventChannel eventChannel = Platform.isIOS ? _iosEventChannel : _androidEventChannel;
      final MethodChannel methodChannel = Platform.isIOS ? _iosMethodChannel : _androidMethodChannel;

      _vadSubscription = eventChannel.receiveBroadcastStream().listen((event) {
        // iOS/Android - event keys may differ, so normalize here
        final isSpeech = event['isSpeech'] ?? event['state'] == 'speech_detected' || false;
        // On Android, key is usually 'rms'; on iOS, it's often 'rms' or 'rms_db'
        final rms = (event['rms'] ?? event['rms_db'] ?? 0.0).toDouble();

        debugPrint('🎙️ VAD => isSpeech=$isSpeech | rms=${rms.toStringAsFixed(2)}| ${DateTime.now()}');

        if (mounted) {
          setState(() {
            _isSpeaking = isSpeech;
            _currentRms = rms;
            _updateHeartbeat(_isSpeaking);
            _updateMeshAnimationSpeed(_isSpeaking);
            if (isSpeech) {
              double maxRms = 0.20; // Or your dynamic scaling value
              double speed = lerpDouble(0.6, 1.3, (rms / maxRms).clamp(0, 1))!;
              _heartbeatController.duration = Duration(milliseconds: (900 ~/ speed).clamp(300, 1200));
              if (!_heartbeatController.isAnimating) _heartbeatController.repeat();
            } else {
              _heartbeatController.stop();
              _heartbeatController.value = 0.0;
            }
          });
        }
      });


      // _vadSubscription = eventChannel.receiveBroadcastStream().listen((event) {
      //   // iOS/Android - event keys may differ, so normalize here
      //   final isSpeech = event['isSpeech'] ?? event['state'] == 'speech_detected' || false;
      //   final rms = (event['rms'] ?? event['rms_db'] ?? 0.0).toDouble();
      //
      //   // Add RMS threshold check here too
      //   double minRmsThreshold = 0.02; // Same threshold as waveform
      //   bool actualSpeechDetected = isSpeech && rms > minRmsThreshold;
      //
      //   debugPrint('🎙️ VAD => isSpeech=$isSpeech | rms=${rms.toStringAsFixed(2)} | actual=$actualSpeechDetected');
      //
      //   if (mounted) {
      //     setState(() {
      //       _isSpeaking = actualSpeechDetected; // Use the refined detection
      //       _currentRms = rms;
      //       _updateHeartbeat(_isSpeaking);
      //       _updateMeshAnimationSpeed(_isSpeaking);
      //
      //       if (actualSpeechDetected) {
      //         double maxRms = 0.20;
      //         double speed = lerpDouble(0.6, 1.3, (rms / maxRms).clamp(0, 1))!;
      //         _heartbeatController.duration = Duration(milliseconds: (900 ~/ speed).clamp(300, 1200));
      //         if (!_heartbeatController.isAnimating) _heartbeatController.repeat();
      //       } else {
      //         _heartbeatController.stop();
      //         _heartbeatController.value = 0.0;
      //       }
      //     });
      //   }
      // });

      // Only once, when VAD starts
      _startRmsSmoothing();

      await methodChannel.invokeMethod('start');
    } catch (e) {
      debugPrint('❌ startNativeVad error: $e');
    }
  }

  Future<void> stopNativeVad() async {
    try {
      final MethodChannel methodChannel = Platform.isIOS ? _iosMethodChannel : _androidMethodChannel;
      await methodChannel.invokeMethod('stop');
      await _vadSubscription?.cancel();
      _vadSubscription = null;

      // Stop RMS smoothing
      _stopRmsSmoothing();
      // _meshController.stop();
      // _meshController.value = 0.0;
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _currentRms = 0.0;
          _displayedRms = 0.0;
        });
      }
    } catch (e) {
      debugPrint('❌ stopNativeVad error: $e');
    }
  }






















//   Future<void> startNativeVad() async {
//     try {
//       await _vadSubscription?.cancel();
//       _vadSubscription = _eventChannel.receiveBroadcastStream().listen((event) {
//         final isSpeech = event['isSpeech'] ?? false;
//         final rms = (event['rms'] ?? 0.0).toDouble();
//
//         debugPrint('🎙️ VAD => isSpeech=$isSpeech | rms=${rms.toStringAsFixed(2)}');
//
//         // if (mounted) {
//         //   setState(() {
//         //     _isSpeaking = isSpeech;
//         //     _currentRms = rms;
//         //    _updateMeshAnimationSpeed(_isSpeaking);
//         //   });
//         // }
//
//         if (mounted) {
//           setState(() {
//             _isSpeaking = isSpeech;
//             _currentRms = rms;
//             //_updateMeshAnimationSpeed(_isSpeaking);
//             _updateHeartbeat(_isSpeaking);
//
//             // Heartbeat Animation logic
//             if (isSpeech) {
//               double maxRms = 0.20;
//               double speed = lerpDouble(0.6, 1.3, (rms / maxRms).clamp(0,1))!;
//               // Clamp speed, so heartbeat duration doesn't go wild
//               _heartbeatController.duration = Duration(milliseconds: (900 ~/ speed).clamp(300, 1200));
//               if (!_heartbeatController.isAnimating) _heartbeatController.repeat();
//             } else {
//               _heartbeatController.stop();
//               _heartbeatController.value = 0.0;
//             }
//           });
//         }
//
//       });
//
//       // Start smoothing only once when VAD starts
//       _startRmsSmoothing();
//
//       await _methodChannel.invokeMethod('start');
//     } catch (e) {
//       debugPrint('❌ startNativeVad error: $e');
//     }
//   }
//
// // In your stopNativeVad method, add stop smoothing:
//   Future<void> stopNativeVad() async {
//     try {
//       await _methodChannel.invokeMethod('stop');
//       await _vadSubscription?.cancel();
//       _vadSubscription = null;
//
//       // Stop RMS smoothing
//       _stopRmsSmoothing();
//
//       if (mounted) {
//         setState(() {
//           _isSpeaking = false;
//           _currentRms = 0.0;
//           _displayedRms = 0.0; // Reset displayed RMS
//         });
//       }
//     } catch (e) {
//       debugPrint('❌ stopNativeVad error: $e');
//     }
//   }







  // Flag to show only latest exchange during typing


  bool _showOnlyLatestDuringTyping = false;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;

    // If minutes is single digit (0-9), don't pad with zero
    if (minutes < 10) {
      return "${minutes}:${seconds.toString().padLeft(2, '0')}";
    } else {
      // If minutes is double digit (10+), use normal format
      return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    }
  }


  String sanitizeMessage(String input) {
    // Removes weird unicode chars and normalizes quotes
    return input
        .replaceAll(RegExp(r'[^\x00-\x7F]'), '') // remove non-ascii chars
        .replaceAll('’', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .trim();
  }


  // Main state variables for messages
  List<Map<String, Object>> messages = [];
  StreamSubscription<ChatMessage>? _streamSubscription;
  String _currentStreamingId = '';
  bool _hasLoadedMessages = false;
  bool _firstMessageComplete = false;



  @override
  void initState() {
    super.initState();
    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700), // 700ms feels natural
    );

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.10).animate(
      CurvedAnimation(parent: _heartbeatController, curve: Curves.easeInOutCubic),
    );

    _glowAnim = Tween<double>(begin: 12, end: 32).animate(
      CurvedAnimation(parent: _heartbeatController, curve: Curves.easeInOutCubic),
    );
    _loadSessionMessages();
    _setupMeshAnimation();
    print("session id");
    print(widget.session.id);
    _scrollController = ScrollController(keepScrollOffset: true);
    WidgetsBinding.instance.addObserver(this);
  //  _scrollToBottom();
    // Add a small delay to request focus to avoid keyboard issues
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      final shouldShow = _scrollController.offset < _scrollController.position.maxScrollExtent - 100;
      if (_showScrollToBottomButton != shouldShow) {
        setState(() {
          _showScrollToBottomButton = shouldShow;
        });
      }
    });

    _focusNode.addListener(_onFocusChange);
   // _speechService = SpeechService();
    //_initializeSpeech();



  }


  void _updateHeartbeat(bool isSpeaking) {
    if (isSpeaking) {
      _heartbeatController.repeat(reverse: true);
    } else {
      _heartbeatController.animateTo(0.0, duration: Duration(milliseconds: 280), curve: Curves.easeOutCubic);
      _heartbeatController.stop();
    }
  }



  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;

    // If keyboard is opened
    if (bottomInset > 0.0) {
      // Wait for keyboard to settle then scroll
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
    if (mounted) {
      setState(() {
        _keyboardInset = bottomInset;
      });
    }
  }


  void _loadSessionMessages() async {
    setState(() {
      messages = [];
    });

    try {
      print("Loading messages for session ID: ${widget.session.id}");
      final fetched = await widget.chatService.fetchMessages(widget.session.id);
      print("✅ Fetched ${fetched.length} messages");

      if (!mounted) return;

      if (fetched.isEmpty) {
        print("No messages found for this conversation");
        setState(() {
          _hasLoadedMessages = true;
        });
        return;
      }

      setState(() {
        // for (final m in fetched) {
        //   // Add user message
        //   messages.add({
        //     'id': UniqueKey().toString(),
        //     'role': 'user',
        //     'msg': m.question,
        //     'isComplete': true,
        //   });
        //
        //   // Add bot message
        //   messages.add({
        //     'id': UniqueKey().toString(),
        //     'role': 'bot',
        //     'msg': m.answer,
        //     'isComplete': true,
        //   });
        // }
        for (final message in fetched) {
          // If this is a system-only message
          messages.add({
            'role': 'user',
            'msg': message.question,
          });

          messages.add({
            'role': 'bot',
            'msg': message.answer,
          });
                        }


        _hasLoadedMessages = true;
      });

      _checkAndNotifyFirstMessageComplete();
      _scrollToBottom();
    } catch (e) {
      print("❌ Error loading messages: $e");

      if (mounted) {
        setState(() {
          _hasLoadedMessages = true; // Mark as loaded even on error
        });

        // Optionally show an error message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load conversation messages'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  void _checkAndNotifyFirstMessageComplete() {
    if (!_firstMessageComplete && _isChatComplete()) {
      _firstMessageComplete = true;
      // Notify parent component that first message is complete
      widget.onFirstMessageComplete?.call(true);
    }
  }




  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _showExpandedInput = _focusNode.hasFocus;
      });
    }
  }

  List<Map<String, Object>> get _visibleMessages {
    if (_showOnlyLatestDuringTyping && messages.length > 2) {
      return messages.sublist(messages.length - 2);
    }
    return messages;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatController.dispose();
    _transcriptionAnimator?.cancel();
    _streamSubscription?.cancel();
    _meshController.dispose();
    _rmsTimer?.cancel(); // Add this line
    _levelTimer?.cancel();
    _audioRecorder.dispose();
    //_audioPlayer.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _waveAnimationController.dispose();
    _pulseAnimationController.dispose();
    _slideAnimationController.dispose();
    _topWaveAnimationController.dispose();
    //_speechService.stopListening();
    super.dispose();
  }







  // void alignMessageTopToStaticY(GlobalKey messageKey, {double staticY = 250.0}) {
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     final messageContext = messageKey.currentContext;
  //
  //     if (messageContext == null) {
  //       print("⏳ Message context not ready, retrying...");
  //       Future.delayed(Duration(milliseconds: 100), () {
  //         alignMessageTopToStaticY(messageKey, staticY: staticY);
  //       });
  //       return;
  //     }
  //
  //     final RenderBox messageBox = messageContext.findRenderObject() as RenderBox;
  //     final double messageTop = messageBox.localToGlobal(Offset.zero).dy;
  //
  //     final double adjustment = messageTop - staticY;
  //
  //     print(" Message Top Y: $messageTop");
  //     print(" Static Target Y: $staticY");
  //     print(" Scroll Adjustment: $adjustment");
  //     print("Offset: ${_scrollController.offset}");
  //
  //     _scrollController.animateTo(
  //       _scrollController.offset + adjustment,
  //       duration: const Duration(milliseconds: 300),
  //       curve: Curves.easeOut,
  //     );
  //   });
  // }









  bool _userScrolledUp = false;


  void _sendMessage() async {
    if (!mounted || _controller.text.trim().isEmpty) return;

    FocusScope.of(context).unfocus();
    final userMessage = sanitizeMessage(_controller.text.trim());
    final isFirstMessage = messages.where((m) => m['role'] == 'user').isEmpty;
    final userMessageKey = GlobalKey();
    final userMessageId = UniqueKey().toString();
    final botMessageId = UniqueKey().toString();

    setState(() {
      _isTyping = true;
      _showBottomSpacer = true;


      messages.add({
        'id': userMessageId,
        'role': 'user',
        'msg': userMessage,
        'isComplete': true,
        'key': userMessageKey
      });

      messages.add({
        'id': botMessageId,
        'role': 'bot',
        'msg': '',
        'isComplete': false,
      });

      _controller.clear();

      if (isFirstMessage) {
        widget.session.title = userMessage;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = userMessageKey.currentContext;
        if (context != null) {
          final height = context.size?.height ?? 0;
          print("✅ User message bubble height: $height");

          setState(() {
            _latestUserMessageHeight = height;
          });
        } else {
          print("⚠️ userMessageKey context is null");
        }
      });

      //scrollBubbleToStaticPosition(userMessageKey, MediaQuery.of(context).size.height - 220);

    });

    _scrollToLatestLikeChatPage();

  //  _alignUserMessageToStaticTop(userMessageKey);


    try {
      if (isFirstMessage) {
        await widget.chatService.updateSessionTitle(widget.session.id, userMessage);
      }

      final responseStream = await widget.chatService.sendMessageWithStreaming(
        sessionId: widget.session.id,
        message: userMessage,
      );

      String streamedText = '';
      _currentStreamingId = '';
      int lastUpdateTime = DateTime.now().millisecondsSinceEpoch;

      _streamSubscription = responseStream.listen(
            (message) {
          if (!mounted) return;

          if (_currentStreamingId.isEmpty) {
            _currentStreamingId = message.id;
          }

          streamedText += message.text;
          final lastIndex = messages.length - 1;
          final currentTime = DateTime.now().millisecondsSinceEpoch;
          final timeSinceLastUpdate = currentTime - lastUpdateTime;

          if (timeSinceLastUpdate > 50 || message.isComplete) {
            if (lastIndex >= 0 && messages[lastIndex]['role'] == 'bot') {
              setState(() {
                messages[lastIndex] = {
                  'id': botMessageId,
                  'role': 'bot',
                  'msg': streamedText,
                  'isComplete': message.isComplete,
                };
              });

              lastUpdateTime = currentTime;

              // if (_showOnlyLatestDuringTyping) {
              //   _scrollToBottom();
              // }
              _scrollController.addListener(() {
                if (_scrollController.offset < _scrollController.position.maxScrollExtent - 100) {
                  _userScrolledUp = true;
                } else {
                  _userScrolledUp = false;
                }
              });

            }
          }

          if (message.isComplete) {
            if (!mounted) return;

            setState(() {
              _showBottomSpacer = false;
              _isTyping = false;

              if (lastIndex >= 0 && messages[lastIndex]['role'] == 'bot') {
                messages[lastIndex] = {
                  'id': botMessageId,
                  'role': 'bot',
                  'msg': streamedText,
                  'isComplete': true,
                };
              }
            });

            _checkAndNotifyFirstMessageComplete();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() {});
            });

            if (streamedText.contains('"stocks":')) {
              try {
                final cleaned = streamedText
                    .replaceAll("```json", "")
                    .replaceAll("```", "")
                    .trim();
                final data = jsonDecode(cleaned);
                final List<dynamic> stocks = data['stocks'];
                setState(() {
                  messages.removeLast();
                  messages.add({
                    'id': UniqueKey().toString(),
                    'role': 'bot',
                    'msg': '',
                    'type': 'stocks',
                    'stocks': stocks,
                  });
                });
              } catch (e) {
                print('❌ Error parsing stock JSON: $e');
              }
            }
          }
        },
        onError: (e) {
          if (!mounted) return;

          setState(() {
            _isTyping = false;
            _showOnlyLatestDuringTyping = false;

            final lastIndex = messages.length - 1;
            if (lastIndex >= 0 && messages[lastIndex]['role'] == 'bot') {
              messages[lastIndex] = {
                'id': botMessageId,
                'role': 'bot',
                'msg': '❌ Failed to respond. ',
                'isComplete': true,
                'retry': true,
                'originalMessage': userMessage,
              };
            }
          });

          _scrollToLatestLikeChatPage();
        },
      );
    } catch (e) {
      print("❌ Error sending message: $e");

      if (mounted) {
        setState(() {
          _isTyping = false;
          _showOnlyLatestDuringTyping = false;

          final lastIndex = messages.length - 1;
          if (lastIndex >= 0 && messages[lastIndex]['role'] == 'bot') {
            messages[lastIndex] = {
              'id': botMessageId,
              'role': 'bot',
              'msg': '❌ Failed to send. ',
              'isComplete': true,
              'retry': true,
              'originalMessage': userMessage,
            };
          }
        });

        _scrollToLatestLikeChatPage();
      }
    }
  }






















  void _stopResponse() {
    try {
      _streamSubscription?.cancel();
      _streamSubscription = null;

      if (_currentStreamingId.isNotEmpty) {
        widget.chatService.stopResponse(
          widget.session.id,
          _currentStreamingId,
        );
      }
    } catch (e) {
      print('Error stopping response: $e');
    }

    if (mounted) {
      setState(() {
        final lastIndex = messages.length - 1;
        if (lastIndex >= 0) {
          messages[lastIndex] = {
            ...messages[lastIndex],
            'isComplete': true,
          };
        }
        _isTyping = false;
        _showOnlyLatestDuringTyping = false;
        // 👇 Don't scroll here
      });
      _checkAndNotifyFirstMessageComplete();
    }
  }


  bool _isChatComplete() {
    int userCount = 0;
    int botCount = 0;

    for (var m in messages) {
      if (m['role'] == 'user') userCount++;
      if (m['role'] == 'bot' && (m['isComplete'] == true)) botCount++;
    }

    return userCount >= 1 && botCount >= 1;
  }



  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      print(_scrollController.position.maxScrollExtent);
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent - (_chatHeight * 0.75),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _showScrollToBottomButton = false;


  void _measureLatestUserHeight(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context != null) {
        final RenderBox? box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final height = box.size.height;
          if (mounted) {
            setState(() {
              _latestUserMessageHeight = height;
            });
          }
          print("📏 Updated latest user message height: $height");
        }
      }
    });
  }


  Widget _buildMessageRow(Map<String, Object> msg) {
    final bool isUser = msg['role'] == 'user';
    final bool isLatest = msg == messages.last;

    final bubbleKey = msg['key'] as GlobalKey?;
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    // 🧱 Function to get height from GlobalKey
    void measureBubbleHeight(GlobalKey key) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = key.currentContext;
        if (context != null) {
          final RenderBox? box = context.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) {
            final height = box.size.height;
            print("📏 User message bubble height: $height");
          } else {
            print("⚠️ RenderBox is not ready or has no size.");
          }
        } else {
          print("⛔ Context is null for user bubble.");
        }
      });
    }

    if (isUser) {
      // ✅ Trigger height measurement for latest user message only
      if (isLatest && bubbleKey != null) {
        _measureLatestUserHeight(bubbleKey);
      }

      return Transform.translate(
        offset: const Offset(0, 10),
        child: Padding(
          padding: const EdgeInsets.only(top: 0, bottom: 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: msg['msg'].toString()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  child: const Icon(Icons.copy, size: 14, color: Color(0XFF7E7E7E)),
                ),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                  ),
                  child: Container(
                    key: bubbleKey,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      color: theme.message,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      msg['msg'].toString(),
                      style: TextStyle(
                        height: 1.9,
                        fontFamily: 'DM Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: theme.text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (msg['type'] == 'stocks' && msg['stocks'] is List) {
      final List<dynamic> stocks = msg['stocks'] as List<dynamic>;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: _buildStockTileList(stocks),
      );
    }

    // 🧠 Default bot message
    final msgStr = msg['msg']?.toString() ?? '';
    final isComplete = msg['isComplete'] == true;

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          msgStr.isEmpty
              ? _buildTypingIndicator()
              : _buildStyledBotMessage(
            fullText: msgStr,
            isComplete: isComplete,
            isLatest: isLatest,
          ),
        ],
      ),
    );
  }


  // Widget _buildMessageRow(Map<String, Object> msg) {
  //   final bool isUser = msg['role'] == 'user';
  //   final bool isLatest = msg == messages.last;
  //
  //   final bubbleKey = msg['key'] as Key?;
  //   final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
  //
  //
  //   if (isUser) {
  //     // return Transform.translate(
  //     //   offset: const Offset(0, 10),
  //     //   child: Padding(
  //     //     padding: const EdgeInsets.only(top: 0, bottom: 0),
  //     //     child: Align(
  //     //       alignment: Alignment.centerRight,
  //     //       child: Row(
  //     //         mainAxisAlignment: MainAxisAlignment.end,
  //     //         children: [
  //     //           const SizedBox(width: 14),
  //     //           GestureDetector(
  //     //             onTap: () {
  //     //               Clipboard.setData(ClipboardData(text: msg['msg'].toString()));
  //     //               ScaffoldMessenger.of(context).showSnackBar(
  //     //                 const SnackBar(content: Text('Copied to clipboard')),
  //     //               );
  //     //             },
  //     //             child: const Icon(Icons.copy, size: 14, color: Color(0XFF7E7E7E)),
  //     //           ),
  //     //           const SizedBox(width: 10),
  //     //           Flexible(
  //     //             child: Container(
  //     //               key: bubbleKey, // ✅ assign key only to latest user message
  //     //               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  //     //               margin: const EdgeInsets.only(bottom: 2),
  //     //               decoration: BoxDecoration(
  //     //                 color: theme.message,
  //     //                 borderRadius: BorderRadius.circular(22),
  //     //               ),
  //     //               child: Text(
  //     //                 msg['msg'].toString(),
  //     //                 style: TextStyle(
  //     //                   // fontSize: 17,
  //     //                   // fontFamily: '.SF Pro Text',
  //     //                   // fontWeight: FontWeight.normal,
  //     //                   // color: theme.text,
  //     //                   height: 1.9,
  //     //                   fontFamily: 'SF Pro Text',
  //     //                   fontSize: 17.5,
  //     //                   fontWeight: FontWeight.w500,
  //     //                   color: Colors.black.withOpacity(0.85),
  //     //                 ),
  //     //               ),
  //     //             ),
  //     //           ),
  //     //         ],
  //     //       ),
  //     //     ),
  //     //   ),
  //     // );
  //     return Transform.translate(
  //       offset: const Offset(0, 10),
  //       child: Padding(
  //         padding: const EdgeInsets.only(top: 0, bottom: 0),
  //         child: Align(
  //           alignment: Alignment.centerRight,
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.end,
  //             children: [
  //               const SizedBox(width: 14),
  //               GestureDetector(
  //                 onTap: () {
  //                   Clipboard.setData(ClipboardData(text: msg['msg'].toString()));
  //                   ScaffoldMessenger.of(context).showSnackBar(
  //                     const SnackBar(content: Text('Copied to clipboard')),
  //                   );
  //                 },
  //                 child: const Icon(Icons.copy, size: 14, color: Color(0XFF7E7E7E)),
  //               ),
  //               const SizedBox(width: 10),
  //               ConstrainedBox(
  //                 constraints: BoxConstraints(
  //                   maxWidth: MediaQuery.of(context).size.width * 0.6,
  //                 ),
  //                 child: Container(
  //                   key: bubbleKey, // ✅ assign key only to latest user message
  //                   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  //                   margin: const EdgeInsets.only(bottom: 2),
  //                   decoration: BoxDecoration(
  //                     boxShadow: [
  //                       BoxShadow(
  //                         color: Colors.black.withOpacity(0.08),
  //                         blurRadius: 10,
  //                         offset: const Offset(0, 3),
  //                       ),
  //                     ],
  //                     color: theme.message,
  //                     borderRadius: BorderRadius.circular(22),
  //                   ),
  //                   child: Text(
  //                     msg['msg'].toString(),
  //                     style: TextStyle(
  //                       height: 1.9,
  //                       fontFamily: 'DM Sans',
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.w500,
  //                       color: theme.text,
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     );
  //
  //   }
  //   // if (msg['role'] == 'user') {
  //   //   return Transform.translate(
  //   //     offset: const Offset(0, 25),
  //   //     child: Padding(
  //   //       padding: const EdgeInsets.only(top: 2, bottom: 0), // 🔻 tighter vertical gap
  //   //       child: Align(
  //   //         alignment: Alignment.centerRight,
  //   //         child: Row(
  //   //           mainAxisAlignment: MainAxisAlignment.end,
  //   //           children: [
  //   //             const SizedBox(width: 14),
  //   //             GestureDetector(
  //   //               onTap: () {
  //   //                 Clipboard.setData(ClipboardData(text: msg['msg'].toString()));
  //   //                 ScaffoldMessenger.of(context).showSnackBar(
  //   //                   const SnackBar(content: Text('Copied to clipboard')),
  //   //                 );
  //   //               },
  //   //               child: const Icon(Icons.copy, size: 14, color: Color(0XFF7E7E7E)),
  //   //             ),
  //   //             const SizedBox(width: 10),
  //   //             Flexible(
  //   //               child: Container(
  //   //                 key: msg == messages.last ? _latestBotMessageKey : null,
  //   //                 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  //   //                 margin: const EdgeInsets.only(bottom: 2), // 🔻 reduce bottom gap
  //   //                 decoration: BoxDecoration(
  //   //                   color: theme.message,
  //   //                   borderRadius: BorderRadius.circular(22),
  //   //                 ),
  //   //                 child: Text(
  //   //                   msg['msg'].toString(),
  //   //                   style: TextStyle(
  //   //                     fontSize: 18,
  //   //                     fontFamily: 'SF Pro Text',
  //   //                     fontWeight: FontWeight.w500,
  //   //                     color: theme.text,
  //   //                     height: 1.9,
  //   //                   ),
  //   //                 ),
  //   //               ),
  //   //             ),
  //   //           ],
  //   //         ),
  //   //       ),
  //   //     ),
  //   //   );
  //   // }
  //
  //   if (msg['type'] == 'stocks' && msg['stocks'] is List) {
  //     final List<dynamic> stocks = msg['stocks'] as List<dynamic>;
  //     return Padding(
  //       padding: const EdgeInsets.symmetric(vertical: 4), // 🔻 reduced for stock tiles too
  //       child: _buildStockTileList(stocks),
  //     );
  //   }
  //
  //   // Default bot message
  //   final msgStr = msg['msg']?.toString() ?? '';
  //   final isComplete = msg['isComplete'] == true;
  //  // final isLatest = msg == messages.last;
  //
  //   return Align(
  //     alignment: Alignment.centerLeft,
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //      // mainAxisSize: MainAxisSize.min,
  //       children: [
  //         msgStr.isEmpty
  //             ? _buildTypingIndicator()
  //             :  _buildStyledBotMessage(
  //           fullText: msgStr,
  //           isComplete: isComplete,
  //           isLatest: isLatest,
  //         ),
  //       ],
  //     ),
  //   );
  //
  // }





  Widget _buildStockTileList(List<dynamic> stocks) {
    return Column(
      children: stocks.map((stock) {
        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => StockDetailScreen(symbol: stock['name'] ?? '',),
            ));
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  stock['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("₹${stock['price']}"),
                    Text(
                      stock['change'] ?? '',
                      style: TextStyle(
                        color: (stock['change'] as String).startsWith('+')
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }



  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      height: 15,
      width: 65,
      child: Lottie.asset(
        'assets/images/typing_loader.json',
        repeat: true,
        fit: BoxFit.contain,
      ),
    );
  }


  Future<void> _transcribeAudio() async {
    print("🎤 Starting transcription process");

    if (_recordingPath.isEmpty) {
      print("❌ Recording path is empty");
      setState(() {
        _isListening = false;
        _showSpeechBar = false;
        _isTranscribing = false;
        _isOverwritingTranscript = false;
      });
      return;
    }

    final file = File(_recordingPath);
    if (!file.existsSync()) {
      print("❌ File not found at: $_recordingPath");
      setState(() {
        _isListening = false;
        _showSpeechBar = false;
        _isTranscribing = false;
        _isOverwritingTranscript = false;
      });
      return;
    }

    print("📁 File size: ${file.lengthSync()} bytes");
    //final String _baseUrl= 'http://127.0.0.1:8000';
    final String _baseUrl = "https://fastapi-chatbot-717280964807.asia-south1.run.app";
    try {
      print("⏳ Sending file to transcription API");

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/audio/transcribe'),
      );

      var multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType('audio', 'wav'),
      );

      print('📤 Uploading file: ${multipartFile.filename}, size: ${multipartFile.length}');
      request.files.add(multipartFile);

      var response = await request.send();
      print('✅ Response status: ${response.statusCode}');

      final responseBody = await response.stream.bytesToString();
      print('📩 Response body: $responseBody');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        final transcript = jsonResponse['transcript'] ?? '';
        print('📄 Transcript received: $transcript');

        if (transcript.isNotEmpty &&
            transcript != 'No speech detected. Please speak clearly and try again.') {
          _recognizedBackupText = '';

          final existingText = _controller.text.trim();
          final newText = existingText.isEmpty ? transcript : '$existingText $transcript';
          HapticFeedback.mediumImpact();
          _animateTranscriptionToInput(newText);
          FocusScope.of(context).requestFocus(_focusNode);
        } else {
          // Empty or failed transcript
          setState(() {
            if (_recognizedBackupText.isNotEmpty) {
              _controller.text = _recognizedBackupText;
              _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _recognizedBackupText.length),
              );
            } else {
              // Keep old text, only show a message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not transcribe audio. Please try again.')),
              );
            }
            _isListening = false;
            _showSpeechBar = false;
            _isTranscribing = false;
            _isOverwritingTranscript = false; // Restore color
          });
        }
      } else {
        print('❌ Transcription failed with status: ${response.statusCode}');
        setState(() {
          _isListening = false;
          _showSpeechBar = false;
          _isTranscribing = false;
          _isOverwritingTranscript = false;
        });
      }
    } catch (e) {
      print('🔥 Exception during transcription: $e');
      setState(() {
        _isListening = false;
        _showSpeechBar = false;
        _isTranscribing = false;
        _isOverwritingTranscript = false;
      });
    }
  }


  Widget _quickChip({
    required String title,
    required String subtitle,
    required double maxWidth,
    required VoidCallback onpressed,
  }) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return GestureDetector(
      onTap: onpressed,
      child: Container(
        height: 200,
        //constraints: BoxConstraints(maxWidth: maxWidth),
        padding:  EdgeInsets.symmetric(horizontal: 15,vertical: 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFAF9F7),
                Color(0xFFF1EAE4),
          ]),
          color: theme.message,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              spreadRadius: 1,
              color: Colors.black.withOpacity(0.08),
              blurRadius: 3,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,  // 👈 optional centering
          crossAxisAlignment: CrossAxisAlignment.start, // 👈 for left-aligned text
          //mainAxisSize: MainAxisSize.max,               // 👈 force Column to fill parent
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'DM Sans',
                color: theme.text,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: theme.text,fontFamily: "SF Pro Text",fontWeight: FontWeight.w500),
            ),
          ],
        ),

      ),
    );
  }

  void onError(Object e) {
    print("Mic monitoring error: $e");
  }



  Widget _buildInputFields() {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return Padding(
      padding: const EdgeInsets.all(1),
      child: Material(
        color: theme.background,
        elevation: 20.0,
        child: Container(
          key: _textFieldKey,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          decoration: BoxDecoration(
            color: theme.background,
            boxShadow: [
              BoxShadow(
                color: theme.shadow,
                blurRadius: 7,
                spreadRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border.all(color: theme.box),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    constraints: BoxConstraints(
                        minHeight: _isListening ? 20 : 70, // ✅ Smooth animated transition
                        maxHeight: 140
                    ),                    child: SingleChildScrollView(
                      child: Scrollbar(
                        child:

                            _isListening ? SizedBox.shrink(): TextField(
                          style: TextStyle(
                            fontFamily: ".SF Pro Text",
                            fontSize: 17.5,
                            fontWeight: FontWeight.w400,
                            color: _isOverwritingTranscript ? Colors.grey.shade400 : theme.text,
                          ),
                          autofocus: true,
                          minLines: 1,
                          maxLines: null,
                          controller: _controller,
                          focusNode: _focusNode,
                          decoration:  InputDecoration(
                            hintStyle: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontFamily: ".SF Pro Text",color: Colors.grey.shade600,fontSize: 17.5),
                            hintText: 'Ask anything',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(left: 0),
                          ),
                          onChanged: (_) {
                            if (mounted) setState(() {});
                          },
                          onSubmitted: (_) {
                            if (mounted) _sendMessage();
                          },
                          textInputAction: TextInputAction.newline,
                          keyboardType: TextInputType.multiline,
                        ),
                      ),
                    ),
                  ),
                  //const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                                      final slideAnimation = Tween<Offset>(
                                        begin: const Offset(0.0, 0.1), // slide up slightly
                                        end: Offset.zero,
                                      ).animate(animation);

                                      return SlideTransition(
                                        position: slideAnimation,
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },

                      child: _isListening
                          ? (_isTranscribing
                          ? Row(
                        key: const ValueKey('loaderOnly'),
                        children: [
                          Expanded(
                            child: Container(
                              height: 45,
                              alignment: Alignment.center,
                              child: Lottie.asset(
                                'assets/images/mic_loading.json',
                                repeat: true,
                              ),
                            ),
                          ),
                        ],
                      )
                          : Row(
                        key: const ValueKey('micMode'),
                        children: [
                          const SizedBox(width: 3),

                          // ❌ Cancel Button with Border
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFC8C8C8),
                                width: 1,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 17,
                              backgroundColor: Colors.white,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.close,
                                  size: 24,
                                  weight: 2,
                                  color: Color(0xFFAC5F2C),
                                ),
                                onPressed: () async {
                                  try {
                                    _timer?.cancel();
                                    _speechTimer.stop();
                                    await _audioRecorder.stop();
                                    stopNativeVad();
                                    if (mounted) {
                                      setState(() {
                                        _isListening = false;
                                        _isTranscribing = false;
                                      });
                                    }
                                  } catch (e) {
                                    print('❌ Error stopping mic: $e');
                                  }
                                },
                              ),
                            ),
                          ),

                          // 🔊 Waveform
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: ChatGPTScrollingWaveform(
                                key: const ValueKey('waveform'),
                                isSpeech: _isSpeaking,
                                rms: _currentRms,
                              ),
                            ),
                          ),

                          // ✅ Check / Transcribe Button
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 1,
                              ),
                            ),
                            child: GestureDetector(
                              onTap: () async {
                                try {
                                  _timer?.cancel();
                                  _speechTimer.stop();

                                  setState(() => _isTranscribing = true); // 👈 immediately hide all UI

                                  final path = await _audioRecorder.stop();
                                  if (path != null) _recordingPath = path;

                                  final file = File(_recordingPath);
                                  if (file.existsSync()) {
                                    await _transcribeAudio(); // Transcription logic
                                  }

                                  if (mounted) {
                                    setState(() {
                                      _isListening = false;
                                      _isTranscribing = false;
                                    });
                                  }
                                } catch (e) {
                                  print('❌ Error in check flow: $e');
                                  if (mounted) {
                                    setState(() {
                                      _isListening = false;
                                      _isTranscribing = false;
                                    });
                                  }
                                }
                              },
                              child: CircleAvatar(
                                backgroundColor: AppColors.primary,
                                radius: 18,
                                child: Icon(
                                  PhosphorIcons.check(PhosphorIconsStyle.bold),
                                  size: 24,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ))

        :

    Row(
                      key: const ValueKey('normalMode'),
                      children: [
                        // Left-side Add Button
                        // IconButton(
                        //   onPressed: () {
                        //     final overlay = Overlay.of(context);
                        //     final renderBox = context.findRenderObject() as RenderBox;
                        //     final size = renderBox.size;
                        //     final offset = renderBox.localToGlobal(Offset.zero);
                        //
                        //     final entry = OverlayEntry(
                        //       builder: (context) => Positioned(
                        //         top: offset.dy + 600,
                        //         left: offset.dx + (size.width / 2) - 140,
                        //         child: Material(
                        //           color: Colors.transparent,
                        //           child: AnimatedComingSoonTooltip(),
                        //         ),
                        //       ),
                        //     );
                        //
                        //     overlay.insert(entry);
                        //     Future.delayed(const Duration(seconds: 2), () => entry.remove());
                        //   },
                        //   icon: Icon(Icons.add, size: 30,color: theme.icon,),
                        // ),
                        Image.asset("assets/images/attach_2.png",color: theme.icon,height: 22,width: 25,fit: BoxFit.contain,),
                        //const SizedBox(width: 16),

                        Spacer(),

                        // Conditionally render send + mic or only mic
                        Row(
                          //mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                HapticFeedback.heavyImpact();
                                if (await _audioRecorder.hasPermission()) {
                                  setState(() {
                                    _isOverwritingTranscript = _controller.text.isNotEmpty;
                                  });

                                  final dir = await getTemporaryDirectory();
                                  _recordingPath = '${dir.path}/audio.wav';

                                  final recordConfig = RecordConfig(
                                    encoder: AudioEncoder.wav,
                                    bitRate: 128000,
                                    sampleRate: 44100,
                                    numChannels: 1,
                                  );

                                  await _audioRecorder.start(recordConfig, path: _recordingPath);
                                  startNativeVad();
                                  _speechTimer.reset();
                                  _speechTimer.start();

                                  _timer = Timer.periodic(const Duration(seconds: 1), (_) {
                                    if (mounted) {
                                      setState(() {
                                        _formattedDuration = _formatDuration(_speechTimer.elapsed);
                                      });
                                    }
                                  });

                                  setState(() {
                                    _isListening = true;
                                    _formattedDuration = '00:00';
                                  });
                                }
                              },
                              child: Image.asset("assets/images/bold_mic.png", height: 23,color: theme.icon,),
                            ),
                            SizedBox(width: 18,),
                            // if (_isTyping || _controller.text.isNotEmpty || _isTranscribing) ...[
                            //   _buildCircleButton(
                            //     bgColor: const Color(0xFFF66A00),
                            //     onTap: () {
                            //       if (!mounted) return;
                            //       if (_isTyping) {
                            //         _stopResponse();
                            //       } else {
                            //         _sendMessage();
                            //       }
                            //     },
                            //     iconWidget: AnimatedSwitcher(
                            //       duration: const Duration(milliseconds: 300),
                            //       child: Icon(
                            //         _isTyping ? Icons.stop : Icons.arrow_upward,
                            //         key: ValueKey(_isTyping),
                            //         color: Colors.white,
                            //       ),
                            //     ),
                            //   ),
                            //   const SizedBox(width: 12),
                            // ],
                            if (_isTyping || _controller.text.isNotEmpty || _isTranscribing)
                              _buildCircleButton(
                                bgColor: const Color(0xFFF66A00),
                                onTap: () {
                                  if (!mounted) return;
                                  if (_isTyping) {
                                    _stopResponse();
                                  } else {
                                    _sendMessage();
                                  }
                                },
                                iconWidget: Icon(
                                  _isTyping ? Icons.stop : Icons.arrow_upward,
                                  key: ValueKey(_isTyping),
                                  color: Colors.white,
                                ),
                              ),

                            // Mic icon always present at right
                          ],
                        ),
                      ],
                    ),




                  ),
                  SizedBox(
                    height: _keyboardInset > 0 ? 0 : 25,
                  )


                ],
              ),
            ],
          ),
        ),
      ),
    );
  }




  // Widget _buildInputFields() {
  //   final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
  //
  //   // Heartbeat + RMS modulation calculation
  //   double maxRms = 0.1;
  //   double rmsMod = (_displayedRms.clamp(0.0, maxRms)) / maxRms;
  //   if (!_isSpeaking) rmsMod = 0.0;
  //
  //   // Heartbeat curve: value 0-1 → 0-π
  //   double beat = sin(pi * _heartbeatValue);
  //   double heartbeatMod = 0.50 * beat;
  //   double modulation = (rmsMod + heartbeatMod).clamp(0.0, 1.0);
  //
  //   // Container height + glow
  //   double baseHeight = 150;
  //   double beatHeight = 35;
  //   // More aggressive curve: modulation^1.5 for steep growth
  //
  //
  //   double containerHeight = baseHeight + (beatHeight * modulation);
  //
  //   double glowIntensity = modulation;
  //   BoxShadow glow = BoxShadow(
  //     color: Colors.blue.withOpacity(0.18 + 0.20 * glowIntensity),
  //     blurRadius: 32 + 20 * glowIntensity,
  //     spreadRadius: 10 + 7 * glowIntensity,
  //   );
  //   BoxShadow outerGlow = BoxShadow(
  //     color: Colors.blueAccent.withOpacity(0.08 + 0.18 * glowIntensity),
  //     blurRadius: 56 + 24 * glowIntensity,
  //     spreadRadius: 36 + 10 * glowIntensity,
  //   );
  //   double glowOverlayOpacity = 0.14 + 0.20 * glowIntensity;
  //
  //   return Padding(
  //     padding: const EdgeInsets.all(1),
  //     child: Material(
  //       color: theme.box,
  //       elevation: 20.0,
  //       child: Stack(
  //         children: [
  //           AnimatedSwitcher(
  //             duration: const Duration(milliseconds: 400),
  //             switchInCurve: Curves.easeInOutCubic,
  //             switchOutCurve: Curves.easeInOutCubic,
  //             transitionBuilder: (child, animation) {
  //               final slideAnimation = Tween<Offset>(
  //                 begin: const Offset(0.0, 0.1), // slide up slightly
  //                 end: Offset.zero,
  //               ).animate(animation);
  //
  //               return SlideTransition(
  //                 position: slideAnimation,
  //                 child: FadeTransition(
  //                   opacity: animation,
  //                   child: child,
  //                 ),
  //               );
  //             },
  //             child: _isListening
  //                 ? AnimatedBuilder(
  //               animation: _heartbeatController,
  //               builder: (context, child) {
  //                 return Center(
  //                   child: Container(
  //                     height: containerHeight,
  //                     width: double.infinity,
  //                     margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
  //                     decoration: BoxDecoration(
  //                       borderRadius: BorderRadius.circular(2),
  //                       // border: Border.all(
  //                       //   color: Color.lerp(
  //                       //     Colors.white,
  //                       //     Colors.white.withOpacity(0.1),
  //                       //     _displayedRms / maxRms,
  //                       //   )!.withOpacity(0.25 + 0.20 * _scaleAnim.value),
  //                       //   width: _scaleAnim.value * 2.1,
  //                       // ),
  //                     ),
  //                     child: Stack(
  //                       fit: StackFit.expand,
  //                       children: [
  //                         // Mesh BG with blur
  //                     ClipPath(
  //                     clipper: ConvexTopClipper(modulation: modulation),
  //                     child: AnimatedSwitcher(
  //                       duration: const Duration(milliseconds: 600),
  //                       switchInCurve: Curves.easeOut,
  //                       switchOutCurve: Curves.easeIn,
  //                       transitionBuilder: (child, animation) {
  //                         return FadeTransition(
  //                           opacity: animation,
  //                           child: SlideTransition(
  //                             position: Tween<Offset>(
  //                               begin: const Offset(0.0, 0.1),
  //                               end: Offset.zero,
  //                             ).animate(animation),
  //                             child: child,
  //                           ),
  //                         );
  //                       },
  //                       child:
  //                       // _showStaticGradient
  //                       //     ? Container(
  //                       //   key: const ValueKey('static'),
  //                       //   width: double.infinity,
  //                       //   height: double.infinity,
  //                       //   decoration: const BoxDecoration(
  //                       //     gradient: LinearGradient(
  //                       //       begin: Alignment.topLeft,
  //                       //       end: Alignment.bottomRight,
  //                       //       colors: [
  //                       //         Color(0xFF7C5E57),
  //                       //         Color(0xFFC06622),
  //                       //       ],
  //                       //     ),
  //                       //   ),
  //                       // )
  //                       //     :
  //                       Stack(
  //                         key: const ValueKey('mesh'),
  //                         children: [
  //                           // Base mesh
  //                           ImageFiltered(
  //                             imageFilter: ImageFilter.blur(sigmaX: 35.0, sigmaY: 35.0),
  //                             child: CustomPaint(
  //                               size: const Size(510, 120),
  //                               painter: ButteryMeshPainter(
  //                                 positions: _meshPositions.map((a) => a.value).toList(),
  //                                 colors: _meshColors.map((c) => c.value!.withOpacity(0.8)).toList(),
  //                                 showShapes: true,
  //                               ),
  //                             ),
  //                           ),
  //                           // Overlay mesh
  //                           ImageFiltered(
  //                             imageFilter: ImageFilter.blur(sigmaX: 35.0, sigmaY: 35.0),
  //                             child: CustomPaint(
  //                               size: const Size(350, 140),
  //                               painter: ButteryMeshPainter(
  //                                 positions: _meshPositions.map((a) => a.value).toList(),
  //                                 colors: _meshColors.map((a) => a.value!).toList(),
  //                                 showShapes: true,
  //                               ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //
  //                     // Content
  //                         Padding(
  //                           padding: const EdgeInsets.symmetric(vertical: 35),
  //                           child: _buildRecordingUI(),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 );
  //               },
  //             )
  //
  //                 :
  //
  //             // Container(
  //             //   key: const ValueKey('textfield'),
  //             //   width: double.infinity, // <-- fixes size for AnimatedSwitcher
  //             //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  //             //   decoration: BoxDecoration(
  //             //     color: theme.box,
  //             //     boxShadow: [
  //             //       BoxShadow(
  //             //         color: theme.shadow,
  //             //         blurRadius: 7,
  //             //         spreadRadius: 1,
  //             //         offset: const Offset(0, 1),
  //             //       ),
  //             //     ],
  //             //     border: Border.all(color: theme.box),
  //             //     borderRadius: const BorderRadius.only(
  //             //       topLeft: Radius.circular(15),
  //             //       topRight: Radius.circular(15),
  //             //     ),
  //             //   ),
  //             //   child: Column(
  //             //     mainAxisSize: MainAxisSize.min,
  //             //     crossAxisAlignment: CrossAxisAlignment.start,
  //             //     children: [
  //             //       Column(
  //             //         children: [
  //             //           Container(
  //             //             constraints: const BoxConstraints(
  //             //                 minHeight: 40, maxHeight: 140),
  //             //             child: SingleChildScrollView(
  //             //               child: Scrollbar(
  //             //                 child: TextField(
  //             //                   style: TextStyle(
  //             //                     fontFamily: "SF Pro Text",
  //             //                     fontSize: 17.5,
  //             //                     fontWeight: FontWeight.w400,
  //             //                     color: _isOverwritingTranscript
  //             //                         ? Colors.grey.shade400
  //             //                         : theme.text,
  //             //                   ),
  //             //                   autofocus: true,
  //             //                   minLines: 1,
  //             //                   maxLines: null,
  //             //                   controller: _controller,
  //             //                   focusNode: _focusNode,
  //             //                   decoration: InputDecoration(
  //             //                     hintStyle: TextStyle(
  //             //                       fontWeight: FontWeight.w400,
  //             //                       fontFamily: "SF Pro Text",
  //             //                       color: Colors.grey.shade600,
  //             //                       fontSize: 17.5,
  //             //                     ),
  //             //                     hintText: 'Ask anything',
  //             //                     border: InputBorder.none,
  //             //                     contentPadding:
  //             //                     const EdgeInsets.only(left: 10),
  //             //                   ),
  //             //                   onChanged: (_) {
  //             //                     if (mounted) setState(() {});
  //             //                   },
  //             //                   onSubmitted: (_) {
  //             //                     if (mounted) _sendMessage();
  //             //                   },
  //             //                   textInputAction: TextInputAction.newline,
  //             //                   keyboardType: TextInputType.multiline,
  //             //                 ),
  //             //               ),
  //             //             ),
  //             //           ),
  //             //           RecordingUI(theme),
  //             //           SizedBox(height: _keyboardInset > 0 ? 0 : 20),
  //             //         ],
  //             //       ),
  //             //     ],
  //             //   ),
  //             // ),
  //
  //             Container(
  //               key: const ValueKey('textfield'),
  //               width: double.infinity,
  //               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  //               decoration: BoxDecoration(
  //                 color: theme.box,
  //                 boxShadow: [
  //                   BoxShadow(
  //                     color: theme.shadow,
  //                     blurRadius: 7,
  //                     spreadRadius: 1,
  //                     offset: const Offset(0, 1),
  //                   ),
  //                 ],
  //                 border: Border.all(color: theme.box),
  //                 borderRadius: const BorderRadius.only(
  //                   topLeft: Radius.circular(15),
  //                   topRight: Radius.circular(15),
  //                 ),
  //               ),
  //               child: Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   // Remove ConstrainedBox and use Flexible instead
  //                   Flexible(
  //                     child: TextField(
  //                       controller: _controller,
  //                       focusNode: _focusNode,
  //                       keyboardType: TextInputType.multiline,
  //                       textInputAction: TextInputAction.newline,
  //                       minLines: 1,
  //                       maxLines: null, // Allow unlimited lines
  //                       expands: false,
  //                       style: TextStyle(
  //                         fontFamily: "SF Pro Text",
  //                         fontSize: 17.5,
  //                         fontWeight: FontWeight.w400,
  //                         color: _isOverwritingTranscript
  //                             ? Colors.grey.shade400
  //                             : theme.text,
  //                       ),
  //                       decoration: InputDecoration(
  //                         hintText: 'Ask anything',
  //                         hintStyle: TextStyle(
  //                           fontWeight: FontWeight.w400,
  //                           fontFamily: "SF Pro Text",
  //                           color: Colors.grey.shade600,
  //                           fontSize: 17.5,
  //                         ),
  //                         border: InputBorder.none,
  //                         contentPadding: const EdgeInsets.only(left: 10, bottom: 12),
  //                       ),
  //                       onChanged: (_) {
  //                         if (mounted) setState(() {});
  //                       },
  //                       onSubmitted: (_) {
  //                         if (mounted) _sendMessage();
  //                       },
  //                     ),
  //                   ),
  //                   RecordingUI(theme),
  //                   SizedBox(height: _keyboardInset > 0 ? 0 : 20),
  //                 ],
  //               ),
  //             )
  //
  //
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }


  Row TextFieldUI(AppTheme theme) {
    return Row(
      key: const ValueKey('micMode'),
      children: [
        const SizedBox(width: 3),
        CircleAvatar(
          radius: 17,
          backgroundColor: Colors.grey.shade200,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon:  Icon(Icons.close,size: 30,weight: 2,color: theme.icon,),
            onPressed: () async{
              try {
                _timer.cancel();
                _speechTimer.stop();

                // ✅ Hard stop audio recording
                await _audioRecorder.stop();

                // ✅ Stop mic monitoring if required
                //_stopMicMonitoring(); // make this async if needed
                await stopNativeVad();
                if (mounted) {
                  setState(() {
                    _isListening = false;
                    _isTranscribing = false;
                  });
                }
              } catch (e) {
                print('❌ Error stopping mic: $e');
              }
            },
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: BlackSlidingWaveform(
              isSpeaking: _isSpeaking,
              isActive: _isSpeaking,
              rms: _currentRms,
              key: const ValueKey('waveform'),
              //durationText: _formattedDuration,
              //isSpeaking: _isSpeaking,
            ),
          ),
        ),
        Text(
          _formattedDuration,
          style:  TextStyle(fontSize: 13,
              fontWeight: FontWeight.w500,color: theme.text),
        ),
        const SizedBox(width: 8),
        _isTranscribing
            ?  CircleAvatar(
          maxRadius: 17,
          backgroundColor: theme.icon,
          child: CupertinoActivityIndicator(color: Colors.white),
        )
            : GestureDetector(
          onTap: () async {
          },
          child:  CircleAvatar(
            backgroundColor: Colors.black,
            radius: 17,
            child: GestureDetector(
              // padding: EdgeInsets.zero,
              onTap: ()async{
                try {
                  _timer.cancel();
                  _speechTimer.stop();

                  // ✅ Stop monitoring
                  //_stopMicMonitoring();
                  await stopNativeVad();
                  setState(() => _isTranscribing = true);

                  // ✅ Stop and save audio
                  final path = await _audioRecorder.stop();
                  if (path != null) _recordingPath = path;

                  final file = File(_recordingPath);
                  if (file.existsSync()) {
                    await _transcribeAudio();
                  } else {
                    if (mounted) {
                      setState(() {
                        _isListening = false;
                        _isTranscribing = false;
                      });
                    }
                  }
                } catch (e) {
                  print('❌ Error in check flow: $e');
                  if (mounted) {
                    setState(() {
                      _isListening = false;
                      _isTranscribing = false;
                    });
                  }
                }
              },
              child: Icon(PhosphorIcons.check(
                  PhosphorIconsStyle.bold
              ), size: 24, color: Colors.white)
              ,

            ),
          ),
        )
      ],
    );
  }


  Widget _buildRecordingUI() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          // Cancel Button - Centered
          _isTranscribing? SizedBox.shrink():  Container(
            width: 40,
            height: 40,
            decoration:  BoxDecoration(
              // border: Border.all(
              //     color: Colors.white
              // ),
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.3),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Center(
                child:
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: 0.785398,
                      child: Container(
                        width: 25,
                        height: 4, // Thickness control
                        color: Colors.white,
                      ),
                    ),
                    Transform.rotate(
                      angle: -0.785398,
                      child: Container(
                        width: 25,
                        height: 4, // Thickness control
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              ),
              onPressed: () async {
                try {
                  _timer.cancel();
                  _speechTimer.stop();
                  await _audioRecorder.stop();
                  await stopNativeVad();
                  if (mounted) {
                    setState(() {
                      _isListening = false;
                      _isTranscribing = false;
                    });
                  }
                } catch (e) {
                  print('❌ Error stopping mic: $e');
                }
              },
            ),
          ),

          const SizedBox(width: 12),

          // ✅ Recording pill with timer + waveform
          _isTranscribing == true ? Expanded(
            child: Container(
              // margin: const EdgeInsets.only(top: 6, bottom: 2),
              height: 65,
              width: 65,
              child: Lottie.asset(
                'assets/images/mic_loading.json',
                repeat: true,
                //  fit: BoxFit.cover,
              ),
            ),
          ):
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ⏱️ Timer
                  Flexible(
                    flex: 0,
                    child: Text(
                      _formattedDuration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                 // const SizedBox(width: 12),

                  // 📊 Waveform inside the container
                  Expanded(
                    flex: 11,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(240),  // 👈 curvy right side
                        bottomRight: Radius.circular(240),
                      ),
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              Colors.white,
                              Colors.white,
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.05, 1.0, 1.0],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: ChatGPTScrollingWaveform(
                          isSpeech: _isSpeaking,
                          rms: _currentRms,
                          key: const ValueKey('waveform'),
                        ),
                      ),
                    ),
                  )

                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ✅ Checkmark / Spinner Button
          // _isTranscribing
          //     ?  Container(
          //   // maxRadius: 19,
          //   // backgroundColor: Colors.black26,
          //   decoration:  BoxDecoration(
          //     border: Border.all(
          //         color: Colors.white
          //     ),
          //     shape: BoxShape.circle,
          //     color: Colors.white.withOpacity(0.3),
          //   ),
          //   width: 40,
          //   height: 40,
          //   child: CupertinoActivityIndicator(color: Colors.white),
          // )
          //     :
          _isTranscribing ? SizedBox.shrink() :  GestureDetector(
              onTap: () async {
                try {
                  _timer.cancel();
                  _speechTimer.stop();
                  await stopNativeVad();
                  setState(() => _isTranscribing = true);

                  final path = await _audioRecorder.stop();
                  if (path != null) _recordingPath = path;

                  final file = File(_recordingPath);
                  if (file.existsSync()) {
                    await _transcribeAudio();
                  } else {
                    if (mounted) {
                      setState(() {
                        _isListening = false;
                        _isTranscribing = false;
                      });
                    }
                  }
                } catch (e) {
                  print('❌ Error in check flow: $e');
                  if (mounted) {
                    setState(() {
                      _isListening = false;
                      _isTranscribing = false;
                    });
                  }
                }
              },
              child: Container(
                width: 40,
                height: 40,
                // backgroundColor: Colors.white.withOpacity(0.3),
                // radius: 19,
                decoration:  BoxDecoration(
                  border: Border.all(
                      color: Colors.white
                  ),
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Center(
                  child:
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Multiple positioned icons for thickness effect
                      Icon(Icons.check, size: 24, color: AppColors.primary),

                      // Slight offsets for thickness
                      Positioned(
                        left: 0.5,
                        child: Icon(Icons.check, size: 24, color: AppColors.primary),
                      ),
                      Positioned(
                        left: -0.5,
                        child: Icon(Icons.check, size: 24, color: AppColors.primary),
                      ),
                      Positioned(
                        top: 0.5,
                        child: Icon(Icons.check, size: 24, color: AppColors.primary),
                      ),
                      Positioned(
                        top: -0.5,
                        child: Icon(Icons.check, size: 24, color: AppColors.primary),
                      ),

                      // Diagonal offsets for extra thickness
                      Positioned(
                        left: 0.5,
                        top: 0.5,
                        child: Icon(Icons.check, size: 24, color: AppColors.primary),
                      ),
                      Positioned(
                        left: -0.5,
                        top: -0.5,
                        child: Icon(Icons.check, size: 24, color: AppColors.primary),
                      ),
                      Positioned(
                        left: 0.5,
                        top: -0.5,
                        child: Icon(Icons.check, size: 24, color: AppColors.primary),
                      ),
                      Positioned(
                        left: -0.5,
                        top: 0.5,
                        child: Icon(Icons.check, size: 24, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              )
          ),
        ],
      ),
    );
  }



  Row RecordingUI(AppTheme theme) {
    return Row(
      key: const ValueKey('normalMode'),
      children: [
        // Left-side Add Button
        IconButton(
          onPressed: () {
            final overlay = Overlay.of(context);
            final renderBox = context.findRenderObject() as RenderBox;
            final size = renderBox.size;
            final offset = renderBox.localToGlobal(Offset.zero);

            final entry = OverlayEntry(
              builder: (context) => Positioned(
                top: offset.dy + 600,
                left: offset.dx + (size.width / 2) - 140,
                child: Material(
                  color: Colors.transparent,
                  child: AnimatedComingSoonTooltip(),
                ),
              ),
            );

            overlay.insert(entry);
            Future.delayed(const Duration(seconds: 2), () => entry.remove());
          },
          icon: Icon(Icons.add, size: 30),
        ),

        const SizedBox(width: 16),

        Spacer(),

        // Conditionally render send + mic or only mic
        Row(
          //mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(1, _micButtonOffset),
              child: GestureDetector(
                onTap: () async {
                  HapticFeedback.heavyImpact();
                  if (await _audioRecorder.hasPermission()) {
                    setState(() {
                      _isOverwritingTranscript = _controller.text.isNotEmpty;
                    });

                    final dir = await getTemporaryDirectory();
                    _recordingPath = '${dir.path}/audio.wav';

                    final recordConfig = RecordConfig(
                      encoder: AudioEncoder.wav,
                      bitRate: 128000,
                      sampleRate: 44100,
                      numChannels: 1,
                    );

                    await _audioRecorder.start(recordConfig, path: _recordingPath);
                    //_startMicMonitoring();
                    _speechTimer.reset();
                    _speechTimer.start();
                    await startNativeVad();

                    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
                      if (mounted) {
                        setState(() {
                          _formattedDuration = _formatDuration(_speechTimer.elapsed);
                        });
                      }
                    });

                    setState(() {
                      _isListening = true;
                      _formattedDuration = '00:00';
                    });
                  }
                },
                child: Image.asset("assets/images/mic_2.png", height: 40,color: theme.icon,),
              ),
            ),
            SizedBox(width: 10,),
            if (_isTyping || _controller.text.isNotEmpty || _isTranscribing)
              _buildCircleButton(
                bgColor: const Color(0xFFF66A00),
                onTap: () {
                  if (!mounted) return;
                  if (_isTyping) {
                    _stopResponse();
                  } else {
                    _sendMessage();
                  }
                },
                iconWidget: Icon(
                  _isTyping ? Icons.stop : Icons.arrow_upward,
                  key: ValueKey(_isTyping),
                  color: Colors.white,
                ),
              ),

            // Mic icon always present at right
          ],
        ),
      ],
    );
  }

  startRecording()async{
    HapticFeedback.heavyImpact();
    if (await _audioRecorder.hasPermission()) {
      setState(() {
        _isRecording = true;
        _isOverwritingTranscript = _controller.text.isNotEmpty;
      });

      _slideAnimationController.forward();
      final dir = await getTemporaryDirectory();
      _recordingPath = '${dir.path}/audio.wav';

      final recordConfig = RecordConfig(
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      );

      await _audioRecorder.start(recordConfig, path: _recordingPath);
      //_startMicMonitoring();
      _speechTimer.reset();
      _speechTimer.start();
      await startNativeVad();

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _formattedDuration = _formatDuration(_speechTimer.elapsed);
          });
        }
      });

      setState(() {
        _isListening = true;
        _formattedDuration = '00:00';
      });
    }
  }


  Widget _buildCircleButton({
    IconData? icon,
    Widget? iconWidget,
    VoidCallback? onTap,
    bool isLoading = false,
    Color bgColor = Colors.transparent,
  }) {
    final bool isFilled = bgColor != Colors.transparent;
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 1.0, end: isLoading ? 0.95 : 1.0),
      builder: (context, scale, child) {
        return GestureDetector(
          onTapDown: (_) {
            HapticFeedback.lightImpact();
          },
          onTap: isLoading ? null : onTap,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 120),
            scale: 1.0,
            child: Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
                border: Border.all(
                  color: isFilled ? Colors.transparent : Colors.grey.shade400,
                  width: 1.2,
                ),
              ),
              child: isLoading
                  ? const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              )
                  : Center(
                child: iconWidget ??
                    Icon(
                      icon,
                      size: 18,
                      color: isFilled ? theme.background : theme.icon,
                    ),
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildStyledBotMessage({
    required String fullText,
    required bool isComplete,
    required bool isLatest,
  }) {
    final theme = locator<ThemeService>().currentTheme;

    final style = TextStyle(
      // fontSize: 17, // ✅ matches ChatGPT iOS
      // fontFamily: 'SF Pro Text',
      // fontWeight: FontWeight.w400,
      // height: 1.9, // ✅ better line height for dense layout
      // color: theme.text,
      fontFamily: 'DM Sans',
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.75,
      color: theme.text,
    );

    List<TextSpan> processTextWithFormatting(String text) {
      final regexBold = RegExp(r"\*\*(.+?)\*\*");
      List<TextSpan> spans = [];

      int lastMatchEnd = 0;

      for (var match in regexBold.allMatches(text)) {
        if (match.start > lastMatchEnd) {
          spans.add(TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: style,
          ));
        }

        spans.add(TextSpan(
          text: match.group(1),
          style: style.copyWith(fontWeight: FontWeight.w700,height: 1.5,color: theme.text,fontFamily: "SF Pro Text"),
        ));

        lastMatchEnd = match.end;
      }

      if (lastMatchEnd < text.length) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd),
          style: style,
        ));
      }

      return spans;
    }

    final lines = fullText.trim().split('\n');
    List<TextSpan> spans = [];

    for (var line in lines) {
      if (line.trim().isEmpty) {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      String emoji = '';
      if (line.trim().startsWith(RegExp(r"^(\*|•|-|\\d+\\.)\\s"))){
        emoji = '👉 ';
      } else if (line.contains('Tip') || line.contains('Note')) {
        emoji = '💡 ';
      } else if (line.contains('Save') || line.contains('budget')) {
        emoji = '💰 ';
      }

      spans.add(TextSpan(text: '\n$emoji'));
      spans.addAll(processTextWithFormatting(line));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 2), // 🔻 reduce outer spacing
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(style: style, children: spans),
          ),
          const SizedBox(height: 15), // 🔻 smaller than 15
          Row(
            children: [
              Visibility(
                visible: true,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 300),
                  opacity: isComplete ? 1 : 0,
                  child: const Icon(Icons.copy, size: 14, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              Visibility(
                visible: true,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Opacity(
                  opacity: isComplete ? 1 : 0,
                  child: const Icon(Icons.thumb_up_alt_outlined, size: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              Visibility(
                visible: true,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Opacity(
                  opacity: isComplete ? 1 : 0,
                  child: const Icon(Icons.thumb_down_alt_outlined, size: 16, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // final displayMessages = _showOnlyLatestDuringTyping && messages.length > 2
    //     ? messages.sublist(messages.length - 4)
    //     : _visibleMessages;
    final displayMessages = _showOnlyLatestDuringTyping && messages.length > 2
        ? messages.sublist(messages.length - 2) // Only show the latest exchange
        : _visibleMessages;
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: theme.background,
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _chatHeight = constraints.maxHeight;
                      return ListView.builder(
                        controller: _scrollController,
                        reverse: false,
                        padding: const EdgeInsets.all(20),
                        itemCount: displayMessages.length + 1,
                        itemBuilder: (context, index) {
                          // if(displayMessages.isEmpty){
                          // print("OFFSET");
                          //   print(_scrollController.offset);
                          //  print(_scrollController.position.maxScrollExtent);
                          //  print(_scrollController.position.minScrollExtent);
                          // }
                          // if (index == displayMessages.length) {
                          //  // print("Got here");
                          //   return SizedBox(height: _chatHeight - 101);
                          // }
                           // print(_latestUserMessageHeight);
                            print(_chatHeight - _latestUserMessageHeight + 16);
                          if (index == displayMessages.length) {
                           return SizedBox(height: _chatHeight - _latestUserMessageHeight);
                          }
                          // if (index == displayMessages.length) {
                          //   return SizedBox(
                          //     height: _chatHeight - (_latestUserMessageHeight > 100 ? 100 : _latestUserMessageHeight) - 16,
                          //
                          //   );

                          final msg = displayMessages[index];
                          return _buildMessageRow(msg);
                        },
                      );
                    },
                  ),
                ),
             _isListening? SizedBox.shrink():   // SIMPLE & PREMIUM - Clean, Fast, Elegant
             AnimatedSwitcher(
               duration: const Duration(milliseconds: 350),
               switchInCurve: Curves.easeOutCubic,
               switchOutCurve: Curves.easeInCubic,
               transitionBuilder: (Widget child, Animation<double> animation) {
                 return FadeTransition(
                   opacity: animation,
                   child: SlideTransition(
                     position: Tween<Offset>(
                       begin: const Offset(0.0, 0.15), // Subtle upward slide
                       end: Offset.zero,
                     ).animate(animation),
                     child: child,
                   ),
                 );
               },
               child: (_hasLoadedMessages &&
                   !messages.any((m) => m['role'] == 'user') &&
                   _controller.text.isEmpty)
                   ? SizedBox(
                 key: const ValueKey('quickChips'),
                 height: 94,
                 child: ListView(
                   scrollDirection: Axis.horizontal,
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                   children: [
                     SizedBox(
                       height: 100,
                       child: _quickChip(
                         onpressed: () {
                           final text = "What's happening in the market today?";
                           setState(() {
                             _controller.text = text;
                             _controller.selection = TextSelection.fromPosition(
                               TextPosition(offset: text.length),
                             );
                           });
                         },
                         title: "Market News",
                         subtitle: "What's happening in the market today?",
                         maxWidth: 220,
                       ),
                     ),
                     const SizedBox(width: 16),
                     _quickChip(
                       onpressed: () {
                         final text = "How's my portfolio doing?";
                         setState(() {
                           _controller.text = text;
                           _controller.selection = TextSelection.fromPosition(
                             TextPosition(offset: text.length),
                           );
                         });
                       },
                       title: "My Portfolio",
                       subtitle: "How's my portfolio doing?",
                       maxWidth: 220,
                     ),
                     const SizedBox(width: 12),
                     AddShortcutCard(),
                   ],
                 ),
               )
                   : const SizedBox.shrink(key: ValueKey('emptyQuickChips')),
             ),
               const SizedBox(height: 5),
                _buildInputFields(),
              ],
            ),

            // 🔽 Scroll to bottom FAB
            if (_showScrollToBottomButton)
              Positioned(
                bottom: 150,
                left: MediaQuery.of(context).size.width / 2 - 26,
                child: GestureDetector(
                  onTap: () {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  child: Container(
                    height: 35,
                    width: 35,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                      border: Border.all(
                        color:  Colors.grey.shade400,
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(Icons.arrow_downward_rounded, size: 26),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }



}







class StaticGradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF7C5E57),
          Color(0xFFC06622),
        ],
      ).createShader(rect);

    final path = Path()
      ..moveTo(0, 20)
      ..quadraticBezierTo(size.width / 2, 0, size.width, 20)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
















