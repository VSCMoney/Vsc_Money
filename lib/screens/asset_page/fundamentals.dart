import 'package:flutter/material.dart';

import '../../services/theme_service.dart';
import '../../testpage.dart';


class FundamentalsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'Fundamentals',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),

          SizedBox(height: 20),

          // Strong Profitability Card
          FundamentalCard(

            imageName: "assets/images/upward.png",
            title: 'Strong Profitability',
            description: 'Microsoft maintains high operating margins (~40%) and consistently strong net income, reflecting excellent cost control and scalable business models.',
          ),

          SizedBox(height: 16),

          // Premium Valuation Card
          FundamentalCard(

            imageName: "assets/images/downward.png",
            title: 'Premium Valuation',
            description: 'Current price-to-earnings ratio is notably above the tech sector average, which may indicate overvaluation in the short term.',
          ),

          SizedBox(height: 16),

          // Low Debt-to-Equity Ratio Card
          FundamentalCard(

            imageName: "assets/images/eye.png",
            title: 'Low Debt-to-Equity Ratio:',
            description: 'Microsoft maintains a return on equity above 35% and solid return on invested capital, highlighting efficient capital use.',
          ),
        ],
      ),
    );
  }
}

class FundamentalCard extends StatelessWidget {
  final String imageName;
  final String title;
  final String description;

  const FundamentalCard({
    Key? key,
    required this.imageName,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.box,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 8,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 16,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child:
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(imageName,width: 30,color: theme.icon,),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:  TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style:  TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: theme.text,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedOrb(size: 20,),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}




class FundamentalData {

  final String title;
  final String description;
  final String imageName;

  FundamentalData({
    required this.title,
    required this.description,
    required this.imageName
  });
}




class CustomFundamentalsSection extends StatelessWidget {
  final List<FundamentalData> fundamentals;
  final String title;

  const CustomFundamentalsSection({
    Key? key,
    required this.fundamentals,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.text,
            ),
          ),
          SizedBox(height: 20),
          ...fundamentals.map((fundamental) => Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: FundamentalCard(
              // icon: fundamental.icon,
              // iconColor: fundamental.iconColor,
              imageName: fundamental.imageName,
              title: fundamental.title,
              description: fundamental.description,
            ),
          )).toList(),
        ],
      ),
    );
  }
}
