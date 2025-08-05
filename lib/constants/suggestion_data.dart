// Create suggestion_model.dart
import 'package:flutter/cupertino.dart';

class SuggestionData {
  final String title;
  final String subtitle;
  final String suggestionText;
  final IconData? icon;
  final String? category;

  const SuggestionData({
    required this.title,
    required this.subtitle,
    required this.suggestionText,
    this.icon,
    this.category,
  });
}

// Pre-defined suggestions
class SuggestionConstants {
  static const List<SuggestionData> defaultSuggestions = [
    SuggestionData(
      title: "Market News",
      subtitle: "What's happening in the market today?",
      suggestionText: "What's happening in the market today?",
      category: "news",
    ),
    SuggestionData(
      title: "My Portfolio",
      subtitle: "How's my portfolio doing?",
      suggestionText: "How's my portfolio doing?",
      category: "portfolio",
    ),
  ];
}