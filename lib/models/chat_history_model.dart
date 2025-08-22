// class ChatHistoryItem {
//   final String question;
//   final String answer;
//   final DateTime timestamp;
//
//   ChatHistoryItem({
//     required this.question,
//     required this.answer,
//     required this.timestamp,
//   });
//
//   factory ChatHistoryItem.fromJson(Map<String, dynamic> json) {
//     try {
//       return ChatHistoryItem(
//         question: json['question'] ?? '',  // Default to empty string if null
//         answer: json['answer'] ?? '',      // Default to empty string if null
//         timestamp: json['timestamp'] != null
//             ? DateTime.parse(json['timestamp'])
//             : DateTime.now(),              // Default to current time if null
//       );
//     } catch (e) {
//       print("Error parsing ChatHistoryItem: $e");
//       print("Problematic JSON: $json");
//       // Return a default item rather than crashing
//       return ChatHistoryItem(
//         question: json['question'] ?? 'Error loading question',
//         answer: json['answer'] ?? 'Error loading answer',
//         timestamp: DateTime.now(),
//       );
//     }
//   }}



// Updated ChatHistoryItem model to handle backend format
class ChatHistoryItem {
  final String question;
  final String answer;
  final String? author;  // Add author field

  ChatHistoryItem({
    required this.question,
    required this.answer,
    this.author,
  });

  factory ChatHistoryItem.fromJson(Map<String, dynamic> json) {
    print('🔍 ChatHistoryItem: Parsing JSON: $json');

    try {
      // ✅ Handle backend format with Author field
      if (json.containsKey('Author')) {
        // If it's individual message format
        final author = json['Author']?.toString().toLowerCase() ?? '';
        final content = json['Content']?.toString() ?? json['Message']?.toString() ?? '';

        // Create a pair based on the author
        if (author == 'user') {
          return ChatHistoryItem(
            question: content,
            answer: '', // Will be filled by next message
            author: author,
          );
        } else {
          return ChatHistoryItem(
            question: '', // Will be filled from previous message
            answer: content,
            author: author,
          );
        }
      }

      // Fallback to original format
      else if (json.containsKey('question') && json.containsKey('answer')) {
        return ChatHistoryItem(
          question: json['question']?.toString() ?? '',
          answer: json['answer']?.toString() ?? '',
        );
      }

      else {
        print('❌ Unknown JSON format: ${json.keys}');
        return ChatHistoryItem(question: '', answer: '');
      }
    } catch (e) {
      print('❌ Error parsing ChatHistoryItem: $e');
      return ChatHistoryItem(question: '', answer: '');
    }
  }
}
