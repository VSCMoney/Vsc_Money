import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../services/theme_service.dart';
import '../../testpage.dart';



class ForYouCard extends StatelessWidget {
  final String title;
  final String content;

  const ForYouCard({
    Key? key,
    this.title = "For you",
    this.content = "Microsoft is currently trading at ₹1,821.45, near its 52-week high, showing positive momentum. Over the last month, the stock gained 5.2% driven by strong quarterly earnings and increased interest in its AI initiatives.",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Subtle gradient background matching the image
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF1EAE4), // Slightly darker warm beige
            Color(0xFFFFFFFF), // Even more subtle variation
          ],
          stops: [0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF734012), // Warm brown color
                  height: 1.2,
                ),
              ),

              SizedBox(height: 12),

              // Content text
              Text(
                content,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.black, // Dark gray for readability
                  height: 1.5,
                ),
              ),
              SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedOrb(size: 20,),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}