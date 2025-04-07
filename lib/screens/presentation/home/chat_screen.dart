// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'dart:io';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter/services.dart';
//
// // Import your existing chat service files
// import '../../../models/chat_message.dart';
// import '../../../models/chat_session.dart';
// import '../../../services/chat_service.dart';
// import '../../../services/speech_service.dart';
// import '../../models/document_context.dart';
// import '../../utils/file_helps.dart';
//
// class ChatScreen extends StatefulWidget {
//   final ChatSession session;
//   final ChatService chatService;
//   final void Function(int)? onNavigateToTab;
//
//   const ChatScreen({
//     Key? key,
//     required this.session,
//     required this.chatService,
//     this.onNavigateToTab
//   }) : super(key: key);
//
//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _controller = TextEditingController();
//   final FocusNode _focusNode = FocusNode();
//   late final SpeechService _speechService;
//   final ScrollController _scrollController = ScrollController();
//   bool _isPreviewingSpeech = false;
//
//
//   bool _showExpandedInput = false;
//   bool _isTyping = false;
//   bool _isListening = false;
//   bool _isProcessingDocument = false;
//   bool get _isKeyboardVisible => MediaQuery.of(context).viewInsets.bottom > 0;
//
//
//   List<Map<String, Object>> messages = []; // Changed to Map<String, Object>
//   StreamSubscription<ChatMessage>? _streamSubscription;
//   String _currentStreamingId = '';
//   final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
//
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) {
//         FocusScope.of(context).requestFocus(_focusNode);
//       }
//     });
//
//
//     _focusNode.addListener(_onFocusChange);
//     _speechService = SpeechService();
//     _initializeSpeech();
//     _loadSessionMessages();
//
//
//     // Auto-scroll on initial load
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _scrollToBottom();
//     });
//
//     // Listen to session updates (in case new messages are added externally)
//     widget.chatService.sessions.listen((sessions) {
//       if (!mounted) return;
//
//       try {
//         final updatedSession = sessions.firstWhere(
//               (s) => s.id == widget.session.id,
//           orElse: () => widget.session,
//         );
//
//         // Reload messages and scroll down
//         _loadSessionMessages(updatedSession);
//
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           _scrollToBottom();
//         });
//       } catch (e) {
//         print('Error updating session messages: $e');
//       }
//     });
//
//     // Listen for live streaming message updates
//     widget.chatService.currentMessageStream.listen((updatedMessage) {
//       if (!mounted) return;
//
//       if (_currentStreamingId == updatedMessage.id) {
//         final index = messages.indexWhere((m) =>
//         m['role'] == 'bot' && m['id'] == updatedMessage.id);
//
//         if (index != -1) {
//           setState(() {
//             messages[index] = {
//               ...messages[index],
//               'msg': updatedMessage.text as Object,
//               'isComplete': updatedMessage.isComplete as Object,
//             };
//           });
//
//           // Scroll after update is rendered
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _scrollToBottom();
//           });
//
//           if (updatedMessage.isComplete) {
//             setState(() {
//               _isTyping = false;
//             });
//           }
//         }
//       }
//     }, onError: (e) {
//       print('Stream listen error: $e');
//     });
//   }
//
//
//   // Convert from ChatSession messages to local UI format
//   void _loadSessionMessages([ChatSession? session]) {
//     if (!mounted) return;
//
//     final messagesToLoad = session?.messages ?? widget.session.messages;
//
//     setState(() {
//       messages = messagesToLoad.map((chatMessage) {
//         return {
//           'id': chatMessage.id as Object,
//           'role': (chatMessage.isUser ? 'user' : 'bot') as Object,
//           'msg': chatMessage.text as Object,
//           'isComplete': chatMessage.isComplete as Object,
//         };
//       }).toList();
//     });
//   }
//
//   Future<void> _initializeSpeech() async {
//     try {
//       await _speechService.initialize();
//     } catch (e) {
//       print('Error initializing speech: $e');
//     }
//   }
//
//   void _startListening() async {
//     if (!mounted) return;
//
//     if (!kIsWeb) {
//       await _initializeSpeech();
//     }
//
//     setState(() => _isListening = true);
//     try {
//       await _speechService.startListening(onResultCallback: (text) {
//         if (!mounted) return;
//
//         setState(() {
//           _controller.text = text;
//           _controller.selection = TextSelection.fromPosition(
//             TextPosition(offset: _controller.text.length),
//           );
//         });
//       });
//     } catch (e) {
//       print('Error starting speech recognition: $e');
//       if (mounted) {
//         setState(() => _isListening = false);
//       }
//     }
//   }
//
//   void _stopListening() {
//     if (!mounted) return;
//     setState(() => _isListening = false);
//     _speechService.stopListening();
//   }
//
//   void _onFocusChange() {
//     if (mounted) {
//       setState(() {
//         _showExpandedInput = _focusNode.hasFocus;
//       });
//     }
//   }
//
//
//   Widget _buildMessageRow(Map<String, Object> msg) {
//     if (msg['role'] == 'user') {
//       return Padding(
//         padding: const EdgeInsets.only(bottom: 16),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.end,
//           children: [
//             GestureDetector(
//               onTap: () {},
//               child: const Icon(Icons.edit, size: 18),
//             ),
//             const SizedBox(width: 8),
//             GestureDetector(
//               onTap: () {
//                 Clipboard.setData(ClipboardData(text: msg['msg'].toString()));
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Copied to clipboard')),
//                 );
//               },
//               child: const Icon(Icons.copy, size: 18),
//             ),
//             const SizedBox(width: 8),
//             Flexible(
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade200,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(msg['msg']?.toString() ?? ''),
//               ),
//             ),
//           ],
//         ),
//       );
//     } else {
//       final msgStr = msg['msg']?.toString() ?? '';
//       final isComplete = msg['isComplete'] == true;
//       return Padding(
//         padding: const EdgeInsets.only(bottom: 16),
//         child: msgStr.isEmpty && !isComplete
//             ? _buildTypingIndicator()
//             : _buildStyledBotMessage(msgStr),
//       );
//     }
//   }
//
//
//
//   @override
//   void dispose() {
//     _streamSubscription?.cancel();
//     _focusNode.removeListener(_onFocusChange);
//     _focusNode.dispose();
//     _controller.dispose();
//     _speechService.stopListening();
//     super.dispose();
//   }
//
//
//
//   void _sendMessage() async {
//     if (!mounted || _controller.text.trim().isEmpty) return;
//
//     // 1. Hide the keyboard
//     FocusScope.of(context).unfocus();
//
//     final userMessage = _controller.text.trim();
//
//     // 2. Add user message
//     final userIndex = messages.length;
//     messages.add({
//       'role': 'user',
//       'msg': userMessage,
//       'isComplete': true,
//     });
//     _listKey.currentState?.insertItem(userIndex);
//     _scrollToBottom();
//
//     // 3. Add bot placeholder
//     final botIndex = messages.length;
//     messages.add({
//       'role': 'bot',
//       'msg': '',
//       'isComplete': false,
//     });
//     _listKey.currentState?.insertItem(botIndex);
//     _scrollToBottom();
//
//     setState(() {
//       _isTyping = true;
//       _controller.clear();
//     });
//
//     try {
//       File? fileToSend;
//
//       if (!kIsWeb && documentContext.hasDocument && documentContext.lastFilePath.isNotEmpty) {
//         final file = File(documentContext.lastFilePath);
//         if (await file.exists()) {
//           fileToSend = file;
//         }
//       }
//
//       final responseStream = await widget.chatService.sendMessageWithStreaming(
//         sessionId: widget.session.id,
//         message: userMessage,
//         attachedFile: fileToSend,
//       );
//
//       _streamSubscription?.cancel();
//       _streamSubscription = responseStream.listen(
//             (message) {
//           if (!mounted) return;
//
//           _currentStreamingId = message.id;
//
//           final lastIndex = messages.length - 1;
//           if (lastIndex >= 0 && messages[lastIndex]['role'] == 'bot') {
//             setState(() {
//               messages[lastIndex] = {
//                 ...messages[lastIndex],
//                 'id': message.id,
//                 'msg': message.text,
//                 'isComplete': message.isComplete,
//               };
//               if (message.isComplete) {
//                 _isTyping = false;
//               }
//             });
//
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               _scrollToBottom();
//             });
//           }
//         },
//         onError: (e) {
//           if (!mounted) return;
//           setState(() {
//             _isTyping = false;
//             final lastIndex = messages.length - 1;
//             if (lastIndex >= 0 && messages[lastIndex]['role'] == 'bot') {
//               messages[lastIndex] = {
//                 ...messages[lastIndex],
//                 'isComplete': true,
//                 'msg': 'Error: ${e.toString()}',
//               };
//             }
//           });
//
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Error: ${e.toString()}')),
//           );
//         },
//         onDone: () {
//           if (!mounted) return;
//           setState(() {
//             _isTyping = false;
//             final lastIndex = messages.length - 1;
//             if (lastIndex >= 0 && messages[lastIndex]['role'] == 'bot') {
//               messages[lastIndex] = {
//                 ...messages[lastIndex],
//                 'isComplete': true,
//               };
//             }
//           });
//
//           _scrollToBottom();
//         },
//       );
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _isTyping = false;
//         final lastIndex = messages.length - 1;
//         if (lastIndex >= 0 && messages[lastIndex]['role'] == 'bot') {
//           messages[lastIndex] = {
//             ...messages[lastIndex],
//             'isComplete': true,
//             'msg': 'Error: ${e.toString()}',
//           };
//         }
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: ${e.toString()}')),
//       );
//     }
//   }
//
//
//   void _stopResponse() {
//     try {
//       _streamSubscription?.cancel();
//       widget.chatService.stopResponse(
//         widget.session.id,
//         _currentStreamingId,
//       );
//     } catch (e) {
//       print('Error stopping response: $e');
//     }
//
//     if (mounted) {
//       setState(() {
//         final lastIndex = messages.length - 1;
//         if (lastIndex >= 0) {
//           messages[lastIndex] = {
//             ...messages[lastIndex],
//             'isComplete': true as Object,
//           };
//         }
//         _isTyping = false;
//       });
//     }
//   }
//
//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent + 100,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       behavior: HitTestBehavior.opaque, // 👉 this ensures taps go through
//       onTap: () {
//         FocusScope.of(context).unfocus(); // 🔥 Hide the keyboard
//       },
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         body: Stack(children: [
//           Column(
//             children: [
//               Expanded(
//                 child: AnimatedList(
//                   key: _listKey,
//                   reverse: true, // 👈 flip the list!
//                   controller: _scrollController,
//                   padding: const EdgeInsets.all(16),
//                   initialItemCount: messages.length,
//                   itemBuilder: (context, index, animation) {
//                     final msg = messages[index];
//                     return SizeTransition(
//                       sizeFactor: animation,
//                       child: _buildMessageRow(msg),
//                     );
//                   },
//                 )
//
//               ),
//
//               // Expanded(
//               //   child: ListView.builder(
//               //     controller: _scrollController,
//               //     padding: const EdgeInsets.all(16),
//               //     itemCount: messages.length,
//               //     itemBuilder: (context, index) {
//               //       final msg = messages[index];
//               //       if (msg['role'] == 'user') {
//               //         return Padding(
//               //           padding: const EdgeInsets.only(bottom: 16),
//               //           child: Row(
//               //             mainAxisAlignment: MainAxisAlignment.end,
//               //             children: [
//               //               GestureDetector(
//               //                 onTap: () {
//               //
//               //                 },
//               //                 child: const Icon(Icons.edit, size: 18),
//               //               ),
//               //               const SizedBox(width: 8),
//               //
//               //               // 📋 Copy Button
//               //               GestureDetector(
//               //                 onTap: () {
//               //                   Clipboard.setData(ClipboardData(text: msg['msg'].toString()));
//               //                   ScaffoldMessenger.of(context).showSnackBar(
//               //                     const SnackBar(content: Text('Copied to clipboard')),
//               //                   );
//               //                 },
//               //                 child: const Icon(Icons.copy, size: 18),
//               //               ),
//               //               const SizedBox(width: 8),
//               //               Flexible(
//               //                 child: Container(
//               //                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//               //                   decoration: BoxDecoration(
//               //                     color: Colors.grey.shade200,
//               //                     borderRadius: BorderRadius.circular(20),
//               //                   ),
//               //                   child: Text(msg['msg'] != null ? msg['msg'].toString() : ''),
//               //                 ),
//               //               ),
//               //             ],
//               //           ),
//               //         );
//               //       } else {
//               //         // For bot message
//               //         final msgStr = msg['msg'] != null ? msg['msg'].toString() : '';
//               //         final isComplete = msg['isComplete'] == true;
//               //
//               //         return Padding(
//               //             padding: const EdgeInsets.only(bottom: 16),
//               //             child: msgStr.isEmpty && !isComplete
//               //                 ? _buildTypingIndicator() // Show typing indicator for empty messages
//               //                 : _buildStyledBotMessage(msgStr)
//               //         );
//               //       }
//               //     },
//               //   ),
//               // ),
//
//               // Use the state variable to determine which input to show
//               _buildInputFields(),
//             ],
//           ),
//           if (_isKeyboardVisible)
//             Positioned(
//               bottom: MediaQuery.of(context).viewInsets.bottom + 16,
//               left: 16,
//               right: 16,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   _buildChip(context, label: "Assets", index: 2),
//                   const SizedBox(width: 12),
//                   _buildChip(context, label: "Goals", index: 1),
//                 ],
//               ),
//             ),
//
//         ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTypingIndicator() {
//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.grey.shade200,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Row(
//             children: [
//               _buildDot(),
//               const SizedBox(width: 3),
//               _buildDot(delay: 300),
//               const SizedBox(width: 3),
//               _buildDot(delay: 600),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildDot({int delay = 0}) {
//     return AnimatedDot(delay: delay);
//   }
//
//   Widget _buildChip(BuildContext context, {required String label, required int index}) {
//     return GestureDetector(
//       onTap: () {
//         FocusScope.of(context).unfocus(); // Close keyboard
//         Future.delayed(const Duration(milliseconds: 100), () {
//           widget.onNavigateToTab?.call(index); // Switch tab
//         });
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//         decoration: BoxDecoration(
//           border: Border.all(color: Colors.black.withOpacity(0.3)),
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
//       ),
//     );
//   }
//
//
//   Widget _buildInputFields() {
//
//     return  Padding(
//       padding: const EdgeInsets.all(16),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//         decoration: BoxDecoration(
//           border: Border.all(color: Colors.grey.shade300),
//           borderRadius: BorderRadius.circular(30),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (_isListening)
//               const Padding(
//                 padding: EdgeInsets.only(bottom: 12),
//                 child: VoiceWaveform(), // 👈 waveform animation
//               ),
//             TextField(
//               autofocus: true,
//               controller: _controller,
//               focusNode: _focusNode,
//               decoration: const InputDecoration(
//                 hintText: 'Ask anything...',
//                 border: InputBorder.none,
//                 contentPadding: EdgeInsets.zero,
//               ),
//             ),
//             const SizedBox(height: 12),
//
//             // Icons row at bottom
//             Row(
//               children: [
//                 GestureDetector(
//                   onTap: () {
//                     if (mounted) {
//                       setState(() => _isProcessingDocument = true);
//                       FileHelpers.pickAndProcessFile().then((result) {
//                         if (mounted) {
//                           setState(() => _isProcessingDocument = false);
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(content: Text(result)),
//                           );
//                         }
//                       });
//                     }
//                   },
//                   child: Container(
//                     height: 36,
//                     width: 36,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       border: Border.all(color: Colors.grey),
//                     ),
//                     child: _isProcessingDocument
//                         ? const SizedBox(
//                       height: 20,
//                       width: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
//                       ),
//                     )
//                         : const Icon(Icons.add, size: 20),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 const Spacer(),
//                 // GestureDetector(
//                 //   onLongPress: _startListening, // Start speech on long press
//                 //   onLongPressUp: _stopListening, // Stop when user lifts finger
//                 //   onTap: () {
//                 //     // Optional: show a dialog to confirm or re-record
//                 //     if (_controller.text.isNotEmpty) {
//                 //       showDialog(
//                 //         context: context,
//                 //         builder: (context) => AlertDialog(
//                 //           title: const Text('Use this input?'),
//                 //           content: Text(_controller.text),
//                 //           actions: [
//                 //             TextButton(
//                 //               onPressed: () => Navigator.pop(context),
//                 //               child: const Text('Cancel'),
//                 //             ),
//                 //             TextButton(
//                 //               onPressed: () {
//                 //                 Navigator.pop(context);
//                 //                 _sendMessage(); // Send message
//                 //               },
//                 //               child: const Text('Send'),
//                 //             ),
//                 //           ],
//                 //         ),
//                 //       );
//                 //     }
//                 //   },
//                 //   child: Container(
//                 //     height: 36,
//                 //     width: 36,
//                 //     decoration: BoxDecoration(
//                 //       shape: BoxShape.circle,
//                 //       border: Border.all(
//                 //         color: _isListening ? Colors.red : Colors.grey,
//                 //       ),
//                 //     ),
//                 //     child: Icon(
//                 //       _isListening ? Icons.stop : Icons.mic,
//                 //       size: 20,
//                 //       color: _isListening ? Colors.red : null,
//                 //     ),
//                 //   ),
//                 // ),
//                 _isListening
//                     ? GestureDetector(
//                   onTap: () {
//                     _speechService.stopListening();
//                     setState(() {
//                       _isListening = false;
//                       _isPreviewingSpeech = false;
//                     });
//                   },
//                   child: const CircleAvatar(
//                     backgroundColor: Colors.green,
//                     child: Icon(Icons.check, color: Colors.white),
//                   ),
//                 )
//                     : GestureDetector(
//                   onTap: () async {
//                     await _initializeSpeech();
//                     setState(() {
//                       _isListening = true;
//                       _controller.clear();
//                     });
//                     await _speechService.startListening(onResultCallback: (text) {
//                       if (!mounted) return;
//                       setState(() {
//                         _controller.text = text;
//                         _controller.selection = TextSelection.fromPosition(
//                           TextPosition(offset: _controller.text.length),
//                         );
//                       });
//                     });
//                   },
//                   child: const CircleAvatar(
//                     backgroundColor: Colors.orange,
//                     child: Icon(Icons.mic, color: Colors.white),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 GestureDetector(
//                   onTap: _isTyping ? _stopResponse : _sendMessage,
//                   child: CircleAvatar(
//                     radius: 18,
//                     backgroundColor: Colors.orange,
//                     child: Icon(
//                         _isTyping ? Icons.stop : Icons.arrow_upward,
//                         color: Colors.white,
//                         size: 18
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//
//
//   Widget _buildInputField() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (_isListening)
//             const Padding(
//               padding: EdgeInsets.only(bottom: 12),
//               child: VoiceWaveform(), // 👈 waveform animation
//             ),
//           Row(
//             children: [
//               // 📎 File picker
//               GestureDetector(
//                 onTap: () {
//                   if (mounted) {
//                     setState(() => _isProcessingDocument = true);
//                     FileHelpers.pickAndProcessFile().then((result) {
//                       if (mounted) {
//                         setState(() => _isProcessingDocument = false);
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(content: Text(result)),
//                         );
//                       }
//                     });
//                   }
//                 },
//                 child: Container(
//                   height: 36,
//                   width: 36,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.grey),
//                   ),
//                   child: _isProcessingDocument
//                       ? const SizedBox(
//                     height: 20,
//                     width: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
//                     ),
//                   )
//                       : const Icon(Icons.attach_file, size: 20),
//                 ),
//               ),
//               const SizedBox(width: 12),
//
//               // ✍️ Text input
//               Expanded(
//                 child: TextField(
//                   controller: _controller,
//                   focusNode: _focusNode,
//                   maxLines: null,
//                   decoration: const InputDecoration(
//                     hintText: 'Type or speak your message...',
//                     border: OutlineInputBorder(),
//                     contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//
//               // 🎤 Mic or Tick
//               _isListening
//                   ? GestureDetector(
//                 onTap: () {
//                   _speechService.stopListening();
//                   setState(() {
//                     _isListening = false;
//                     _isPreviewingSpeech = false;
//                   });
//                 },
//                 child: const CircleAvatar(
//                   backgroundColor: Colors.green,
//                   child: Icon(Icons.check, color: Colors.white),
//                 ),
//               )
//                   : GestureDetector(
//                 onTap: () async {
//                   await _initializeSpeech();
//                   setState(() {
//                     _isListening = true;
//                     _controller.clear();
//                   });
//                   await _speechService.startListening(onResultCallback: (text) {
//                     if (!mounted) return;
//                     setState(() {
//                       _controller.text = text;
//                       _controller.selection = TextSelection.fromPosition(
//                         TextPosition(offset: _controller.text.length),
//                       );
//                     });
//                   });
//                 },
//                 child: const CircleAvatar(
//                   backgroundColor: Colors.orange,
//                   child: Icon(Icons.mic, color: Colors.white),
//                 ),
//               ),
//
//               const SizedBox(width: 8),
//
//               // 📤 Send or Stop
//               GestureDetector(
//                 onTap: _isTyping ? _stopResponse : _sendMessage,
//                 child: CircleAvatar(
//                   radius: 18,
//                   backgroundColor: Colors.orange,
//                   child: Icon(
//                     _isTyping ? Icons.stop : Icons.arrow_upward,
//                     color: Colors.white,
//                     size: 18,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//
//   Widget _buildCollapsedInput() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Container(
//         height: 56,
//         padding: const EdgeInsets.symmetric(horizontal: 12),
//         decoration: BoxDecoration(
//           border: Border.all(color: Colors.black),
//           borderRadius: BorderRadius.circular(30),
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: TextField(
//                 controller: _controller,
//                 focusNode: _focusNode,
//                 decoration: const InputDecoration(
//                   hintText: 'Ask Anything',
//                   border: InputBorder.none,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),
//             GestureDetector(
//               onTap: _isListening ? _stopListening : _startListening,
//               child: Container(
//                 height: 36,
//                 width: 36,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color: _isListening ? Colors.red : Colors.grey,
//                   ),
//                 ),
//                 child: Icon(
//                   _isListening ? Icons.stop : Icons.mic_none_outlined,
//                   size: 20,
//                   color: _isListening ? Colors.red : null,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),
//             GestureDetector(
//               onTap: _isTyping ? _stopResponse : _sendMessage,
//               child: CircleAvatar(
//                 radius: 18,
//                 backgroundColor: Colors.orange,
//                 child: Icon(
//                   _isTyping ? Icons.stop : Icons.arrow_upward,
//                   color: Colors.white,
//                   size: 18,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//
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
//   return RichText(
//     text: TextSpan(
//       style: const TextStyle(
//         fontSize: 14.5,
//         color: Colors.black,
//         height: 1.6, // better line height
//       ),
//       children: spans,
//     ),
//   );
// }
//
// // Animated dot for typing indicator
// class AnimatedDot extends StatefulWidget {
//   final int delay;
//
//   const AnimatedDot({
//     Key? key,
//     this.delay = 0,
//   }) : super(key: key);
//
//   @override
//   State<AnimatedDot> createState() => _AnimatedDotState();
// }
//
// class _AnimatedDotState extends State<AnimatedDot> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     )..repeat(reverse: true);
//
//     _animation = Tween<double>(begin: 0, end: 6).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: Curves.easeInOut,
//       ),
//     );
//
//     // Add delay if specified
//     if (widget.delay > 0) {
//       Future.delayed(Duration(milliseconds: widget.delay), () {
//         if (mounted) {
//           _controller.forward();
//         }
//       });
//     } else {
//       _controller.forward();
//     }
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _animation,
//       builder: (context, child) {
//         return Container(
//           width: 8,
//           height: 8,
//           decoration: BoxDecoration(
//             color: Colors.grey.shade500,
//             borderRadius: BorderRadius.circular(4),
//             //transform: Matrix4.translationValues(0, -_animation.value / 2, 0),
//           ),
//         );
//       },
//     );
//   }
// }
//
// class VoiceWaveform extends StatefulWidget {
//   const VoiceWaveform({Key? key}) : super(key: key);
//
//   @override
//   State<VoiceWaveform> createState() => _VoiceWaveformState();
// }
//
// class _VoiceWaveformState extends State<VoiceWaveform>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late List<Animation<double>> _barAnimations;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     )..repeat(reverse: true);
//
//     _barAnimations = List.generate(5, (i) {
//       final start = i * 0.1;
//       final end = start + 0.4;
//       return Tween<double>(begin: 6, end: 20).animate(
//         CurvedAnimation(
//           parent: _controller,
//           curve: Interval(start, end, curve: Curves.easeInOut),
//         ),
//       );
//     });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: List.generate(_barAnimations.length, (index) {
//         return AnimatedBuilder(
//           animation: _controller,
//           builder: (_, __) => Container(
//             margin: const EdgeInsets.symmetric(horizontal: 2),
//             width: 4,
//             height: _barAnimations[index].value,
//             decoration: BoxDecoration(
//               color: Colors.orange,
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//         );
//       }),
//     );
//   }
// }
//




import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

// Import your existing chat service files
import '../../../models/chat_message.dart';
import '../../../models/chat_session.dart';
import '../../../services/chat_service.dart';
import '../../../services/speech_service.dart';
import '../../models/document_context.dart';
import '../../utils/file_helps.dart';

class ChatScreen extends StatefulWidget {
  final ChatSession session;
  final ChatService chatService;
  final void Function(int)? onNavigateToTab;

  const ChatScreen({
    Key? key,
    required this.session,
    required this.chatService,
    this.onNavigateToTab
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final SpeechService _speechService;
  final ScrollController _scrollController = ScrollController();
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

  // Main state variables for messages
  List<Map<String, Object>> messages = [];
  StreamSubscription<ChatMessage>? _streamSubscription;
  String _currentStreamingId = '';

  @override
  void initState() {
    super.initState();
_scrollToBottom();
    // Add a small delay to request focus to avoid keyboard issues
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });

    _focusNode.addListener(_onFocusChange);
    _speechService = SpeechService();
    _initializeSpeech();
    _loadSessionMessages();

    // Listen to session updates (in case new messages are added externally)
    widget.chatService.sessions.listen((sessions) {
      if (!mounted) return;

      try {
        final updatedSession = sessions.firstWhere(
              (s) => s.id == widget.session.id,
          orElse: () => widget.session,
        );

        // Reload messages
        _loadSessionMessages(updatedSession);
      } catch (e) {
        print('Error updating session : $e');
      }
    });

    // Listen for live streaming message updates
    // widget.chatService.currentMessageStream.listen((updatedMessage) {
    //   if (!mounted) return;
    //
    //   if (_currentStreamingId == updatedMessage.id) {
    //     final index = messages.indexWhere((m) =>
    //     m['role'] == 'bot' && m['id'] == updatedMessage.id);
    //
    //     if (index != -1 && mounted) {
    //       setState(() {
    //         messages[index] = {
    //           ...messages[index],
    //           'msg': updatedMessage.text as Object,
    //           'isComplete': updatedMessage.isComplete as Object,
    //         };
    //         if (updatedMessage.isComplete) {
    //           _isTyping = false;
    //           _showOnlyLatestDuringTyping = false; // Enable full scrolling after message is complete
    //         }
    //       });
    //
    //       _scrollToBottom();
    //     }
    //   }
    // }, onError: (e) {
    //   print('Stream listen error: $e');
    // });
  }

  // Convert from ChatSession messages to local UI format
  void _loadSessionMessages([ChatSession? session]) {
    if (!mounted) return;

    final messagesToLoad = session?.messages ?? widget.session.messages;

    setState(() {
      messages = messagesToLoad.map((chatMessage) {
        return {
          'id': chatMessage.id as Object,
          'role': (chatMessage.isUser ? 'user' : 'bot') as Object,
          'msg': chatMessage.text as Object,
          'isComplete': chatMessage.isComplete as Object,
        };
      }).toList();
    });
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

  // When typing, we'll show only the latest exchange
  List<Map<String, Object>> get _visibleMessages {
    if (_showOnlyLatestDuringTyping && messages.length > 2) {
      // Show only the latest user-bot exchange
      return messages.sublist(messages.length - 2);
    }

    // Show all messages by default
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
  //   FocusScope.of(context).unfocus();
  //   final userMessage = _controller.text.trim();
  //
  //   setState(() {
  //     messages.add({'role': 'user', 'msg': userMessage, 'isComplete': true});
  //     messages.add({'role': 'bot', 'msg': '', 'isComplete': false});
  //     _controller.clear();
  //     _isTyping = true;
  //     _showOnlyLatestDuringTyping = true; // Show only latest while message is being typed
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
  //     _streamSubscription?.cancel();
  //     _streamSubscription = responseStream.listen((message) {
  //       if (!mounted) return;
  //       _currentStreamingId = message.id;
  //
  //       final lastIndex = messages.length - 1;
  //       if (lastIndex >= 0 && messages[lastIndex]['role'] == 'bot') {
  //         setState(() {
  //           messages[lastIndex] = {
  //             ...messages[lastIndex],
  //             'id': message.id,
  //             'msg': message.text,
  //             'isComplete': message.isComplete,
  //           };
  //           if (message.isComplete) {
  //             _isTyping = false;
  //             _showOnlyLatestDuringTyping = false; // Enable full scrolling after message is complete
  //           }
  //         });
  //
  //         _scrollToBottom();
  //       }
  //     });
  //   } catch (e) {
  //     print("Error: $e");
  //   }
  // }



  void _sendMessage() async {
    if (!mounted || _controller.text.trim().isEmpty) return;

    final userMessage = _controller.text.trim();

    setState(() {
      messages.add({'role': 'user', 'msg': userMessage, 'isComplete': true});
      messages.add({'role': 'bot', 'msg': '', 'isComplete': false});
      _controller.clear();
      _isTyping = true;
      _showOnlyLatestDuringTyping = true;
    });

    _scrollToBottom();

    try {
      final responseStream = await widget.chatService.sendMessageWithStreaming(
        sessionId: widget.session.id,
        message: userMessage,
      );

      responseStream.listen((botMessage) {
        final lastIndex = messages.length - 1;
        if (lastIndex >= 0 && messages[lastIndex]['role'] == 'bot') {
          setState(() {
            messages[lastIndex] = {
              'role': 'bot',
              'msg': botMessage.text,
              'isComplete': true,
            };
            _isTyping = false;
            _showOnlyLatestDuringTyping = false;
          });
          _scrollToBottom();
        }
      });
    } catch (e) {
      print("❌ Error sending message: $e");
    }
  }


  // void _stopResponse() {
  //   try {
  //     _streamSubscription?.cancel();
  //     widget.chatService.stopResponse(
  //       widget.session.id,
  //       _currentStreamingId,
  //     );
  //   } catch (e) {
  //     print('Error stopping response: $e');
  //   }
  //
  //   if (mounted) {
  //     setState(() {
  //       final lastIndex = messages.length - 1;
  //       if (lastIndex >= 0) {
  //         messages[lastIndex] = {
  //           ...messages[lastIndex],
  //           'isComplete': true as Object,
  //         };
  //       }
  //       _isTyping = false;
  //       _showOnlyLatestDuringTyping = false; // Enable full scrolling after stopping response
  //     });
  //   }
  // }

  void _scrollToBottom() {
    // Add a slight delay to ensure rendering is complete
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageRow(Map<String, Object> msg) {
    if (msg['role'] == 'user') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () {},
              child: const Icon(Icons.edit, size: 18),
            ),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(msg['msg']?.toString() ?? ''),
              ),
            ),
          ],
        ),
      );
    } else {
      final msgStr = msg['msg']?.toString() ?? '';
      final isComplete = msg['isComplete'] == true;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: msgStr.isEmpty && !isComplete
            ? _buildTypingIndicator()
            : _buildStyledBotMessage(msgStr),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayMessages = _visibleMessages;

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
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.blue.withOpacity(0.1),
                child: const Center(
                  child: Text(
                    "Full chat will be available when response completes",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
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

            _buildInputFields(),

            // Add keyboard spacer
            if (_isKeyboardVisible)
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
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
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isListening)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: VoiceWaveform(),
              ),

            // Switch between normal TextField and recording bar
            _showSpeechBar
                ? Row(
              children: [
                GestureDetector(
                  onTap: () {
                    _speechTimer.stop();
                    _timer.cancel();
                    _speechService.stopListening();
                    if (mounted) {
                      setState(() {
                        _showSpeechBar = false;
                        _isListening = false;
                        _recognizedSpeech = '';
                      });
                    }
                  },
                  child: const Icon(Icons.close),
                ),
                const SizedBox(width: 12),
                Text(
                  _formattedDuration,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    _speechTimer.stop();
                    _timer.cancel();
                    _speechService.stopListening();
                    if (mounted) {
                      setState(() {
                        _controller.text = _recognizedSpeech;
                        _controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: _controller.text.length),
                        );
                        _showSpeechBar = false;
                        _isListening = false;
                      });

                      // Give focus back to text field
                      Future.delayed(Duration(milliseconds: 100), () {
                        if (mounted) {
                          FocusScope.of(context).requestFocus(_focusNode);
                        }
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
                : Column(
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
                    _buildCircleButton(
                      icon: _isProcessingDocument ? null : Icons.add,
                      isLoading: _isProcessingDocument,
                      onTap: () {
                        if (mounted) {
                          setState(() => _isProcessingDocument = true);
                          FileHelpers.pickAndProcessFile().then((result) {
                            if (mounted) {
                              setState(() => _isProcessingDocument = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result)),
                              );
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    const Spacer(),

                    // Mic Button
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
                            });
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),

                    (_controller.text.trim().isNotEmpty || _isTyping)
                        ? _buildCircleButton(
                        icon: _isTyping ? Icons.stop : Icons.arrow_upward,
                        onTap: () {
                          if (!mounted) return;

                          if (_isTyping) {
                            // _stopResponse();
                          } else {
                            _sendMessage();
                          }
                        }
                    )
                        : const SizedBox.shrink(),
                  ],
                )
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

Widget _buildStyledBotMessage(String fullText) {
  final lines = fullText.trim().split('\n');
  final regexBold = RegExp(r"\*\*(.+?)\*\*");

  List<InlineSpan> spans = [];

  for (var line in lines) {
    if (line.trim().isEmpty) {
      spans.add(const TextSpan(text: '\n')); // extra spacing
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

    // Apply bold styling if **text** exists
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

  return RichText(
    text: TextSpan(
      style: const TextStyle(
        fontSize: 14.5,
        color: Colors.black,
        height: 1.6, // better line height
      ),
      children: spans,
    ),
  );
}

// Animated dot for typing indicator
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