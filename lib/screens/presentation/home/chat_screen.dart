import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show Float64List, kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:http_parser/http_parser.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:waveform_flutter/waveform_flutter.dart' as wf;

// Import your existing chat service files
import '../../../constants/colors.dart';
import '../../../models/chat_message.dart';
import '../../../models/chat_session.dart';
import '../../../models/stock_detail.dart';
import '../../../services/auth_service.dart';
import '../../../services/chat_service.dart';
import '../../../services/locator.dart';
import '../../../services/speech_service.dart';
import '../../../services/theme_service.dart';
import '../../models/document_context.dart';
import '../../stock_detail_screen.dart';
import '../../utils/file_helps.dart';
import 'package:http/http.dart' as http;


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

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver{
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
 // late final SpeechService _speechService;
   ScrollController _scrollController = ScrollController();
  final _audioRecorder = AudioRecorder();
 // final _audioPlayer = just_audio.AudioPlayer();
  String _recordingPath = '';
  bool _isTranscribing = false;
  Timer? _levelTimer;
  final FlutterAudioCapture _audioCapture = FlutterAudioCapture();
  Timer? _transcriptionAnimator;
  String _pendingTranscriptionText = '';

  bool _isSpeaking = false;
  bool _showExpandedInput = false;
  bool _isTyping = false;
  bool _isListening = false;
  bool _isProcessingDocument = false;
  bool get _isKeyboardVisible => MediaQuery.of(context).viewInsets.bottom > 0;
  bool _showListeningBar = false;
  String _lastSpeechResult = '';
  bool _showSpeechBar = false;
  String _recognizedSpeech = '';
  Stopwatch _speechTimer = Stopwatch();
  late Timer _timer;
  String _formattedDuration = '00:00';
  double _chatHeight = 0;
  bool _showBottomSpacer = true;
  String _recognizedBackupText = '';
  bool _isOverwritingTranscript = false;
  double _keyboardInset = 0;


  void _animateTranscriptionToInput(String finalText) {
    _transcriptionAnimator?.cancel();
    _pendingTranscriptionText = '';

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
      final targetOffset = (offset + _chatHeight).clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }


  // Flag to show only latest exchange during typing
  bool _showOnlyLatestDuringTyping = false;

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds % 60)}";
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
    _loadSessionMessages();
    print("session id");
    print(widget.session.id);
    _scrollController = ScrollController(keepScrollOffset: true);
    WidgetsBinding.instance.addObserver(this);
    _scrollToBottom();
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
          if (message.question == null && message.answer != null) {
            messages.add({
              'role': 'bot',
              'msg': message.answer,
              'isSystemOnly': true, // Optional for custom style
            });
          }

          // Normal user + bot messages
          if (message.question != null) {
            messages.add({
              'role': 'user',
              'msg': message.question,
            });

            if (message.answer != null) {
              messages.add({
                'role': 'bot',
                'msg': message.answer,
              });
            }
          }
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
    _transcriptionAnimator?.cancel();
    _streamSubscription?.cancel();
    _levelTimer?.cancel();
    _audioRecorder.dispose();
    //_audioPlayer.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    //_speechService.stopListening();
    super.dispose();
  }


  bool _userScrolledUp = false;


  void _sendMessage() async {
    if (!mounted || _controller.text.trim().isEmpty) return;

    FocusScope.of(context).unfocus();
    final userMessage = sanitizeMessage(_controller.text.trim());
    final isFirstMessage = messages.where((m) => m['role'] == 'user').isEmpty;

    final userMessageId = UniqueKey().toString();
    final botMessageId = UniqueKey().toString();

    setState(() {
      _isTyping = true;
      _showBottomSpacer = !_userScrolledUp;


      messages.add({
        'id': userMessageId,
        'role': 'user',
        'msg': userMessage,
        'isComplete': true,
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
    });

    _scrollToLatestLikeChatPage();

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

          if (_currentStreamingId.isEmpty && message.id != null) {
            _currentStreamingId = message.id!;
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
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _showScrollToBottomButton = false;

  final GlobalKey _lastUserMessageKey = GlobalKey();
  final theme = locator<ThemeService>().currentTheme;


  Widget _buildMessageRow(Map<String, Object> msg) {
    if (msg['role'] == 'user') {
      return Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 2), // 🔻 tighter vertical gap
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
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 2), // 🔻 reduce bottom gap
                  decoration: BoxDecoration(
                    color: theme.message,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    msg['msg'].toString(),
                    style: TextStyle(
                      fontSize: 18, // 👈 slightly smaller for ChatGPT-like feel
                      fontFamily: 'SF Pro Text',
                      fontWeight: FontWeight.w500,
                      color: theme.text,
                      height: 1.9,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (msg['type'] == 'stocks' && msg['stocks'] is List) {
      final List<dynamic> stocks = msg['stocks'] as List<dynamic>;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4), // 🔻 reduced for stock tiles too
        child: _buildStockTileList(stocks),
      );
    }

    // Default bot message
    final msgStr = msg['msg']?.toString() ?? '';
    final isComplete = msg['isComplete'] == true;
    final isLatest = msg == messages.last;

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStyledBotMessage(
            fullText: msgStr,
            isComplete: isComplete,
            isLatest: isLatest,
          ),
        ],
      ),
    );

  }





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


  @override
  Widget build(BuildContext context) {
    final displayMessages = _showOnlyLatestDuringTyping && messages.length > 2
        ? messages.sublist(messages.length - 4)
        : _visibleMessages;

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
                      print("Bro chat height");
                      print(_chatHeight);
                      print("Bro  height");
                      print(MediaQuery.of(context).size.height);
                      return ListView.builder(
                        physics: _showOnlyLatestDuringTyping
                            ? const NeverScrollableScrollPhysics()
                            : const BouncingScrollPhysics(),
                        controller: _scrollController,
                        reverse: false,
                        padding: const EdgeInsets.all(16),
                        itemCount: displayMessages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == displayMessages.length) {
                            return SizedBox(height: _chatHeight - 100);
                          }
                          final msg = displayMessages[index];
                          return _buildMessageRow(msg);
                        },
                      );
                    },
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    final offsetAnimation = Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
                    return SlideTransition(position: offsetAnimation, child: child);
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
                              _callFollowUpApi();
                              final text = "What’s happening in the market today?";
                              setState(() {
                                _controller.text = text;
                                _controller.selection = TextSelection.fromPosition(
                                  TextPosition(offset: text.length),
                                );
                              });
                            },
                            title: "Market News",
                            subtitle: "What’s happening in the market today?",
                            maxWidth: 220,
                          ),
                        ),
                        const SizedBox(width: 16),
                        _quickChip(
                          onpressed: () {
                            _callFollowUpApi();
                            final text = "How’s my portfolio doing?";
                            setState(() {
                              _controller.text = text;
                              _controller.selection = TextSelection.fromPosition(
                                TextPosition(offset: text.length),
                              );
                            });
                          },
                          title: "My Portfolio",
                          subtitle: "How’s my portfolio doing?",
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



  void _callFollowUpApi() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    final res = await http.post(
      Uri.parse("https://fastapi-chatbot-717280964807.asia-south1.run.app/api/v1/follow_up"),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print("📩 Response: ${res.body}");
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





  Timer? _silenceTimer;
  bool _currentlySpeaking = false;
  List<bool> _recentVolumes = []; // 🆕 Add globally (top of your widget class)
  final int _volumeWindowSize = 5; // Memory of last 5 samples
  final int requiredLoudChunks = 3; // At least 3 loud samples needed to "start speaking"
  final int requiredSilentChunks = 3; // At least 3 silent samples needed to "stop speaking"
  final double minVolumeThreshold = 0.04; // Very small noises ignore completely
  final double speakingThreshold = 0.04;

  Widget _quickChip({
    required String title,
    required String subtitle,
    required double maxWidth,
    required VoidCallback onpressed,
  }) {
    return GestureDetector(
      onTap: onpressed,
      child: Container(
        height: 200,
        //constraints: BoxConstraints(maxWidth: maxWidth),
        padding:  EdgeInsets.symmetric(horizontal: 15,vertical: 7),
        decoration: BoxDecoration(
          color: theme.message,
          borderRadius: BorderRadius.circular(13),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withOpacity(0.08),
          //     blurRadius: 10,
          //     offset: const Offset(0, 3),
          //   ),
          // ],
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
            style: TextStyle(fontSize: 14, color: theme.text,fontFamily: "DM Sans",fontWeight: FontWeight.w500),
          ),
        ],
      ),

    ),
    );
  }



  void _startMicMonitoring() async {
    await _audioCapture.init();
    await _audioCapture.start(listener, onError, sampleRate: 44100);

    // ✅ Reset speaking state when mic starts fresh
    _currentlySpeaking = false;
    if (mounted) {
      setState(() {
        _isSpeaking = false;
      });
    }
  }


  void listener(dynamic obj) {
    if (obj is! List<double>) return;

    // Calculate average amplitude, NOT max
    final avgVolume = obj.map((e) => e.abs()).reduce((a, b) => a + b) / obj.length;

    const double noiseFloor = 0.02; // Background noise ignore
    const double speakingFloor = 0.04; // Proper speaking detection

    if (avgVolume > speakingFloor) {
      // Clearly speaking
      _silenceTimer?.cancel();
      _silenceTimer = null;
      if (!_currentlySpeaking) {
        if (mounted) {
          setState(() {
            _isSpeaking = true;
          });
        }
        _currentlySpeaking = true;
      }
    } else if (avgVolume < noiseFloor) {
      // Definitely silent
      if (_currentlySpeaking) {
        _silenceTimer ??= Timer(const Duration(milliseconds: 400), () {
          if (mounted) {
            setState(() {
              _isSpeaking = false;
            });
          }
          _currentlySpeaking = false;
          _silenceTimer = null;
        });
      }
    }
  }




  void _stopMicMonitoring() async {
    try {
      await _audioCapture.stop();
    } catch (_) {
      // Ignore errors when stopping
    }
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _isSpeaking = false;
    _currentlySpeaking = false;
  }


  void onError(Object e) {
    print("Mic monitoring error: $e");
  }



  Widget _buildInputFields() {
    return Padding(
      padding: const EdgeInsets.all(1),
      child: Material(
        color: theme.box,
        elevation: 20.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: theme.box,
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
                  Container(
                    constraints: const BoxConstraints(minHeight: 40, maxHeight: 140),
                    child: SingleChildScrollView(
                      child: Scrollbar(
                        child: TextField(
                          style: TextStyle(
                            fontFamily: "SF Pro Text",
                            fontSize: 18,
                            color: _isOverwritingTranscript ? Colors.grey.shade400 : theme.text,
                          ),
                          autofocus: true,
                          minLines: 1,
                          maxLines: null,
                          controller: _controller,
                          focusNode: _focusNode,
                          decoration:  InputDecoration(
                            hintStyle: TextStyle(fontFamily: "SF Pro Text",color: Colors.grey.shade600,fontSize: 18),
                            hintText: 'Ask anything',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(left: 10),
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
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      );
                    },
                    child: _isListening
                        ? Row(
                      key: const ValueKey('micMode'),
                      children: [
                        const SizedBox(width: 0),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey.shade200,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _timer?.cancel();
                              _speechTimer.stop();
                              _stopMicMonitoring();
                              setState(() {
                                _isListening = false;
                                _isTranscribing = false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: ChatGPTScrollingWaveform(
                              key: const ValueKey('waveform'),
                              durationText: _formattedDuration,
                              isSpeaking: _isSpeaking,
                            ),
                          ),
                        ),
                        Text(
                          _formattedDuration,
                          style: const TextStyle(fontWeight: FontWeight.w500),
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
                            _timer?.cancel();
                            _speechTimer.stop();
                            _stopMicMonitoring();
                            setState(() => _isTranscribing = true);

                            final path = await _audioRecorder.stop();
                            if (path != null) _recordingPath = path;

                            final file = File(_recordingPath);
                            if (file.existsSync()) {
                              await _transcribeAudio();
                            } else {
                              setState(() {
                                _isListening = false;
                                _isTranscribing = false;
                              });
                            }
                          },
                          child: const CircleAvatar(
                            backgroundColor: Colors.black,
                            radius: 16,
                            child: Icon(Icons.check, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    )
                        :
                    Row(
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
                                      _startMicMonitoring();
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
                              child: Image.asset("assets/images/mic_2.png", height: 40,color: theme.icon,),
                            ),
                           SizedBox(width: 10,),
                            if (_isTyping || _controller.text.isNotEmpty || _isTranscribing) ...[
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
                                iconWidget: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    _isTyping ? Icons.stop : Icons.arrow_upward,
                                    key: ValueKey(_isTyping),
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],

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
  //   return Padding(
  //     padding: const EdgeInsets.all(1),
  //     child: Material(
  //       elevation: 20.0,
  //       // shadowColor: Colors.bl,
  //       child: Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           boxShadow: [
  //             BoxShadow(
  //               color: Colors.black.withOpacity(0.2),
  //               blurRadius: 7,
  //               spreadRadius: 1,
  //               offset: const Offset(0, 1),
  //             ),
  //           ],
  //           border: Border.all(color: Colors.grey.shade300),
  //           borderRadius: const BorderRadius.only(
  //             topLeft: Radius.circular(15),
  //             topRight: Radius.circular(15),
  //           ),
  //         ),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Column(
  //               children: [
  //                 Container(
  //                   constraints: const BoxConstraints(minHeight: 40, maxHeight: 140),
  //                   child: SingleChildScrollView(
  //                     child: Scrollbar(
  //                       child: TextField(
  //                         style: TextStyle(
  //                           fontFamily: "DM Sans",
  //                           color: _isOverwritingTranscript ? Colors.grey.shade400 : Colors.black,
  //                         ),
  //                         autofocus: true,
  //                         minLines: 1,
  //                         maxLines: null,
  //                         controller: _controller,
  //                         focusNode: _focusNode,
  //                         decoration: const InputDecoration(
  //                           hintStyle: TextStyle(fontFamily: "DM Sans"),
  //                           hintText: 'Ask anything...',
  //                           border: InputBorder.none,
  //                           contentPadding: EdgeInsets.zero,
  //                         ),
  //                         onChanged: (_) {
  //                           if (mounted) setState(() {});
  //                         },
  //                         onSubmitted: (_) {
  //                           if (mounted) _sendMessage();
  //                         },
  //                         textInputAction: TextInputAction.newline,
  //                         keyboardType: TextInputType.multiline,
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 Row(
  //                   children: [
  //                     if (!_isListening) ...[
  //                       _buildCircleButton(
  //                         icon: Icons.add,
  //                         onTap: () {
  //                           final overlay = Overlay.of(context);
  //                           final renderBox = context.findRenderObject() as RenderBox;
  //                           final size = renderBox.size;
  //                           final offset = renderBox.localToGlobal(Offset.zero);
  //
  //                           final entry = OverlayEntry(
  //                             builder: (context) => Positioned(
  //                               top: offset.dy + 600,
  //                               left: offset.dx + (size.width / 2) - 140,
  //                               child: Material(
  //                                 color: Colors.transparent,
  //                                 child: AnimatedComingSoonTooltip(),
  //                               ),
  //                             ),
  //                           );
  //
  //                           overlay.insert(entry);
  //                           Future.delayed(const Duration(seconds: 2), () => entry.remove());
  //                         },
  //                       ),
  //                       const SizedBox(width: 12),
  //                       const Spacer(),
  //                       _buildCircleButton(
  //                         icon: Icons.mic,
  //                         onTap: () async {
  //                           HapticFeedback.heavyImpact();
  //                           if (await _audioRecorder.hasPermission()) {
  //                             setState(() {
  //                               _isOverwritingTranscript = _controller.text.isNotEmpty;
  //                             });
  //                             final dir = await getTemporaryDirectory();
  //                             _recordingPath = '${dir.path}/audio.wav';
  //
  //                             final recordConfig = RecordConfig(
  //                               encoder: AudioEncoder.wav,
  //                               bitRate: 128000,
  //                               sampleRate: 44100,
  //                               numChannels: 1,
  //                             );
  //
  //                             await _audioRecorder.start(recordConfig, path: _recordingPath);
  //                             _startMicMonitoring();
  //                             _speechTimer.reset();
  //                             _speechTimer.start();
  //
  //                             _timer = Timer.periodic(const Duration(seconds: 1), (_) {
  //                               if (mounted) {
  //                                 setState(() {
  //                                   _formattedDuration = _formatDuration(_speechTimer.elapsed);
  //                                 });
  //                               }
  //                             });
  //
  //                             setState(() {
  //                               _isListening = true;
  //                               _formattedDuration = '00:00';
  //                             });
  //                           }
  //                         },
  //                       ),
  //                       const SizedBox(width: 8),
  //                     ],
  //
  //                     if (!_isListening && (_isTyping || _controller.text.isNotEmpty || _isTranscribing))
  //                       _buildCircleButton(
  //                         bgColor: const Color(0xFFF66A00),
  //   onTap: () {
  //                           if (!mounted) return;
  //                           if (_isTyping) {
  //                             _stopResponse();
  //                           } else {
  //                             _sendMessage();
  //                           }
  //                         },                          iconWidget: AnimatedSwitcher(
  //                           duration: const Duration(milliseconds: 300),
  //                           transitionBuilder: (child, animation) => ScaleTransition(
  //                             scale: animation,
  //                             child: child,
  //                           ),
  //                           child: Icon(
  //                             _isTyping ? Icons.stop : Icons.arrow_upward,
  //                             key: ValueKey(_isTyping),
  //                             color: Colors.white,
  //                           ),
  //                         ),
  //                       ),
  //
  //                     if (_isListening) ...[
  //                       const SizedBox(width: 4),
  //                       CircleAvatar(
  //                         backgroundColor: Colors.grey.shade200,
  //                         child: IconButton(
  //                           icon: const Icon(Icons.close),
  //                           onPressed: () {
  //                             _timer?.cancel();
  //                             _speechTimer.stop();
  //                             _stopMicMonitoring();
  //                             setState(() {
  //                               _isListening = false;
  //                               _isTranscribing = false;
  //                             });
  //                           },
  //                         ),
  //                       ),
  //                       const SizedBox(width: 8),
  //                       Expanded(
  //                         child: Padding(
  //                           padding: const EdgeInsets.symmetric(horizontal: 8),
  //                           child: ChatGPTScrollingWaveform(
  //                             key: const ValueKey('waveform'),
  //                             durationText: _formattedDuration,
  //                             isSpeaking: _isSpeaking,
  //                           ),
  //                         ),
  //                       ),
  //                       Text(
  //                         _formattedDuration,
  //                         style: const TextStyle(fontWeight: FontWeight.w500),
  //                       ),
  //                       const SizedBox(width: 8),
  //                       _isTranscribing
  //                           ? const CircleAvatar(
  //                         backgroundColor: Colors.black,
  //                         child: CupertinoActivityIndicator(color: Colors.white),
  //                       )
  //                           : GestureDetector(
  //                         onTap: () async {
  //                           _timer?.cancel();
  //                           _speechTimer.stop();
  //                           _stopMicMonitoring();
  //                           setState(() => _isTranscribing = true);
  //
  //                           final path = await _audioRecorder.stop();
  //                           if (path != null) _recordingPath = path;
  //
  //                           final file = File(_recordingPath);
  //                           if (file.existsSync()) {
  //                             await _transcribeAudio(); // uses animation + append
  //                           } else {
  //                             setState(() {
  //                               _isListening = false;
  //                               _isTranscribing = false;
  //                             });
  //                           }
  //                         },
  //                         child: const CircleAvatar(
  //                           backgroundColor: Colors.black,
  //                           radius: 16,
  //                           child: Icon(Icons.check, size: 16, color: Colors.white),
  //                         ),
  //                       ),
  //                     ],
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }



  Widget _buildCircleButton({
    IconData? icon,
    Widget? iconWidget,
    VoidCallback? onTap,
    bool isLoading = false,
    Color bgColor = Colors.transparent,
  }) {
    final bool isFilled = bgColor != Colors.transparent;

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

}

Widget _buildStyledBotMessage({
  required String fullText,
  required bool isComplete,
  required bool isLatest,
}) {
  final theme = locator<ThemeService>().currentTheme;

  final style = TextStyle(
    fontSize: 18, // ✅ matches ChatGPT iOS
    fontFamily: 'SF Pro Text',
    fontWeight: FontWeight.w400,
    height: 1.9, // ✅ better line height for dense layout
    color: theme.text,
  );

  List<TextSpan> processTextWithFormatting(String text) {
    final regexBold = RegExp(r"\*\*(.+?)\*\*");
    List<TextSpan> spans = [];

    String remainingText = text;
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
        style: style.copyWith(fontWeight: FontWeight.bold),
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
    if (line.trim().startsWith(RegExp(r"1\.|2\.|3\.|•|-"))) {
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
        Opacity(
          opacity: isComplete ? 1 : 0,
          child: Row(
            children: const [
              Icon(Icons.copy, size: 14, color: Colors.grey),
              SizedBox(width: 12),
              Icon(Icons.thumb_up_alt_outlined, size: 16, color: Colors.grey),
              SizedBox(width: 12),
              Icon(Icons.thumb_down_alt_outlined, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ],
    ),
  );
}



// Widget _buildStyledBotMessage({
//   required String fullText,
//   required bool isComplete,
//   required bool isLatest,
// }) {
//   final theme = locator<ThemeService>().currentTheme;
//   // final style =  TextStyle(
//   //   fontSize: 14.5,
//   //   color: theme.text,
//   //   height: 1.6,
//   //   fontFamily: 'DM Sans',
//   //   fontWeight: FontWeight.w400,
//   // );
//   final style = TextStyle(
//     fontSize: 17.5, // ✅ matches ChatGPT iOS
//     fontFamily: 'SF Pro Text',
//     fontWeight: FontWeight.w400,
//     height: 1.8, // ✅ better line height for dense layout
//     color: Colors.black,
//   );
//
//
//   // Function to process text with bold formatting
//   List<TextSpan> processTextWithFormatting(String text) {
//     final regexBold = RegExp(r"\*\*(.+?)\*\*");
//     List<TextSpan> spans = [];
//
//     String remainingText = text;
//     int lastMatchEnd = 0;
//
//     for (var match in regexBold.allMatches(text)) {
//       if (match.start > lastMatchEnd) {
//         spans.add(TextSpan(
//           text: text.substring(lastMatchEnd, match.start),
//           style: style,
//         ));
//       }
//
//       spans.add(TextSpan(
//         text: match.group(1),
//         style: style.copyWith(fontWeight: FontWeight.bold),
//       ));
//
//       lastMatchEnd = match.end;
//     }
//
//     if (lastMatchEnd < text.length) {
//       spans.add(TextSpan(
//         text: text.substring(lastMatchEnd),
//         style: style,
//       ));
//     }
//
//     return spans;
//   }
//
//   final lines = fullText.trim().split('\n');
//   List<TextSpan> spans = [];
//
//   for (var line in lines) {
//     if (line.trim().isEmpty) {
//       spans.add(const TextSpan(text: '\n'));
//       continue;
//     }
//
//     String emoji = '';
//     if (line.trim().startsWith(RegExp(r"1\.|2\.|3\.|•|-"))) {
//       emoji = '👉 ';
//     } else if (line.contains('Tip') || line.contains('Note')) {
//       emoji = '💡 ';
//     } else if (line.contains('Save') || line.contains('budget')) {
//       emoji = '💰 ';
//     }
//
//     spans.add(TextSpan(text: '\n$emoji'));
//     spans.addAll(processTextWithFormatting(line));
//   }
//
//   return Container(
//     padding: const EdgeInsets.symmetric(horizontal: 4),
//     decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         RichText(
//           text: TextSpan(style: style, children: spans),
//         ),
//         const SizedBox(height: 15),
//         Row(
//           children: [
//             Visibility(
//               visible: true,
//               maintainSize: true,
//               maintainAnimation: true,
//               maintainState: true,
//               child: Opacity(
//                 opacity: isComplete ? 1 : 0,
//                 child: const Icon(Icons.copy, size: 14, color: Colors.grey),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Visibility(
//               visible: true,
//               maintainSize: true,
//               maintainAnimation: true,
//               maintainState: true,
//               child: Opacity(
//                 opacity: isComplete ? 1 : 0,
//                 child: const Icon(Icons.thumb_up_alt_outlined, size: 16, color: Colors.grey),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Visibility(
//               visible: true,
//               maintainSize: true,
//               maintainAnimation: true,
//               maintainState: true,
//               child: Opacity(
//                 opacity: isComplete ? 1 : 0,
//                 child: const Icon(Icons.thumb_down_alt_outlined, size: 16, color: Colors.grey),
//               ),
//             ),
//           ],
//         ),
//       ],
//     ),
//   );
// }



class StreamingText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const StreamingText({super.key, required this.text, required this.style});

  @override
  State<StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<StreamingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotCount;

  @override
  void initState() {
    super.initState();
    // 🧼 Clear focus once on load
    Future.delayed(Duration.zero, () {
      FocusScope.of(context).unfocus();
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _dotCount = StepTween(begin: 0, end: 3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotCount,
      builder: (context, _) {
        final dots = '.' * _dotCount.value;
        return Text(
          '${widget.text}$dots',
          style: widget.style,
        );
      },
    );
  }
}



class StreamingRichText extends StatefulWidget {
  final List<InlineSpan> spans;
  final TextStyle style;

  const StreamingRichText({super.key, required this.spans, required this.style});

  @override
  State<StreamingRichText> createState() => _StreamingRichTextState();
}

class _StreamingRichTextState extends State<StreamingRichText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _charCount;
  String _fullText = '';
  List<InlineSpan> _partialSpans = [];

  @override
  void initState() {
    super.initState();

    // Flatten spans to get full string for animation count
    _fullText = widget.spans.map((span) => span.toPlainText()).join();
    final totalLength = _fullText.length;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalLength * 30),
    )..forward();

    _charCount = StepTween(begin: 0, end: totalLength).animate(_controller)
      ..addListener(() {
        final visibleText = _fullText.substring(0, _charCount.value);
        _partialSpans = _buildVisibleSpans(visibleText);
        if (mounted) setState(() {});
      });
  }

  List<InlineSpan> _buildVisibleSpans(String visibleText) {
    List<InlineSpan> visibleSpans = [];
    int currentIndex = 0;

    for (final span in widget.spans) {
      final spanText = span.toPlainText();
      final remaining = visibleText.length - currentIndex;

      if (remaining <= 0) break;

      final chunk = spanText.substring(0, remaining.clamp(0, spanText.length));
      visibleSpans.add(TextSpan(
        text: chunk,
        style: span is TextSpan ? span.style : null,
      ));
      currentIndex += chunk.length;
    }

    return visibleSpans;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(style: widget.style, children: _partialSpans),
    );
  }
}



class AnimatedDot extends StatefulWidget {
  final int delay;

  const AnimatedDot({
    Key? key,
    this.delay = 0,
  }) : super(key: key);

  @override
  State<AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<AnimatedDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Add delay if specified
    if (widget.delay > 0) {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox.shrink();
      },
    );
  }
}

class VoiceWaveform extends StatefulWidget {
  const VoiceWaveform({Key? key}) : super(key: key);

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _barAnimations;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _barAnimations = List.generate(5, (i) {
      final start = i * 0.1;
      final end = start + 0.4;
      return Tween<double>(begin: 6, end: 20).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeInOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_barAnimations.length, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 4,
            height: _barAnimations[index].value,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}






class AnimatedComingSoonTooltip extends StatefulWidget {
  @override
  _AnimatedComingSoonTooltipState createState() => _AnimatedComingSoonTooltipState();
}

class _AnimatedComingSoonTooltipState extends State<AnimatedComingSoonTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            'Coming Soon!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}



class AddShortcutCard extends StatelessWidget {
  const AddShortcutCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final overlay = Overlay.of(context);
        final renderBox = context.findRenderObject() as RenderBox;
        final size = renderBox.size;
        final offset = renderBox.localToGlobal(Offset.zero);

        final entry = OverlayEntry(
          builder: (context) => Positioned(
            top: offset.dy + size.height + 8,
            left: offset.dx + size.width / 2 - 60,
            child: Material(
              color: Colors.transparent,
              child: _ComingSoonTooltip(),
            ),
          ),
        );

        overlay.insert(entry);
        Future.delayed(const Duration(seconds: 2), () => entry.remove());
      },
      child: Container(
        height: 94,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF2F2F2F),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add, color: Colors.white, size: 20),
                SizedBox(width: 6),
                Text(
                  "Add Shortcut",
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white,fontSize: 16,fontFamily: 'DM Sans'),
                ),
              ],
            ),
            SizedBox(height: 2),
            Text(
              " Create your own quick prompt",
              style: TextStyle(fontSize: 14, color: Colors.white,fontFamily: "DM Sans"),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonTooltip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: const Text(
        "Coming soon",
        style: TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}




class TypewriterAnimatedText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;
  final bool isComplete;

  const TypewriterAnimatedText({
    Key? key,
    required this.text,
    required this.style,
    required this.duration,
    required this.isComplete,
  }) : super(key: key);

  @override
  _TypewriterAnimatedTextState createState() => _TypewriterAnimatedTextState();
}

class _TypewriterAnimatedTextState extends State<TypewriterAnimatedText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _displayedText = "";
  bool _isAnimating = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        final characterCount = (widget.text.length * _animation.value).floor();
        if (mounted) {
          setState(() {
            _displayedText = widget.text.substring(0, characterCount);
          });
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _isAnimating = false;
            _displayedText = widget.text;
          });
        }
      });

    // Start animation only if not already complete
    if (!widget.isComplete) {
      _controller.forward();
    } else {
      _displayedText = widget.text;
      _isAnimating = false;
    }
  }

  @override
  void didUpdateWidget(TypewriterAnimatedText oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If text changed and is still not complete, animate the rest
    if (widget.text != oldWidget.text && !widget.isComplete) {
      final charCount = oldWidget.text.length;
      final totalChars = widget.text.length;

      if (totalChars > charCount) {
        // Calculate what portion has been revealed
        final revealedPortion = charCount / totalChars;

        // Update the displayed text with what we already have
        _displayedText = widget.text.substring(0, charCount);

        // Reset animation to start from current point
        _controller.reset();
        _animation = Tween<double>(
          begin: revealedPortion,
          end: 1.0,
        ).animate(_controller);

        _isAnimating = true;
        _controller.forward();
      } else {
        // If text got shorter (unlikely but possible)
        _displayedText = widget.text;
      }
    }

    // If message is now complete but was animating before
    if (widget.isComplete && !oldWidget.isComplete) {
      _controller.stop();
      setState(() {
        _displayedText = widget.text;
        _isAnimating = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If animation is done or text is complete, show full text
    return RichText(
      text: TextSpan(
        style: widget.style,
        text: _displayedText,
      ),
    );
  }
}

// Enhanced typing indicator with pulse animation
class EnhancedTypingIndicator extends StatefulWidget {
  const EnhancedTypingIndicator({Key? key}) : super(key: key);

  @override
  _EnhancedTypingIndicatorState createState() => _EnhancedTypingIndicatorState();
}

class _EnhancedTypingIndicatorState extends State<EnhancedTypingIndicator> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 600),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    // Start animations with delays
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 8 + (4 * _animations[index].value),
              width: 8 + (4 * _animations[index].value),
              decoration: BoxDecoration(
                color: Colors.grey.shade600.withOpacity(0.6 + (0.4 * _animations[index].value)),
                borderRadius: BorderRadius.circular(5),
              ),
            );
          },
        );
      }),
    );
  }
}


