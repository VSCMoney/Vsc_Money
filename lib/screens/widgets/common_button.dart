import 'package:flutter/material.dart';

import '../../constants/colors.dart';

class CommonButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? label;
  final Widget? child;

  const CommonButton({
    super.key,
    this.onPressed,
    this.label,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      width: screenWidth,
      height: screenHeight * 0.060,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
         // padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onPressed,
        child: child ??
            Text(
              label ?? '',
              style: TextStyle(
                fontSize: screenWidth * 0.045, // Responsive font size
                color: Colors.white,
                fontFamily: 'SF Pro'
              ),
            ),
      ),
    );
  }
}

