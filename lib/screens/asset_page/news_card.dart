import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../testpage.dart';


class NewsCard extends StatelessWidget {
  final String source;
  final String timeAgo;
  final String title;
  final String description;
  final Widget? trailingWidget;

  const NewsCard({
    Key? key,
    this.source = "ScoutQuest",
    this.timeAgo = "5 days",
    this.title = "Microsoft reveals 40 jobs about to be destroyed by AI – see the list?",
    this.description = "A Microsoft Research paper has listed out 40 professions it believes are most at risk from the rise of AI, as well as 40 professions that should be safe.",
    this.trailingWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source and time
          Text(
            '$source • $timeAgo',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7E7E7E),
              height: 1.2,
            ),
          ),

          const SizedBox(height: 12),

          // Title (with right padding for the orb)
          Container(
            padding: const EdgeInsets.only(right: 40),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.black,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            description,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF7E7E7E),
              height: 1.5,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedOrb(size: 20,)
            ],
          )
        ],
      ),
    );
  }
}
