import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../models/asset_model.dart';
import 'assets_page.dart';
import 'chart_data.dart';


class MarketDepthWidget extends StatelessWidget {
  final double buyPercentage;
  final double sellPercentage;
  final List<OrderData> bidOrders;
  final List<OrderData> askOrders;
  final int bidTotal;
  final int askTotal;

  const MarketDepthWidget({
    Key? key,
    this.buyPercentage = 37.66,
    this.sellPercentage = 62.34,
    this.bidOrders = const [
      OrderData(price: 0.00, quantity: 0),
      OrderData(price: 0.00, quantity: 0),
      OrderData(price: 0.00, quantity: 0),
      OrderData(price: 0.00, quantity: 0),
      OrderData(price: 0.00, quantity: 0),
    ],
    this.askOrders = const [
      OrderData(price: 0.00, quantity: 1464),
      OrderData(price: 0.00, quantity: 0),
      OrderData(price: 0.00, quantity: 0),
      OrderData(price: 0.00, quantity: 0),
      OrderData(price: 0.00, quantity: 0),
    ],
    this.bidTotal = 164634,
    this.askTotal = 164634,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0), // No border radius for full width
      ),
      child: Column(
        children: [
          // Header with percentages
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buy orders',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF7E7E7E),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${buyPercentage.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Sell orders',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF7E7E7E),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${sellPercentage.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 20),

          // Progress bar showing buy vs sell ratio
          Container(
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                // Buy orders (Green)
                Expanded(
                  flex: (buyPercentage * 100).round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF22C55E), // Green
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(6),
                        bottomLeft: Radius.circular(6),
                      ),
                    ),
                  ),
                ),
                // Sell orders (Red/Orange)
                Expanded(
                  flex: (sellPercentage * 100).round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFEF4444), // Red
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(6),
                        bottomRight: Radius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          // Order book table
          Row(
            children: [
              // Bid orders (Left side)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF9E6F37), width: 1), // 🟤 brown border
                    borderRadius: BorderRadius.circular(0),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Bid price',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7E7E7E),
                              ),
                            ),
                            Text(
                              'Qty',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7E7E7E),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bid rows
                      ...bidOrders.map((order) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.price.toStringAsFixed(2),
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              _formatNumber(order.quantity),
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF00AF41), // ✅ green
                              ),
                            ),
                          ],
                        ),
                      )),

                      // Bid total
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Bid total',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              _formatNumber(bidTotal),
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              //SizedBox(width: 6), // gap between tables

              // Ask orders (Right side)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF9E6F37), width: 1), // 🟤 brown border
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ask price',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7E7E7E),
                              ),
                            ),
                            Text(
                              'Qty',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7E7E7E),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Ask rows
                      ...askOrders.map((order) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.price.toStringAsFixed(2),
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              order.quantity == 0 ? "0" : _formatNumber(order.quantity),
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFFF3D3D), // ✅ red
                              ),
                            ),
                          ],
                        ),
                      )),

                      // Ask total
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ask total',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              _formatNumber(askTotal),
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )

        ],
      ),
    );
  }

  Widget _buildOrderRow(String price, String quantity, bool isBid) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            price,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          Text(
            quantity,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isBid ? Color(0xFF22C55E) : Color(0xFFEF4444), // Green for bid, Red for ask
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    } else {
      return number.toString();
    }
  }
}
