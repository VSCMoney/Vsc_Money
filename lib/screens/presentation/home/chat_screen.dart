import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

// Import your existing chat service files
import '../../../models/chat_message.dart';
import '../../../models/chat_session.dart';
import '../../../models/stock_detail.dart';
import '../../../services/auth_service.dart';
import '../../../services/chat_service.dart';
import '../../../services/speech_service.dart';
import '../../models/document_context.dart';
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
  late final SpeechService _speechService;
   ScrollController _scrollController = ScrollController();
  bool _isPreviewingSpeech = false;

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

  // Flag to show only latest exchange during typing
 // bool _showOnlyLatestDuringTyping = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(keepScrollOffset: true);
    WidgetsBinding.instance.addObserver(this);
    _scrollToBottom();
    // Add a small delay to request focus to avoid keyboard issues
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });

    _focusNode.addListener(_onFocusChange);
    _speechService = SpeechService();
    //_initializeSpeech();
    _loadSessionMessages();



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
  }


  // Convert from ChatSession messages to local UI format
  void _loadSessionMessages() async {
    try {
      final fetched = await widget.chatService.fetchMessages(widget.session.id);

      if (!mounted) return;

      setState(() {
        messages = [];

        for (final m in fetched) {
          messages.add({
            'id': UniqueKey().toString(),
            'role': 'user',
            'msg': m.question ?? m.question ?? '', // optional chaining
            'isComplete': true,
          });

          messages.add({
            'id': UniqueKey().toString(),
            'role': 'bot',
            'msg': m.answer ?? '',
            'isComplete': true,
          });
        }
      });
       _hasLoadedMessages = true;
       _checkAndNotifyFirstMessageComplete();
      _scrollToBottom();
    } catch (e) {
      debugPrint("❌ Error loading messages: $e");
    }
  }



  // In ChatScreen.dart, add this print to see if the callback is actually called
  void _checkAndNotifyFirstMessageComplete() {
    if (!_firstMessageComplete && _isChatComplete()) {
      _firstMessageComplete = true;
      print("🔔 CALLING PARENT CALLBACK with value: true");
      widget.onFirstMessageComplete?.call(true);
    }
  }



  Future<void> _initializeSpeech() async {
    try {
      await _speechService.initialize();
    } catch (e) {
      print('Error initializing speech: $e');
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
    _streamSubscription?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _speechService.stopListening();
    super.dispose();
  }



  // void _sendMessage() async {
  //   if (!mounted || _controller.text.trim().isEmpty) return;
  //
  //   final userMessage = _controller.text.trim();
  //   final isFirstMessage = messages.where((m) => m['role'] == 'user').isEmpty;
  //
  //   setState(() {
  //     messages.add({
  //       'id': UniqueKey().toString(),
  //       'role': 'user',
  //       'msg': userMessage,
  //       'isComplete': true
  //     });
  //
  //     messages.add({
  //       'id': UniqueKey().toString(),
  //       'role': 'bot',
  //       'msg': '',
  //       'isComplete': false
  //     });
  //
  //     _controller.clear();
  //     _isTyping = true;
  //     _showOnlyLatestDuringTyping = true;
  //
  //     // Set title if it's first message
  //     if (isFirstMessage) {
  //       widget.session.title = userMessage;
  //     }
  //   });
  //
  //   _scrollToBottom();
  //
  //   try {
  //     final responseStream = await widget.chatService.sendMessageWithStreaming(
  //       sessionId: widget.session.id,
  //       message: userMessage,
  //     );
  //
  //     String streamedText = '';
  //     _currentStreamingId = '';
  //
  //     // This timer controls the animation smoothness
  //     Timer? throttleTimer;
  //
  //     _streamSubscription = responseStream.listen(
  //           (message) {
  //         if (!mounted) return;
  //
  //         // Set currentStreamingId only once
  //         if (_currentStreamingId.isEmpty && message.id != null) {
  //           _currentStreamingId = message.id!;
  //         }
  //
  //         // Accumulate text from the stream for smooth animation
  //         streamedText += message.text;
  //
  //         // Find the last message which should be the bot's response
  //         final lastIndex = messages.length - 1;
  //
  //         if (lastIndex >= 0 && messages[lastIndex]['role'] == 'bot') {
  //           // Throttle UI updates for smoother appearance
  //           throttleTimer?.cancel();
  //
  //           throttleTimer = Timer(const Duration(milliseconds: 30), () {
  //             if (!mounted) return;
  //
  //             setState(() {
  //               messages[lastIndex] = {
  //                 'id': messages[lastIndex]['id'] as String,  // Force cast to String
  //                 'role': 'bot',
  //                 'msg': streamedText,
  //                 'isComplete': message.isComplete,
  //               };
  //             });
  //
  //             // Make sure we're following the latest text
  //             if (_showOnlyLatestDuringTyping) {
  //               _scrollToBottom();
  //             }
  //           });
  //         }
  //
  //         // When the message is complete
  //         if (message.isComplete) {
  //           if (!mounted) return;
  //
  //           throttleTimer?.cancel();
  //
  //           setState(() {
  //             _isTyping = false;
  //
  //             // Update the last message once more to ensure it's complete
  //             if (lastIndex >= 0 && messages[lastIndex]['role'] == 'bot') {
  //               messages[lastIndex] = {
  //                 'id': messages[lastIndex]['id'] as String,
  //                 'role': 'bot',
  //                 'msg': streamedText,
  //                 'isComplete': true,
  //               };
  //             }
  //           });
  //
  //           // Specially handle the transition to full chat view with smooth scrolling
  //           _transitionToFullChat();
  //
  //           // Handle stock tiles if available
  //           if (streamedText.contains('"stocks":')) {
  //             try {
  //               final cleaned = streamedText
  //                   .replaceAll("```json", "")
  //                   .replaceAll("```", "")
  //                   .trim();
  //
  //               final Map<String, dynamic> data = jsonDecode(cleaned);
  //               final List<dynamic> stocks = data['stocks'];
  //
  //               setState(() {
  //                 messages.removeLast(); // Remove incomplete bot msg
  //                 messages.add({
  //                   'id': UniqueKey().toString(),
  //                   'role': 'bot',
  //                   'msg': '',
  //                   'type': 'stocks',
  //                   'stocks': stocks,
  //                 });
  //               });
  //
  //               // Remove this line
  //               // _scrollToBottom();
  //             } catch (e) {
  //               print('❌ Error parsing stock JSON: $e');
  //             }
  //           }
  //           }
  //
  //       },
  //       onError: (e) {
  //         print("❌ Stream error: $e");
  //         if (!mounted) return;
  //
  //         setState(() {
  //           _isTyping = false;
  //           _showOnlyLatestDuringTyping = false;
  //           final lastIndex = messages.length - 1;
  //           if (lastIndex >= 0 && messages[lastIndex]['role'] == 'bot') {
  //             messages[lastIndex] = {
  //               'id': messages[lastIndex]['id'] as String,
  //               'role': 'bot',
  //               'isComplete': true,
  //               'msg': 'Error: ${e.toString()}',
  //             };
  //           }
  //         });
  //
  //         _scrollToBottom();
  //       },
  //     );
  //   } catch (e) {
  //     print("❌ Error sending message: $e");
  //   }
  // }



  void _sendMessage() async {
    if (!mounted || _controller.text.trim().isEmpty) return;

    final userMessage = sanitizeMessage(_controller.text.trim());
    final isFirstMessage = messages.where((m) => m['role'] == 'user').isEmpty;

    DateTime dateTime = DateTime.now();

    setState(() {
      messages.add({
        'id': UniqueKey().toString(),
        'role': 'user',
        'msg': userMessage,
        'isComplete': true,
      });

      messages.add({
        'id': UniqueKey().toString(),
        'role': 'bot',
        'msg': '',
        'isComplete': false,
      });

      _controller.clear();
      _isTyping = true;
      _showOnlyLatestDuringTyping = true;

      // ✅ UI update
      if (isFirstMessage) {
        widget.session.title = userMessage;
      }
    });

    _scrollToBottom();

    try {
      // ✅ Backend title update (if first message)
      if (isFirstMessage) {
        await widget.chatService.updateSessionTitle(widget.session.id, userMessage);
      }

      final responseStream = await widget.chatService.sendMessageWithStreaming(
        sessionId: widget.session.id,
        message: userMessage,
      );

      String streamedText = '';
      _currentStreamingId = '';
      Timer? throttleTimer;
      print(DateTime.now().difference(dateTime));
      _streamSubscription = responseStream.listen(
            (message) {
          if (!mounted) return;

          if (_currentStreamingId.isEmpty && message.id != null) {
            _currentStreamingId = message.id!;
          }

          streamedText += message.text;
          final lastIndex = messages.length - 1;

          if (lastIndex >= 0 && messages[lastIndex]['role'] == 'bot') {
            throttleTimer?.cancel();
            throttleTimer = Timer(const Duration(milliseconds: 30), () {
              if (!mounted) return;
              setState(() {
                messages[lastIndex] = {
                  'id': messages[lastIndex]['id'] as String,
                  'role': 'bot',
                  'msg': streamedText,
                  'isComplete': message.isComplete,
                };
              });
              if (_showOnlyLatestDuringTyping) _scrollToBottom();
            });
          }

          if (message.isComplete) {
            if (!mounted) return;
            throttleTimer?.cancel();
            setState(() {
              _isTyping = false;
              if (lastIndex >= 0 && messages[lastIndex]['role'] == 'bot') {
                messages[lastIndex] = {
                  'id': messages[lastIndex]['id'] as String,
                  'role': 'bot',
                  'msg': streamedText,
                  'isComplete': true,
                };
              }
            });
            _checkAndNotifyFirstMessageComplete();
            _transitionToFullChat();

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
          print("❌ Stream error: $e");
          if (!mounted) return;
          setState(() {
            _isTyping = false;
            _showOnlyLatestDuringTyping = false;
            final lastIndex = messages.length - 1;
            if (lastIndex >= 0 && messages[lastIndex]['role'] == 'bot') {
              messages[lastIndex] = {
                'id': messages[lastIndex]['id'] as String,
                'role': 'bot',
                'isComplete': true,
                'msg': 'Error: ${e.toString()}',
              };
            }
          });
          _scrollToBottom();
        },
      );
    } catch (e) {
      print("❌ Error sending message: $e");
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


  // In ChatScreen.dart
  bool _isChatComplete() {
    // Simplify the check - just look for at least one user message and one completed bot message
    bool hasUserMessage = messages.any((m) => m['role'] == 'user');
    bool hasCompleteBotMessage = messages.any((m) => m['role'] == 'bot' && m['isComplete'] == true);

    // Debug print
    print("Chat complete check: hasUserMessage=$hasUserMessage, hasCompleteBotMessage=$hasCompleteBotMessage");

    return hasUserMessage && hasCompleteBotMessage;
  }



  // Improved scrollToBottom function to be less aggressive
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 30), () {
      if (_scrollController.hasClients) {
        final position = _scrollController.position;
        final isNearBottom = position.maxScrollExtent - position.pixels < 150;

        if (isNearBottom) {
          _scrollController.jumpTo(position.maxScrollExtent);
        } else {
          _scrollController.animateTo(
            position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
  }

// Improved transition function that doesn't auto-scroll aggressively
  // First, modify how we handle the transition to full chat
  void _transitionToFullChat() {
    if (!_showOnlyLatestDuringTyping || messages.length <= 2) return;

    // Save the current message we're looking at before the transition
    final int currentIndex = messages.length - 1;

    setState(() {
      _showOnlyLatestDuringTyping = false;
    });

    // After the state change, scroll to keep the same message in view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Find the position of the current message in the full list
        // This will ensure we keep looking at the same message we were viewing
        final double targetPosition = _calculateScrollPositionForIndex(currentIndex);
        _scrollController.jumpTo(targetPosition);
      }
    });
  }

// Add this helper method to calculate scroll position for a specific message index
  double _calculateScrollPositionForIndex(int index) {
    // This is an approximation - you may need to adjust based on your message heights
    // Assuming average message height of 100 pixels plus padding
    const double estimatedMessageHeight = 100.0;
    const double listPadding = 16.0;

    return math.max(0, index * estimatedMessageHeight - listPadding);
  }

    // No automatic scrolling - let the user stay where they are




  Widget _buildMessageRow(Map<String, Object> msg) {
    if (msg['role'] == 'user') {
      return Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
        // GestureDetector(
        //             onTap: () {},
        //             child: const Icon(Icons.edit, size: 18),
        //           ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: msg['msg'].toString()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                    child: const Icon(Icons.copy, size: 18),
                  ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0XFFF1EFEF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(msg['msg'].toString()),
              ),
            ),
          ],
        ),
      );
    }

    // Check if it's a stock tile message
    if (msg['type'] == 'stocks' && msg['stocks'] is List) {
      final List<dynamic> stocks = msg['stocks'] as List<dynamic>;

      return _buildStockTileList(stocks);
    }

    // Default bot message
    final msgStr = msg['msg']?.toString() ?? '';
    final isComplete = msg['isComplete'] == true;
    final isLatest = msg == messages.last;
    return Align(
      alignment: Alignment.centerLeft,
      child: msgStr.isEmpty
                ? _buildTypingIndicator()
                : _buildStyledBotMessage(msgStr,isComplete: isComplete,
        isLatest: isLatest,),
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
    //final displayMessages = _visibleMessages;
    final displayMessages = _showOnlyLatestDuringTyping && messages.length > 2
        ? messages.sublist(messages.length - 2) // Only show the latest exchange
        : _visibleMessages;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Show a helper text if we're only showing the latest exchange during typing
            if (_showOnlyLatestDuringTyping && messages.length > 2)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.blue.withOpacity(0.1),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    SizedBox(width: 6),
                    Text(
                      "Showing only the latest exchange",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: displayMessages.length,
                itemBuilder: (context, index) {
                  final msg = displayMessages[index];
                  return _buildMessageRow(msg);
                },
              ),
            ),
            if (_hasLoadedMessages &&!messages.any((m) => m['role'] == 'user'))
              SizedBox(
                height: 84,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  children: [
                    _quickChip(
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
                    const SizedBox(width: 12),
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
              ),


            _buildInputFields(),

            // Add keyboard spacer
            if (_isKeyboardVisible)
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }


  void _callFollowUpApi() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    DateTime dateTime = DateTime.now();
    final res = await http.post(
      Uri.parse("https://fastapi-chatbot-717280964807.asia-south1.run.app/api/v1/follow_up"),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    DateTime dateTime2 = DateTime.now();
    print(dateTime2.difference(dateTime));
    print("📩 Response: ${res.body}");
  }


  Widget _buildTypingIndicator() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildDot(),
              const SizedBox(width: 3),
              _buildDot(delay: 300),
              const SizedBox(width: 3),
              _buildDot(delay: 600),
            ],
          ),
        ),
      ],
    );
  }



  Widget _quickChip({
    required String title,
    required String subtitle,
    required double maxWidth,
    required VoidCallback onpressed,
  }) {
    return GestureDetector(
      onTap: onpressed,
      child: Container(
        //constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildDot({int delay = 0}) {
    return AnimatedDot(delay: delay);
  }

  Widget _buildChip(BuildContext context, {required String label, required int index}) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Close keyboard
        Future.delayed(const Duration(milliseconds: 100), () {
          widget.onNavigateToTab?.call(index); // Switch tab
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildInputFields() {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // if (_isListening)
            //   const Padding(
            //     padding: EdgeInsets.only(bottom: 12),
            //     child: VoiceWaveform(),
            //   ),
            Column(
              children: [
                TextField(
                  autofocus: true,
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Ask anything...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) {
                    if (mounted) setState(() {});
                  },
                  onSubmitted: (_) {
                    if (mounted) _sendMessage();
                  },
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (!_isListening) ...[
                      _buildCircleButton(
                        icon: Icons.add,
                        isLoading: _isProcessingDocument,
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
                      ),
                      const SizedBox(width: 12),
                      const Spacer(),
                      _buildCircleButton(
                        icon: Icons.mic,
                        onTap: () async {
                          await _initializeSpeech();
                          if (mounted) {
                            setState(() {
                              _isListening = true;
                              _showSpeechBar = true;
                              _recognizedSpeech = '';
                              _formattedDuration = '00:00';
                              _speechTimer.reset();
                              _speechTimer.start();
                            });

                            _timer = Timer.periodic(const Duration(seconds: 1), (_) {
                              if (mounted) {
                                setState(() {
                                  _formattedDuration = _formatDuration(_speechTimer.elapsed);
                                });
                              }
                            });

                            await _speechService.startListening(onResultCallback: (text) {
                              if (!mounted) return;
                              setState(() {
                                _recognizedSpeech = text;
                                _controller.text = text;
                                _controller.selection = TextSelection.fromPosition(
                                  TextPosition(offset: text.length),
                                );
                              });
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      (_controller.text.trim().isNotEmpty || _isTyping)
                          ? _buildCircleButton(
                        bgColor: Colors.orange,
                        icon: _isTyping ? Icons.stop : Icons.arrow_upward,
                        onTap: () {
                          if (!mounted) return;
                          if (_isTyping) {
                            _stopResponse();
                          } else {
                            _sendMessage();
                          }
                        },
                      )
                          : const SizedBox.shrink(),
                    ] else ...[
                      const SizedBox(width: 4),
                      const VoiceWaveform(),
                      const SizedBox(width: 12),
                      Text(
                        _formattedDuration,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          _speechTimer.stop();
                          _timer.cancel();
                          _speechService.stopListening();
                          if (mounted) {
                            setState(() {
                              _isListening = false;
                              _showSpeechBar = false;
                            });

                            // Refocus text field
                            Future.delayed(const Duration(milliseconds: 100), () {
                              FocusScope.of(context).requestFocus(_focusNode);
                            });
                          }
                        },
                        child: const CircleAvatar(
                          backgroundColor: Colors.black,
                          radius: 16,
                          child: Icon(Icons.check, size: 16, color: Colors.white),
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCircleButton({
    IconData? icon,
    VoidCallback? onTap,
    bool isLoading = false,
    Color bgColor = Colors.transparent,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: isLoading
            ? const Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        )
            : Icon(
          icon,
          size: 18,
          color: bgColor == Colors.transparent ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}

// Widget _buildStyledBotMessage(String fullText) {
//   final lines = fullText.trim().split('\n');
//   final regexBold = RegExp(r"\*\*(.+?)\*\*");
//
//   List<InlineSpan> spans = [];
//
//   for (var line in lines) {
//     if (line.trim().isEmpty) {
//       spans.add(const TextSpan(text: '\n')); // extra spacing
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
//     // Apply bold styling if **text** exists
//     final boldMatch = regexBold.firstMatch(line);
//     if (boldMatch != null) {
//       final before = line.substring(0, boldMatch.start);
//       final boldText = boldMatch.group(1)!;
//       final after = line.substring(boldMatch.end);
//
//       spans.add(TextSpan(text: '\n$emoji$before'));
//       spans.add(TextSpan(
//         text: boldText,
//         style: const TextStyle(fontWeight: FontWeight.bold),
//       ));
//       spans.add(TextSpan(text: after));
//     } else {
//       spans.add(TextSpan(text: '\n$emoji$line'));
//     }
//   }
//
//
//   return Column(
//     children: [
//       RichText(
//         text: TextSpan(
//           style: const TextStyle(
//             fontSize: 14.5,
//             color: Colors.black,
//             height: 1.6, // better line height
//           ),
//           children: spans,
//         ),
//       ),
//       SizedBox(height: 5),
//       Row(
//         //mainAxisSize: MainAxisSize.min,
//         children: [
//           GestureDetector(
//             onTap: () {}, // copy logic
//             child: Icon(Icons.copy, size: 20, color: Colors.grey),
//           ),
//           SizedBox(width: 12),
//           GestureDetector(
//             onTap: () {}, // like logic
//             child: Icon(Icons.thumb_up_alt_outlined, size: 20, color: Colors.grey),
//           ),
//           SizedBox(width: 12),
//           GestureDetector(
//             onTap: () {}, // dislike logic
//             child: Icon(Icons.thumb_down_alt_outlined, size: 20, color: Colors.grey),
//           ),
//         ],
//       )
//
//
//
//     ],
//   );
// }

// Animated dot for typing indicator


Widget _buildStyledBotMessage(String fullText, {
  required bool isComplete,
  required bool isLatest,
}) {
  final lines = fullText.trim().split('\n');
  final regexBold = RegExp(r"\*\*(.+?)\*\*");

  List<InlineSpan> spans = [];

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

    final boldMatch = regexBold.firstMatch(line);
    if (boldMatch != null) {
      final before = line.substring(0, boldMatch.start);
      final boldText = boldMatch.group(1)!;
      final after = line.substring(boldMatch.end);

      spans.add(TextSpan(text: '\n$emoji$before'));
      spans.add(TextSpan(
        text: boldText,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      spans.add(TextSpan(text: after));
    } else {
      spans.add(TextSpan(text: '\n$emoji$line'));
    }
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14.5,
            color: Colors.black,
            height: 1.6,
          ),
          children: spans,
        ),
      ),

      // 👍 👎 Copy - shown only if latest message and complete
      if (isComplete) ...[
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: () {}, // copy
              child: const Icon(Icons.copy, size: 20, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {}, // like
              child: const Icon(Icons.thumb_up_alt_outlined, size: 20, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {}, // dislike
              child: const Icon(Icons.thumb_down_alt_outlined, size: 20, color: Colors.grey),
            ),
          ],
        ),
      ]
    ],
  );
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
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade500,
            borderRadius: BorderRadius.circular(4),
          ),
        );
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






class StockDetailScreen extends StatefulWidget {
  final String symbol;
  const StockDetailScreen({required this.symbol});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  StockDetail? stock;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    final result = await StockService.getStockDetail(widget.symbol);
    setState(() {
      stock = result;
      loading = false;
    });
    print(stock?.price);
    print("Parsed JSON: ${stock?.name} | ${stock?.symbol} | ${stock?.price}");

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.symbol)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : stock == null
          ? const Center(child: Text("Stock data not found"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(stock!),
            const SizedBox(height: 20),
            _buildSection("Stock Overview", stock!.details),
            const SizedBox(height: 20),
            _buildDisclaimer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(StockDetail data) {
    final isNegative = data.change.contains('-');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.symbol,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(data.price, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isNegative ? Colors.red.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                data.change,
                style: TextStyle(
                  color: isNegative ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildSection(String title, Map details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: details.entries.map<Widget>((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500))),
                      Expanded(flex: 3, child: Text(entry.value.toString(), textAlign: TextAlign.right)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildDisclaimer() {
    return Text(
      "Note: Data sourced from Google Finance and may be delayed or approximate.",
      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
        padding: const EdgeInsets.all(12),
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
                Icon(Icons.add, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  "Add Shortcut",
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
            SizedBox(height: 2),
            Text(
              "Create your own quick prompt",
              style: TextStyle(fontSize: 10, color: Colors.white),
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





