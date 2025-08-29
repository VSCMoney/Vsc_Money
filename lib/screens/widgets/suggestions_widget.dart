import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/suggestion_data.dart';
import '../../services/theme_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SuggestionsWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String)? onAskVitty;
  final VoidCallback? onSuggestionSelected;

  const SuggestionsWidget({
    Key? key,
    required this.controller,
    this.onAskVitty,
    this.onSuggestionSelected,
  }) : super(key: key);

  void _selectSuggestion(BuildContext context, String text) {
    controller.text = text;
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    onSuggestionSelected?.call();
  }

  Widget _buildSuggestionChip({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String suggestionText,
    required double maxWidth,
  }) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: () => _selectSuggestion(context, suggestionText),
      child: Container(
        height: 200, // Same as original
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 7), // Same as original
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.gradient,
          ),
          color: theme.message,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              spreadRadius: 1,
              color: Colors.black.withOpacity(0.08),
              blurRadius: 3,
              offset: const Offset(3, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF Pro',
                    color: theme.text,
                    fontSize: 16,
                  ),
                  contextMenuBuilder: (context, editableTextState) {
                    final selection = editableTextState.textEditingValue.selection;
                    final text = editableTextState.textEditingValue.text;
                    final selectedText = selection.textInside(text);
                    return AdaptiveTextSelectionToolbar.buttonItems(
                      anchors: editableTextState.contextMenuAnchors,
                      buttonItems: [
                        ContextMenuButtonItem(
                          label: 'Ask Vitty 🤖',
                          onPressed: () {
                            Navigator.pop(context);
                            onAskVitty?.call(selectedText);
                          },
                        ),
                        ContextMenuButtonItem(
                          label: 'Copy',
                          onPressed: () {
                            Navigator.pop(context);
                            Clipboard.setData(ClipboardData(text: selectedText));
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.text,
                    fontFamily: "SF Pro",
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 94,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        children: [
          // Your exact quick chips...
          SizedBox(
            height: 100,
            child: _buildSuggestionChip(
              context: context,
              title: "Market News",
              subtitle: "What's happening in the market today?",
              suggestionText: "What's happening in the market today?",
              maxWidth: 220,
            ),
          ),
          const SizedBox(width: 16),
          _buildSuggestionChip(
            context: context,
            title: "My Portfolio",
            subtitle: "How's my portfolio doing?",
            suggestionText: "How's my portfolio doing?",
            maxWidth: 220,
          ),
          const SizedBox(width: 12),
          // AddShortcutCard(), // Uncomment if you have this widget
        ],
      ),
    );
  }
}