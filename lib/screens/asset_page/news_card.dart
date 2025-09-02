import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../services/theme_service.dart';
import '../../testpage.dart';


class NewsCard extends StatefulWidget {
  final String source;
  final String timeAgo;
  final String title;
  final String description;
  final Widget? trailingWidget;
  final int maxLines;

  const NewsCard({
    Key? key,
    this.source = "ScoutQuest",
    this.timeAgo = "5 days",
    this.title = "Microsoft reveals 40 jobs about to be destroyed by AI – see the list?",
    this.description = "A Microsoft Research paper has listed out 40 professions it believes are most at risk from the rise of AI, as well as 40 professions that should be safe.",
    this.trailingWidget,
    this.maxLines = 3, // Default collapsed lines
  }) : super(key: key);

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isTextOverflow = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start the fade animation immediately
    _animationController.forward();

    // Check text overflow after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTextOverflow();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkTextOverflow() {
    final textSpan = TextSpan(
      text: widget.description,
      style: const TextStyle(
        fontFamily: 'SF Pro',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Color(0xFF7E7E7E),
        height: 1.5,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: widget.maxLines,
    );

    // Use the actual available width (accounting for padding)
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 80; // Account for card padding and margins

    textPainter.layout(maxWidth: availableWidth);

    final hasOverflow = textPainter.didExceedMaxLines;

    if (hasOverflow != _isTextOverflow) {
      setState(() {
        _isTextOverflow = hasOverflow;
      });
    }
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.box,
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
            '${widget.source} • ${widget.timeAgo}',
            style: TextStyle(
              fontFamily: 'SF Pro',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: theme.text,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 12),

          // Title (with right padding for the orb)
          Container(
            padding: const EdgeInsets.only(right: 40),
            child: Text(
              widget.title,
              style: TextStyle(
                fontFamily: 'SF Pro',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.text,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Description with expandable functionality
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Text(
                  widget.description,
                  style: const TextStyle(
                    fontFamily: 'SF Pro',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF7E7E7E),
                    height: 1.5,
                  ),
                  maxLines: widget.maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
                secondChild: Text(
                  widget.description,
                  style: const TextStyle(
                    fontFamily: 'SF Pro',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF7E7E7E),
                    height: 1.5,
                  ),
                ),
              ),

              // Read More / Read Less button
              if (_isTextOverflow)
                GestureDetector(
                  onTap: _toggleExpansion,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      _isExpanded ? 'Read less' : 'Read more',
                      style: TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary, // iOS blue
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Orb positioned at bottom right
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedOrb(size: 20),
            ],
          ),
        ],
      ),
    );
  }
}