Stream<wf.Amplitude> createSinusoidalAmplitudeStream() async* {
  double t = 0.0;
  while (true) {
    await Future.delayed(const Duration(milliseconds: 50)); // smooth update
    final value = 0.5 + 0.5 * math.sin(t); // 0 to 1
    yield wf.Amplitude(
      current: math.Random().nextDouble() * 100,
      max: 100,
    );
    t += 0.2; // slow forward movement
  }
}



class ChatGPTScrollingWaveform extends StatefulWidget {
  final bool isSpeaking;
  final String durationText;

  const ChatGPTScrollingWaveform({
    Key? key,
    required this.isSpeaking,
    required this.durationText,
  }) : super(key: key);

  @override
  State<ChatGPTScrollingWaveform> createState() => _ChatGPTScrollingWaveformState();
}

class _ChatGPTScrollingWaveformState extends State<ChatGPTScrollingWaveform> {
  final int maxBars = 40; // How many bars on screen at once
  final Duration frameRate = const Duration(milliseconds: 60); // 60 FPS feel
  final double flatHeight = 6; // Height when silent
  final double speakingMin = 10; // Minimum height when speaking
  final double speakingMax = 70; // Maximum height when speaking

  final List<double> _waveform = [];
  final random = math.Random();
  Timer? _timer;
  final theme = locator<ThemeService>().currentTheme;

