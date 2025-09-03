import 'package:flutter/material.dart';

import '../../constants/colors.dart';



class FinancialMetricsWidget extends StatelessWidget {
  final String marketCap;
  final String roe;
  final String peRatio;
  final String eps;
  final String pbRatio;
  final String divYield;
  final String industryPE;
  final String bookValue;
  final String debtToEquity;
  final String faceValue;

  const FinancialMetricsWidget({
    Key? key,
    this.marketCap = "₹25,473Cr",
    this.roe = "1.33%",
    this.peRatio = "75.58",
    this.eps = "13.23",
    this.pbRatio = "1.18",
    this.divYield = "1.10%",
    this.industryPE = "45.54",
    this.bookValue = "847.61",
    this.debtToEquity = "0.33",
    this.faceValue = "10",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0), // No border radius for full width
      ),
      child: Column(
        children: [
          // Row 1: Mkt Cap & ROE
          _buildMetricRow("Mkt Cap", marketCap, "ROE", roe),

          SizedBox(height: 24),

          // Row 2: P/E Ratio & EPS
          _buildMetricRow("P/E Ratio(TTM)", peRatio, "EPS(TTM)", eps),

          SizedBox(height: 24),

          // Row 3: P/B Ratio & Div Yield
          _buildMetricRow("P/B Ratio", pbRatio, "Div Yield", divYield),

          SizedBox(height: 24),

          // Row 4: Industry P/E & Book Value
          _buildMetricRow("Industry P/E", industryPE, "Book Value", bookValue),

          SizedBox(height: 24),

          // Row 5: Debt to Equity & Face Value
          _buildMetricRow("Debt to Equity", debtToEquity, "Face Value", faceValue),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String leftLabel, String leftValue, String rightLabel, String rightValue) {
    return Row(
      children: [
        // Left side metric
        Expanded(
          child: Row(
            children: [
              Text(
                leftLabel,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF7E7E7E), // Gray color
                  height: 1.2,
                ),
              ),
              Spacer(),
              Text(
                leftValue,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),

        SizedBox(width: 20), // Space between columns

        // Right side metric
        Expanded(
          child: Row(
            //crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rightLabel,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF7E7E7E), // Gray color
                  height: 1.2,
                ),
              ),
              Spacer(),
              Text(
                rightValue,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
