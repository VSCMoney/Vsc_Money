import 'package:flutter/material.dart';



class ChatUIHelper {
  static double calculateScrollAdjustment({
    required double chatHeight,
    required double latestUserMessageHeight,
  }) {
    double adjustment = chatHeight - 110;

    if (latestUserMessageHeight == 52) {
      adjustment = chatHeight - 110;
    } else if (latestUserMessageHeight == 82) {
      adjustment = chatHeight - 140;
    } else if (latestUserMessageHeight == 112) {
      adjustment = chatHeight - 170;
    } else if (latestUserMessageHeight == 142) {
      adjustment = chatHeight - 200;
    } else if (latestUserMessageHeight == 172) {
      adjustment = chatHeight - 230;
    }

    return adjustment;
  }

  static void updateTextFieldWithSuggestion({
    required TextEditingController controller,
    required String text,
    VoidCallback? onUpdate,
  }) {
    controller.text = text;
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    onUpdate?.call();
  }
}


// class ChatUIHelper {
//   static double calculateScrollAdjustment({
//     required double chatHeight,
//     required double latestUserMessageHeight,
//   }) {
//     double adjustment = chatHeight - 110;
//
//     if (latestUserMessageHeight == 52) {
//       adjustment = chatHeight - 110;
//     } else if (latestUserMessageHeight == 82) {
//       adjustment = chatHeight - 140;
//     } else if (latestUserMessageHeight == 112) {
//       adjustment = chatHeight - 170;
//     } else if (latestUserMessageHeight == 142) {
//       adjustment = chatHeight - 200;
//     } else if (latestUserMessageHeight == 172) {
//       adjustment = chatHeight - 230;
//     }
//
//     return adjustment;
//   }
//
//   static void updateTextFieldWithSuggestion({
//     required TextEditingController controller,
//     required String text,
//     VoidCallback? onUpdate,
//   }) {
//     controller.text = text;
//     controller.selection = TextSelection.fromPosition(
//       TextPosition(offset: text.length),
//     );
//     onUpdate?.call();
//   }
// }