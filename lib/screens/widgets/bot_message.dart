import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/widgets.dart';
import '../../models/chat_message.dart';
import '../../services/locator.dart';
import '../../services/theme_service.dart';

// class BotMessageWidget extends StatelessWidget {
//   final String message;
//   final bool isComplete;
//   final bool isLatest;
//   final Function(String)? onAskVitty;
//
//   const BotMessageWidget({
//     Key? key,
//     required this.message,
//     required this.isComplete,
//     this.isLatest = false,
//     this.onAskVitty,
//   }) : super(key: key);
//
//   List<TextSpan> _processTextWithFormatting(String text, TextStyle baseStyle) {
//     final regexBold = RegExp(r"\*\*(.+?)\*\*");
//     List<TextSpan> spans = [];
//     int lastMatchEnd = 0;
//
//     for (var match in regexBold.allMatches(text)) {
//       if (match.start > lastMatchEnd) {
//         spans.add(
//           TextSpan(
//             text: text.substring(lastMatchEnd, match.start),
//             style: baseStyle,
//           ),
//         );
//       }
//
//       spans.add(
//         TextSpan(
//           text: match.group(1),
//           style: baseStyle.copyWith(
//             fontWeight: FontWeight.w700,
//             height: 1.5,
//             fontFamily: "SF Pro Text",
//           ),
//         ),
//       );
//
//       lastMatchEnd = match.end;
//     }
//
//     if (lastMatchEnd < text.length) {
//       spans.add(TextSpan(text: text.substring(lastMatchEnd), style: baseStyle));
//     }
//
//     return spans;
//   }
//
//   List<TextSpan> _buildFormattedSpans(String fullText, TextStyle baseStyle) {
//     final lines = fullText.trim().split('\n');
//     List<TextSpan> spans = [];
//
//     for (var line in lines) {
//       if (line.trim().isEmpty) {
//         spans.add(const TextSpan(text: '\n'));
//         continue;
//       }
//
//       // Add emoji based on line content
//       String emoji = '';
//       if (line.trim().startsWith(RegExp(r"^(\*|•|-|\d+\.)\s"))) {
//         emoji = '👉 ';
//       } else if (line.contains('Tip') || line.contains('Note')) {
//         emoji = '💡 ';
//       } else if (line.contains('Save') || line.contains('budget')) {
//         emoji = '💰 ';
//       }
//
//       spans.add(TextSpan(text: '\n$emoji'));
//       spans.addAll(_processTextWithFormatting(line, baseStyle));
//     }
//
//     return spans;
//   }
//
//   Widget _buildContextMenu(BuildContext context, EditableTextState editableTextState) {
//     final value = editableTextState.textEditingValue;
//     final selection = value.selection;
//
//     if (!selection.isValid || selection.isCollapsed) {
//       return const SizedBox.shrink();
//     }
//
//     final selectedText = value.text.substring(selection.start, selection.end);
//
//     return AdaptiveTextSelectionToolbar(
//       anchors: editableTextState.contextMenuAnchors,
//       children: [
//         if (onAskVitty != null)
//           TextButton(
//             onPressed: () {
//               onAskVitty!(selectedText);
//               ContextMenuController.removeAny();
//             },
//             style: TextButton.styleFrom(
//               foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text('Ask Vitty'),
//                 const SizedBox(width: 8),
//                 Image.asset(
//                   'assets/images/vitty.png',
//                   width: 20,
//                   height: 20,
//                 ),
//               ],
//             ),
//           ),
//         TextButton(
//           onPressed: () {
//             Clipboard.setData(ClipboardData(text: selectedText));
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Copied!')),
//             );
//             ContextMenuController.removeAny();
//           },
//           child: const Text('Copy', style: TextStyle(color: Colors.black)),
//         ),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = locator<ThemeService>().currentTheme;
//
//     final style = TextStyle(
//       fontFamily: 'DM Sans',
//       fontSize: 16,
//       fontWeight: FontWeight.w500,
//       height: 1.75,
//       color: theme.text,
//     );
//
//     final spans = _buildFormattedSpans(message, style);
//
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 4, top: 2),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SelectableText.rich(
//             TextSpan(style: style, children: spans),
//             contextMenuBuilder: _buildContextMenu,
//           ),
//           const SizedBox(height: 15),
//           _buildActionButtons(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildActionButtons() {
//     return Row(
//       children: [
//         _AnimatedActionButton(
//           icon: Icons.copy,
//           size: 14,
//           isVisible: isComplete,
//         ),
//         const SizedBox(width: 12),
//         _AnimatedActionButton(
//           icon: Icons.thumb_up_alt_outlined,
//           size: 16,
//           isVisible: isComplete,
//         ),
//         const SizedBox(width: 12),
//         _AnimatedActionButton(
//           icon: Icons.thumb_down_alt_outlined,
//           size: 16,
//           isVisible: isComplete,
//         ),
//       ],
//     );
//   }
// }
//
// class _AnimatedActionButton extends StatelessWidget {
//   final IconData icon;
//   final double size;
//   final bool isVisible;
//
//   const _AnimatedActionButton({
//     required this.icon,
//     required this.size,
//     required this.isVisible,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Visibility(
//       visible: true,
//       maintainSize: true,
//       maintainAnimation: true,
//       maintainState: true,
//       child: AnimatedOpacity(
//         duration: const Duration(milliseconds: 300),
//         opacity: isVisible ? 1 : 0,
//         child: Icon(
//           icon,
//           size: size,
//           color: Colors.grey,
//         ),
//       ),
//     );
//   }
// }



// STEP 1: Replace your existing BotMessageWidget with this enhanced version

class BotMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final Function(String)? onAskVitty;
  final Function(String)? onStockTap;

  const BotMessageWidget({
    Key? key,
    required this.message,
    this.onAskVitty,
    this.onStockTap,
  }) : super(key: key);

  List<TextSpan> _processTextWithFormatting(String text, TextStyle baseStyle) {
    final regexBold = RegExp(r"\*\*(.+?)\*\*");
    List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    for (var match in regexBold.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: baseStyle,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: match.group(1),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.5,
            fontFamily: "SF Pro Text",
          ),
        ),
      );

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd), style: baseStyle));
    }

    return spans;
  }

  List<TextSpan> _buildFormattedSpans(String fullText, TextStyle baseStyle) {
    final lines = fullText.trim().split('\n');
    List<TextSpan> spans = [];

    for (var line in lines) {
      if (line.trim().isEmpty) {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      String emoji = '';
      if (line.trim().startsWith(RegExp(r"^(\*|•|-|\d+\.)\s"))) {
        emoji = '👉 ';
      } else if (line.contains('Tip') || line.contains('Note')) {
        emoji = '💡 ';
      } else if (line.contains('Save') || line.contains('budget')) {
        emoji = '💰 ';
      }

      spans.add(TextSpan(text: '\n$emoji'));
      spans.addAll(_processTextWithFormatting(line, baseStyle));
    }

    return spans;
  }

  // Helper method to extract text content from table data
  String _extractTableText(Map<String, dynamic> data) {
    final headers = data['headers'] as List<String>? ?? [];
    final rows = data['rows'] as List<List<String>>? ?? [];

    if (headers.isEmpty || rows.isEmpty) {
      return 'Invalid table data';
    }

    String tableText = headers.join('\t') + '\n';
    for (var row in rows) {
      tableText += row.join('\t') + '\n';
    }

    return tableText;
  }

  // Helper method to extract text from key-value data
  String _extractKeyValueText(Map<String, dynamic> data) {
    final displayData = Map<String, dynamic>.from(data);
    displayData.remove('display_type');

    String text = '';
    for (var entry in displayData.entries) {
      text += '${entry.key}: ${entry.value}\n';
    }

    return text;
  }

  Widget _buildTableView(Map<String, dynamic> data, dynamic theme) {
    final headers = data['headers'] as List<String>? ?? [];
    final rows = data['rows'] as List<List<String>>? ?? [];

    if (headers.isEmpty || rows.isEmpty) {
      return SelectableText(
        'Invalid table data',
        style: TextStyle(
          color: theme.text,
          fontFamily: 'DM Sans',
        ),
        contextMenuBuilder: _buildContextMenu,
      );
    }

    final isStockTable = headers.isNotEmpty &&
        headers.first.toLowerCase().contains('stock');

    // Create a selectable table using Column and Row layout
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.text.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            decoration: BoxDecoration(
              color: theme.text.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: headers.asMap().entries.map((entry) {
                  final isLast = entry.key == headers.length - 1;
                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: isLast
                              ? BorderSide.none
                              : BorderSide(color: theme.text.withOpacity(0.2)),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(
                          entry.value,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'DM Sans',
                            color: theme.text,
                          ),
                          contextMenuBuilder: _buildContextMenu,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Data rows
          ...rows.asMap().entries.map((rowEntry) {
            final rowIndex = rowEntry.key;
            final row = rowEntry.value;
            final isLastRow = rowIndex == rows.length - 1;

            return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: isLastRow
                      ? BorderSide.none
                      : BorderSide(color: theme.text.withOpacity(0.2)),
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: row.asMap().entries.map((cellEntry) {
                    final columnIndex = cellEntry.key;
                    final cellValue = cellEntry.value;
                    final isLastColumn = columnIndex == row.length - 1;

                    return Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: isLastColumn
                                ? BorderSide.none
                                : BorderSide(color: theme.text.withOpacity(0.2)),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: isStockTable && columnIndex == 0 && onStockTap != null
                              ? GestureDetector(
                            onTap: () {
                              print("🔍 Stock tapped: $cellValue");
                              onStockTap!(cellValue);
                            },
                            child: SelectableText(
                              cellValue,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'DM Sans',
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.blue[700],
                              ),
                              contextMenuBuilder: _buildContextMenu,
                            ),
                          )
                              : SelectableText(
                            cellValue,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'DM Sans',
                              color: theme.text,
                            ),
                            contextMenuBuilder: _buildContextMenu,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Context menu builder for SelectableText
  Widget _buildContextMenu(BuildContext context, EditableTextState editableTextState) {
    final value = editableTextState.textEditingValue;
    final selection = value.selection;

    if (!selection.isValid || selection.isCollapsed) {
      return const SizedBox.shrink();
    }

    final selectedText = value.text.substring(selection.start, selection.end);

    return AdaptiveTextSelectionToolbar(
      anchors: editableTextState.contextMenuAnchors,
      children: [
        if (onAskVitty != null)
          TextButton(
            onPressed: () {
              onAskVitty!(selectedText);
              ContextMenuController.removeAny();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Ask Vitty'),
                const SizedBox(width: 8),
                Image.asset(
                  'assets/images/vitty.png',
                  width: 20,
                  height: 20,
                ),
              ],
            ),
          ),
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: selectedText));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied!')),
            );
            ContextMenuController.removeAny();
          },
          child: const Text('Copy', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = locator<ThemeService>().currentTheme;

    final style = TextStyle(
      fontFamily: 'DM Sans',
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.75,
      color: theme.text,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.statusUpdates.isNotEmpty)
            _buildStatusUpdates(theme),

          if (message.payloads.isNotEmpty)
            _buildResponsePayloads(theme, style),

          if (message.text.isNotEmpty && message.payloads.isEmpty)
            SelectableText.rich(
              TextSpan(
                style: style,
                children: _buildFormattedSpans(message.text, style),
              ),
              contextMenuBuilder: _buildContextMenu,
            ),

          const SizedBox(height: 15),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusUpdates(dynamic theme) {
    if (message.statusUpdates.isEmpty || message.payloads.isNotEmpty) {
      return SizedBox.shrink();
    }

    StatusUpdate currentStatus;
    final incompleteStatuses = message.statusUpdates.where((s) => !s.isComplete).toList();
    if (incompleteStatuses.isNotEmpty) {
      currentStatus = incompleteStatuses.last;
    } else {
      currentStatus = message.statusUpdates.last;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(animation),
            child: child,
          );
        },
        child: _buildCurrentStatusItem(currentStatus, theme),
      ),
    );
  }

  Widget _buildCurrentStatusItem(StatusUpdate status, dynamic theme) {
    return Container(
      key: ValueKey(status.id),
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 30),
        child: StatusUpdateWidget(
          statusUpdates: [status],
          theme: theme,
        ),
      ),
    );
  }

  Widget _buildResponsePayloads(dynamic theme, TextStyle style) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: message.payloads.map((payload) {
        return AnimatedPayloadRenderer(
          key: ValueKey('payload_${payload.id}'),
          payload: payload,
          theme: theme,
          style: style,
          onStockTap: onStockTap, // ENSURE THIS IS PASSED
          contextMenuBuilder: _buildContextMenu,
          messageId: message.id,
        );
      }).toList(),
    );
  }

  Widget _buildPayloadRenderer(ResponsePayload payload, dynamic theme, TextStyle style) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (payload.title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SelectableText(
                payload.title!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'DM Sans',
                  color: theme.text,
                ),
                contextMenuBuilder: _buildContextMenu,
              ),
            ),
          if (payload.description != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SelectableText(
                payload.description!,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'DM Sans',
                  color: theme.text.withOpacity(0.7),
                ),
                contextMenuBuilder: _buildContextMenu,
              ),
            ),
          _renderPayloadContent(payload, theme, style),
        ],
      ),
    );
  }

  Widget _renderPayloadContent(ResponsePayload payload, dynamic theme, TextStyle style) {
    switch (payload.type) {
      case PayloadType.text:
        return SelectableText.rich(
          TextSpan(
            style: style,
            children: _buildFormattedSpans(payload.data, style),
          ),
          contextMenuBuilder: _buildContextMenu,
        );
      case PayloadType.json:
        return _buildJsonPayload(payload.data, theme);
      case PayloadType.chart:
        return _buildChartPayload(payload.data, theme);
    }
  }

  Widget _buildJsonPayload(Map<String, dynamic> data, dynamic theme) {
    final displayType = data['display_type'] as String?;

    if (displayType == 'table') {
      return _buildTableView(data, theme);
    } else {
      return _buildKeyValueView(data, theme);
    }
  }

  Widget _buildKeyValueView(Map<String, dynamic> data, dynamic theme) {
    final displayData = Map<String, dynamic>.from(data);
    displayData.remove('display_type');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.text.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.text.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: displayData.entries.map((entry) =>
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: SelectableText.rich(
                TextSpan(
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 14,
                    fontFamily: 'DM Sans',
                  ),
                  children: [
                    TextSpan(
                      text: '${entry.key}: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: entry.value.toString()),
                  ],
                ),
                contextMenuBuilder: _buildContextMenu,
              ),
            ),
        ).toList(),
      ),
    );
  }

  Widget _buildChartPayload(dynamic data, dynamic theme) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.blue),
            const SizedBox(height: 8),
            SelectableText(
              'Chart will be rendered here',
              style: TextStyle(
                color: theme.text,
                fontFamily: 'DM Sans',
              ),
              contextMenuBuilder: _buildContextMenu,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        _AnimatedActionButton(
          icon: Icons.copy,
          size: 14,
          isVisible: message.isComplete,
        ),
        const SizedBox(width: 12),
        _AnimatedActionButton(
          icon: Icons.thumb_up_alt_outlined,
          size: 16,
          isVisible: message.isComplete,
        ),
        const SizedBox(width: 12),
        _AnimatedActionButton(
          icon: Icons.thumb_down_alt_outlined,
          size: 16,
          isVisible: message.isComplete,
        ),
      ],
    );
  }
}
// Keep your existing _AnimatedActionButton class unchanged
class _AnimatedActionButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool isVisible;

  const _AnimatedActionButton({
    required this.icon,
    required this.size,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: true,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isVisible ? 1 : 0,
        child: Icon(
          icon,
          size: size,
          color: Colors.grey,
        ),
      ),
    );
  }
}
