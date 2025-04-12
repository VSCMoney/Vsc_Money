import 'package:flutter/material.dart';

import '../../constants/colors.dart';

class DotsIndicator extends StatelessWidget {
  final int currentPage;
  const DotsIndicator({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentPage == index ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: currentPage == index ? AppColors.primary : Colors.grey,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
