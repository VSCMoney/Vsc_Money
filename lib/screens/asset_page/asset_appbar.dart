import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get_it/get_it.dart';

import '../../../services/asset_service.dart';

class StockAppBar extends StatefulWidget {
  const StockAppBar({
    super.key,
    required this.onClose,
    required this.fallbackTitle, // e.g., the symbol or name you already have
    this.accentColor = const Color(0xFF734012),
  });

  final VoidCallback onClose;
  final String fallbackTitle;
  final Color accentColor;

  @override
  State<StockAppBar> createState() => _StockAppBarState();
}

class _StockAppBarState extends State<StockAppBar> {
  late final AssetService _svc = GetIt.I<AssetService>();
  StreamSubscription<AssetViewState>? _sub;

  String _title = '';
  bool _watchlisted = false;

  @override
  void initState() {
    super.initState();

    // initial from snapshot (if available)
    _syncFromState(_svc.snapshot);

    // subscribe to changes
    _sub = _svc.state.listen((s) {
      if (!mounted) return;
      _syncFromState(s);
    });
  }

  void _syncFromState(AssetViewState s) {
    String newTitle = widget.fallbackTitle;
    bool newWatch = _watchlisted;

    final d = s.data;
    if (d != null) {
      // Prefer backend name; else use fallback
      if (d.basicInfo.name.trim().isNotEmpty) {
        newTitle = d.basicInfo.name.trim();
      }
      newWatch = d.additionalData?.userWatchlisted ?? false;
    }

    // Update only if changed to avoid rebuild churn
    if (newTitle != _title || newWatch != _watchlisted) {
      setState(() {
        _title = newTitle;
        _watchlisted = newWatch;
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _toggleWatchlist() {
    // optimistic flip
    setState(() => _watchlisted = !_watchlisted);
    _svc.toggleWatchlist();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🔹 Center title always centered regardless of sides
          Text(
            _title.isNotEmpty ? _title : widget.fallbackTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              fontFamily: "DM Sans",
            ),
          ),

          // 🔹 Left and Right controls positioned exactly
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 18),
              GestureDetector(
                onTap: widget.onClose,
                child: Image.asset(
                  "assets/images/cancel.png",
                  width: 30,
                  height: 30,
                  color: widget.accentColor,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: widget.accentColor,
                      size: 24,
                    ),
                    onPressed: () {
                      // TODO: hook your alerts/notifications sheet here
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _watchlisted ? Icons.bookmark : Icons.bookmark_border,
                      color: widget.accentColor,
                      size: 24,
                    ),
                    onPressed: _toggleWatchlist,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class StockPortfolioCard extends StatelessWidget {
  final int shares;
  final double avgPrice;
  final double currentValue;
  final double changePercent;
  final double changeAmount;
  final bool isPositive;

  const StockPortfolioCard({
    Key? key,
    this.shares = 20,
    this.avgPrice = 1821.45,
    this.currentValue = 36429.00,
    this.changePercent = 10.0,
    this.changeAmount = 14.9,
    this.isPositive = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Top row - Shares info and current value
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Shares info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$shares Shares',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Avg price ₹${avgPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF6B7280),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),

                // Right side - Current value and change
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${currentValue.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          color:
                          isPositive
                              ? Color(0xFF10B981)
                              : Color(0xFFEF4444),
                          size: 16,
                        ),
                        Text(
                          '${changePercent.toStringAsFixed(0)}% (+${changeAmount.toStringAsFixed(1)})',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color:
                            isPositive
                                ? Color(0xFF10B981)
                                : Color(0xFFEF4444),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 1),
            Divider(thickness: 0),
            SizedBox(height: 10),

            // Bottom row - Broker logos and action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side - Broker logos
                Row(
                  children: [
                    // First broker logo (teal circle)
                    Image.asset("assets/images/choose_broker.png", width: 40),
                  ],
                ),

                // Right side - Go to broker action
                Row(
                  children: [
                    Text(
                      'Go to your broker',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: Colors.black, size: 18),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}