import 'package:flutter/material.dart';
import '../../screens/presentation/stock_detail_screen.dart';
import '../../services/chat_service.dart';
import '../../testpage.dart';

class ChatNavigationHelper {
  static void handleAskVittyFromSelection({
    required BuildContext context,
    required String selectedText,
    required bool isThreadMode,
    required ChatService chatService,
    Function(String)? onAskVitty,
  }) {
    if (isThreadMode && onAskVitty != null) {
      onAskVitty(selectedText);
    } else {
      showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            VittyThreadSheet(
              onClose: (){},
          chatService: chatService,
          initialText: selectedText,
        ),
      );
    }
  }

  static void navigateToStockDetail({
    required BuildContext context,
    required String stockSymbol,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StockDetailPage(stockSymbol: stockSymbol,onClose: (){},stockName: stockSymbol,),
      ),
    );
  }
}