import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vscmoney/constants/widgets.dart';
import 'package:vscmoney/testpage.dart';

class AddShortcutCard extends StatelessWidget {
  const AddShortcutCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final overlay = Overlay.of(context);
        final renderBox = context.findRenderObject() as RenderBox;
        final size = renderBox.size;
        final offset = renderBox.localToGlobal(Offset.zero);

        final entry = OverlayEntry(
          builder: (context) => Positioned(
            top: offset.dy + size.height + 8,
            left: offset.dx + size.width / 2 - 60,
            child: Material(
              color: Colors.transparent,
              child: ComingSoonTooltip(),
            ),
          ),
        );

        overlay.insert(entry);
        Future.delayed(const Duration(seconds: 2), () => entry.remove());
      },
      child: Container(
        height: 94,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF2F2F2F),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add, color: Colors.white, size: 20),
                SizedBox(width: 6),
                Text(
                  "Add Shortcut",
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white,fontSize: 16,fontFamily: 'SF Pro'),
                ),
              ],
            ),
            SizedBox(height: 2),
            Text(
              " Create your own quick prompt",
              style: TextStyle(fontSize: 14, color: Colors.white,fontFamily: "SF Pro"),
            ),
          ],
        ),
      ),
    );
  }
}