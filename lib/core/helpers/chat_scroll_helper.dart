import 'package:flutter/material.dart';

class ChatScrollHelper {
  static void scrollToLatestLikeChatPage({
    required ScrollController scrollController,
    required double chatHeight,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;

      final offset = scrollController.offset;
      var targetOffset = (offset + chatHeight).clamp(
        scrollController.position.minScrollExtent,
        scrollController.position.maxScrollExtent,
      );

      scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  static void scrollToMaxExtent(ScrollController scrollController) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  static void handleKeyboardScroll(ScrollController scrollController) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }
}