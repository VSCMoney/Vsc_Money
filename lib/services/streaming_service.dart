// lib/services/streaming_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../constants/keys.dart' as ApiConstants;
import '../models/chat_message.dart';
import '../screens/models/document_context.dart';


// class StreamingService {
//   bool _isGeneratingResponse = false;
//   StreamController<void> _stopSignalController = StreamController<void>();
//
//   // Stream simulation for ChatGPT-like streaming responses
//   Stream<String> simulateResponseStream(String fullResponse) async* {
//     // Break the response into words
//     final words = fullResponse.split(' ');
//     String currentText = '';
//
//     // Yield word by word with random tiny delays to simulate typing
//     for (var word in words) {
//       currentText += (currentText.isEmpty ? '' : ' ') + word;
//       yield currentText;
//
//       // Random delay between 50ms and 200ms
//       await Future.delayed(Duration(
//           milliseconds: 50 +
//               (150 *
//                   (0.2 +
//                       0.8 *
//                           (DateTime.now().millisecondsSinceEpoch % 10) /
//                           10))
//                   .round()));
//     }
//   }
//
//   Stream<String> getStreamingAiResponse(
//       String userMessage,
//       List<ChatMessage> conversation, {
//         String systemInstruction =
//         "You are an AI assistant specializing in investment advisory for India. Provide fact-based insights and always ask follow up question.Be the most friendly AI financial advisor there is.",
//
//         //String systemInstruction = "You are the most rude guy there is and also a rapper",
//         double temperature = 0.7,
//         int maxTokens = 1000,
//       }) async* {
//     if (ApiConstants.geminiApiKey.isEmpty) {
//       yield "Error: Gemini API key is missing.";
//       return;
//     }
//
//     final apiUrl =
//         "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro:generateContent?key=${ApiConstants.geminiApiKey}";
//
//     final List<Map<String, Object>> contents = [];
//
//     // Combine system instruction + document context
//     String combinedSystemPrompt = systemInstruction;
//
//     if (documentContext.hasDocument &&
//         documentContext.extractedText.trim().isNotEmpty) {
//       combinedSystemPrompt += """
//
// 📂 **A document has been uploaded. Prioritize this document's content for answering user queries.**
//
// **Document Content:**
// ${documentContext.extractedText}
//
// **Document Summary:**
// ${documentContext.documentSummary}
// """;
//     }
//
//     // Add combined system prompt
//     contents.add({
//       "role": "model",
//       "parts": [
//         {"text": combinedSystemPrompt}
//       ]
//     });
//
//     // Add conversation history
//     for (var msg in conversation) {
//       if (msg.text.trim().isNotEmpty) {
//         contents.add({
//           "role": msg.isUser ? "user" : "model",
//           "parts": [
//             {"text": msg.text}
//           ]
//         });
//       }
//     }
//
//     // Add latest user input
//     if (userMessage.trim().isNotEmpty) {
//       contents.add({
//         "role": "user",
//         "parts": [
//           {"text": userMessage}
//         ]
//       });
//     } else {
//       yield "Error: Empty user message.";
//       return;
//     }
//
//     final requestBody = {
//       "contents": contents,
//       "generationConfig": {
//         "temperature": temperature,
//         "maxOutputTokens": maxTokens,
//         "topP": 1.0,
//         "topK": 40,
//         "stopSequences": []
//       }
//     };
//
//     _isGeneratingResponse = true;
//     _stopSignalController = StreamController<void>();
//
//     try {
//       final response = await http.post(
//         Uri.parse(apiUrl),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(requestBody),
//       );
//
//       if (response.statusCode == 200) {
//         final jsonResponse = jsonDecode(response.body);
//         final candidates = jsonResponse["candidates"] ?? [];
//
//         if (candidates.isEmpty) {
//           yield "No response from Gemini.";
//           return;
//         }
//
//         String fullText = candidates[0]["content"]["parts"][0]["text"] ?? "";
//
//         // Streaming typing effect
//         String accumulated = "";
//         for (int i = 0; i < fullText.length; i++) {
//           if (!_isGeneratingResponse || _stopSignalController.isClosed) break;
//
//           accumulated += fullText[i];
//           yield accumulated;
//
//           await Future.delayed(const Duration(milliseconds: 25));
//         }
//
//         if (_isGeneratingResponse) {
//           yield fullText;
//         }
//       } else {
//         final errorMsg =
//             "Error: ${response.statusCode} - ${response.reasonPhrase}";
//         yield errorMsg;
//         print("Gemini API Error: ${response.body}");
//       }
//     } catch (e) {
//       yield "Error: Failed to connect to Gemini API - ${e.toString()}";
//     } finally {
//       _isGeneratingResponse = false;
//       if (!_stopSignalController.isClosed) {
//         _stopSignalController.close();
//       }
//     }
//   }
//
//   Stream<String> getDocumentAnalysisResponse(
//       String userQuestion,
//       List<ChatMessage> chatHistory) async* {
//     if (ApiConstants.geminiApiKey.isEmpty) {
//       yield "Error: Gemini API key is missing.";
//       return;
//     }
//
//     // Use the more powerful model for document analysis
//     final apiUrl =
//         "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0:generateContent?key=${ApiConstants.geminiApiKey}";
//
//     final List<Map<String, Object>> history = [];
//
//     // Updated system prompt for document analysis
//     String systemPrompt =
//         "You are a document analysis assistant. You help analyze and answer questions about documents.";
//
//     // Add context about the document if available
//     if (documentContext.hasDocument) {
//       systemPrompt +=
//           "\n\nDOCUMENT CONTENT:\n${documentContext.extractedText}\n\n" +
//               "DOCUMENT SUMMARY:\n${documentContext.documentSummary}";
//     } else {
//       yield "No document has been processed. Please upload a document first.";
//       return;
//     }
//
//     history.add({
//       "role": "model",
//       "parts": [
//         {"text": systemPrompt}
//       ]
//     });
//
//     // Add chat history (excluding system prompt)
//     for (var msg in chatHistory.where((msg) => msg.text.trim().isNotEmpty)) {
//       history.add({
//         "role": msg.isUser ? "user" : "model",
//         "parts": [
//           {"text": msg.text}
//         ]
//       });
//     }
//
//     // Add the user's current question about the document
//     if (userQuestion.trim().isNotEmpty) {
//       history.add({
//         "role": "user",
//         "parts": [
//           {"text": "Based on the document I uploaded, $userQuestion"}
//         ]
//       });
//     } else {
//       yield "Please ask a question about the uploaded document.";
//       return;
//     }
//
//     final Map<String, Object> requestBody = {
//       "contents": history,
//       "generationConfig": {
//         "temperature": 0.3, // Lower temperature for more factual responses
//         "maxOutputTokens": 1000 // Increased limit for document analysis
//       }
//     };
//
//     _isGeneratingResponse = true;
//     _stopSignalController = StreamController<void>();
//
//     try {
//       final response = await http.post(
//         Uri.parse(apiUrl),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(requestBody),
//       );
//
//       if (response.statusCode == 200) {
//         final jsonResponse = jsonDecode(response.body);
//         final candidates = jsonResponse["candidates"] ?? [];
//
//         if (candidates.isEmpty) {
//           yield "No response from Gemini for document analysis.";
//           return;
//         }
//
//         String fullText = candidates[0]["content"]["parts"][0]["text"] ?? "";
//
//         // Save full response in conversation history
//         chatHistory.add(ChatMessage(
//           id: DateTime.now().millisecondsSinceEpoch.toString(),
//           text: fullText,
//           isUser: false,
//           timestamp: DateTime.now(),
//         ));
//
//         // Stream the response word-by-word with no interruptions
//         String accumulatedResponse = "";
//         final words = fullText.split(" ");
//
//         for (int i = 0; i < words.length; i++) {
//           if (!_isGeneratingResponse || _stopSignalController.isClosed) break;
//
//           accumulatedResponse += "${words[i]} ";
//           yield accumulatedResponse.trim();
//
//           await Future.delayed(const Duration(milliseconds: 50));
//
//           if (_stopSignalController.hasListener) {
//             bool shouldBreak = false;
//             try {
//               await for (var _ in _stopSignalController.stream.take(1)) {
//                 _isGeneratingResponse = false;
//                 shouldBreak = true;
//                 break;
//               }
//             } catch (e) {
//               print("Stream error: $e");
//             }
//             if (shouldBreak) break;
//           }
//         }
//
//         if (_isGeneratingResponse) {
//           yield fullText;
//         }
//       } else {
//         final errorMsg =
//             "Error: ${response.statusCode} - ${response.reasonPhrase}";
//         yield errorMsg;
//         print("Gemini API Error: ${response.body}");
//       }
//     } catch (e) {
//       final errorMsg =
//           "Error: Failed to connect to Gemini API - ${e.toString()}";
//       yield errorMsg;
//       print("Exception: $e");
//     } finally {
//       _isGeneratingResponse = false;
//       if (!_stopSignalController.isClosed) {
//         _stopSignalController.close();
//       }
//     }
//   }
//
//   Future<String> handleDocumentQuestion(
//       String userQuestion, List<ChatMessage> conversation) async {
//     if (!documentContext.hasDocument) {
//       return "Please upload a document first.";
//     }
//
//     // Create a StreamController to collect the responses
//     final controller = StreamController<String>();
//     String fullResponse = "";
//
//     // Subscribe to the stream - pass conversation as a parameter
//     getStreamingAiResponse(
//       userQuestion,
//       conversation,
//     ).listen((response) {
//       fullResponse = response;
//       controller.add(response);
//     }, onDone: () {
//       controller.close();
//     }, onError: (e) {
//       controller.add("Error: $e");
//       controller.close();
//     });
//
//     // Wait for the stream to complete and return the final response
//     await controller.stream.last;
//     return fullResponse;
//   }
//
//   void stopResponse() {
//     _isGeneratingResponse = false;
//
//     // Cancel the stream signal
//     if (!_stopSignalController.isClosed) {
//       _stopSignalController.add(null);
//       _stopSignalController.close();
//     }
//   }
// }