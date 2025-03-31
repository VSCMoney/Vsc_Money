import 'package:flutter/material.dart';

import '../../constants/colors.dart';

class ToggleButtonsRow extends StatelessWidget {
  const ToggleButtonsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('Opportunity', style: TextStyle(color: Colors.black)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: const Text('Caution', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }
}
