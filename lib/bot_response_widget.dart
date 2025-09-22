import 'package:flutter/material.dart';

import 'constants/chat_typing_indicator.dart';
import 'constants/widgets.dart';




class BotMessageWidget extends StatelessWidget {
  final Map<String, dynamic> message;

  const BotMessageWidget({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = message['content'] as String? ?? '';
    final isComplete = message['isComplete'] as bool? ?? false;
    final currentStatus = message['currentStatus'] as String?;
    final tableData = message['tableData'] as Map<String, dynamic>?;

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: BotMessageContentWidget(
              content: content,
              isComplete: isComplete,
              currentStatus: currentStatus,
              tableData: tableData,
            ),
          ),
        ],
      ),
    );
  }
}


class BotMessageContentWidget extends StatelessWidget {
  final String content;
  final bool isComplete;
  final String? currentStatus;
  final Map<String, dynamic>? tableData;

  const BotMessageContentWidget({
    Key? key,
    required this.content,
    required this.isComplete,
    this.currentStatus,
    this.tableData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (currentStatus != null && !isComplete)
            StatusIndicatorWidget(status: currentStatus!),

          if (!isComplete && content.isEmpty && currentStatus == null)
            const TypingIndicatorWidget(),

          if (content.isNotEmpty) ...[
            if (currentStatus != null) const SizedBox(height: 8),
            MessageTextWidget(content: content),
          ],

          if (tableData != null) ...[
            if (content.isNotEmpty || currentStatus != null)
              const SizedBox(height: 12),
            SimpleTableWidget(tableData: tableData!),
          ],
        ],
      ),
    );
  }
}


class StatusIndicatorWidget extends StatelessWidget {
  final String status;

  const StatusIndicatorWidget({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PremiumShimmerWidget(
      text: status,
      isComplete: false,
      baseColor: const Color(0xFF9CA3AF),
      highlightColor: const Color(0xFF6B7280),
    );
  }
}


class MessageTextWidget extends StatelessWidget {
  final String content;

  const MessageTextWidget({Key? key, required this.content}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      content,
      style: const TextStyle(
        fontSize: 16,
        height: 1.4,
        color: Colors.black87,
      ),
    );
  }
}


class SimpleTableWidget extends StatelessWidget {
  final Map<String, dynamic> tableData;

  const SimpleTableWidget({Key? key, required this.tableData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final heading = tableData['heading'] as String?;
    final rows = tableData['rows'] as List?;

    if (rows == null || rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (heading != null) TableHeaderWidget(heading: heading),
          TableRowsWidget(rows: rows),
        ],
      ),
    );
  }
}


class TableHeaderWidget extends StatelessWidget {
  final String heading;

  const TableHeaderWidget({Key? key, required this.heading}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          heading,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}


class TableRowsWidget extends StatelessWidget {
  final List rows;

  const TableRowsWidget({Key? key, required this.rows}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows.map((row) {
        if (row is Map) {
          return TableRowWidget(row: row);
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }
}

class TableRowWidget extends StatelessWidget {
  final Map row;

  const TableRowWidget({Key? key, required this.row}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        children: row.entries.map<Widget>((entry) {
          return Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 2),
            child: Text(
              '${entry.key}: ${entry.value}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}