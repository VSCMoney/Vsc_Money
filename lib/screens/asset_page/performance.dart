import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../services/theme_service.dart';


class PerformanceSection extends StatelessWidget {
  final double currentPrice;
  final double todayLow;
  final double todayHigh;
  final double weekLow52;
  final double weekHigh52;
  final double openPrice;
  final double prevClose;
  final String volume;
  final double lowerCircuit;
  final double upperCircuit;

  const PerformanceSection({
    Key? key,
    this.currentPrice = 210.54,
    this.todayLow = 210.54,
    this.todayHigh = 216.00,
    this.weekLow52 = 210.54,
    this.weekHigh52 = 216.00,
    this.openPrice = 210.54,
    this.prevClose = 210.54,
    this.volume = "60,62,086",
    this.lowerCircuit = 210.54,
    this.upperCircuit = 210.54,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(0), // No border radius for full width
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Title
          Text(
            'Performance',
            style: TextStyle(
              fontFamily: 'SF Pro',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.text,
            ),
          ),

          SizedBox(height: 30),

          // Today's Range
          _buildPriceRange(
            "Today's low",
            "Today's high",
            todayLow,
            todayHigh,
            currentPrice,
            context
          ),

          SizedBox(height: 40),

          // 52 Week Range
          _buildPriceRange(
            "52 week low",
            "52 week high",
            weekLow52,
            weekHigh52,
            currentPrice,
            context
          ),

          SizedBox(height: 40),

          // Price Data Grid (2x3)
          Column(
            children: [
              // First Row
              Row(
                children: [
                  _buildDataItem("Open Price", openPrice.toStringAsFixed(2),context),
                  _buildDataItem("Prev. close", prevClose.toStringAsFixed(2),context),
                  _buildDataItem("Volume", volume,context),
                ],
              ),

              SizedBox(height: 30),

              // Second Row
              Row(
                children: [
                  _buildDataItem("Lower circuit", lowerCircuit.toStringAsFixed(2),context),
                  _buildDataItem("Upper circuit", upperCircuit.toStringAsFixed(2),context),
                  Expanded(child: SizedBox()), // Empty space for alignment
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRange(
      String lowLabel,
      String highLabel,
      double lowValue,
      double highValue,
      double currentValue,
      BuildContext context,
      ) {
    double progress = (currentValue - lowValue) / ((highValue - lowValue).abs() < 1e-9 ? 1 : (highValue - lowValue));
    progress = progress.clamp(0.0, 1.0);
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    const indicatorWidth = 12.0;

    return Column(
      children: [
        // Labels and values
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lowLabel,
                    style:  TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: theme.text)),
                const SizedBox(height: 8),
                Text(lowValue.toStringAsFixed(2),
                    style:  TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.text)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(highLabel,
                    style:  TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: theme.text)),
                const SizedBox(height: 8),
                Text(highValue.toStringAsFixed(2),
                    style:  TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.text)),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Bar + triangle
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            final leftPx = (barWidth - indicatorWidth) * progress;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // background bar
                Container(
                  width: double.infinity,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                // triangle indicator
                Positioned(
                  left: leftPx,
                  top: -2,
                  child: SizedBox(
                    width: indicatorWidth,
                    height: 10,
                    child: CustomPaint(painter: TrianglePainter()),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDataItem(String label, String value,BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'SF Pro',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: theme.text,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'SF Pro',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.text,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the triangle indicator
class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0); // Top point
    path.lineTo(0, size.height); // Bottom left
    path.lineTo(size.width, size.height); // Bottom right
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}