  @override
  void initState() {
    super.initState();
    _waveform.addAll(List.generate(maxBars, (_) => flatHeight));
    _startWaveformAnimation();
  }

  void _startWaveformAnimation() {
    _timer = Timer.periodic(frameRate, (_) {
      if (!mounted) return;

      double nextHeight = widget.isSpeaking
          ? speakingMin + random.nextDouble() * (speakingMax - speakingMin)
          : flatHeight;

      setState(() {
        _waveform.add(nextHeight);
        if (_waveform.length > maxBars) {
          _waveform.removeAt(0); // Remove leftmost bar -> creates scrolling effect
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Cross button (Cancel)
        // const Icon(Icons.close, size: 24),
        // const SizedBox(width: 8),

        // Waveform (scrolling bars)
        Expanded(
          child: SizedBox(
            height: 40,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_waveform.length, (index) {
                  final barHeight = _waveform[index];
                  final isAnimated = barHeight > flatHeight;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: AnimatedContainer(
                      duration: frameRate,
                      width: 4,
                      height: _waveform[index],
                      decoration: BoxDecoration(
                        color: isAnimated ? AppColors.primary : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),

        // const SizedBox(width: 8),
        //
        // // Timer (Duration text)
        // Text(
        //   widget.durationText,
        //   style: const TextStyle(fontWeight: FontWeight.w500),
        // ),
        //
        // const SizedBox(width: 8),
        //
        // // Tick button (Send)
        // const Icon(Icons.check_circle, size: 24),
      ],
    );
  }
}

// class ChatGPTScrollingWaveform extends StatefulWidget {
//   final bool isSpeaking;
//   final String durationText;
//
//   const ChatGPTScrollingWaveform({
//     Key? key,
//     required this.isSpeaking,
//     required this.durationText,
//   }) : super(key: key);
//
//   @override
//   State<ChatGPTScrollingWaveform> createState() => _ChatGPTScrollingWaveformState();
// }
//
// class _ChatGPTScrollingWaveformState extends State<ChatGPTScrollingWaveform> {
//   final int maxBars = 40;
//   final Duration frameRate = const Duration(milliseconds: 60);
//   final double flatHeight = 6;
//   final double speakingMin = 10;
//   final double speakingMax = 70;
//
//   final List<double> _waveform = [];
//   final random = math.Random();
//   Timer? _timer;
//
//   @override
//   void initState() {
//     super.initState();
//     _waveform.addAll(List.generate(maxBars, (_) => flatHeight));
//     _startWaveformAnimation();
//   }
//
//   void _startWaveformAnimation() {
//     _timer = Timer.periodic(frameRate, (_) {
//       if (!mounted) return;
//
//       double nextHeight = widget.isSpeaking
//           ? speakingMin + random.nextDouble() * (speakingMax - speakingMin)
//           : flatHeight;
//
//       setState(() {
//         _waveform.add(nextHeight);
//         if (_waveform.length > maxBars) {
//           _waveform.removeAt(0);
//         }
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: SizedBox(
//             height: 40,
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: List.generate(_waveform.length, (index) {
//                   final barHeight = _waveform[index];
//                   final isAnimated = barHeight > flatHeight;
//
//                   return Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 1.5),
//                     child: AnimatedContainer(
//                       duration: frameRate,
//                       width: 3,
//                       height: barHeight,
//                       decoration: BoxDecoration(
//                         color: isAnimated ? AppColors.primary : Colors.grey.shade400,
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                   );
//                 }),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }










