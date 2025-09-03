import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:vscmoney/services/locator.dart';

import '../../../services/asset_service.dart';
import '../../constants/bottomsheet.dart';
import '../../services/theme_service.dart';

class StockAppBar extends StatefulWidget {
  const StockAppBar({
    super.key,
    required this.onClose,
    required this.fallbackTitle,
    this.accentColor = const Color(0xFF734012),
  });

  final VoidCallback onClose;
  final String fallbackTitle;
  final Color accentColor;

  @override
  State<StockAppBar> createState() => _StockAppBarState();
}

class _StockAppBarState extends State<StockAppBar> {
  late final AssetService _svc = locator<AssetService>();
  StreamSubscription<AssetViewState>? _sub;

  String _title = '';
  bool _watchlisted = false;

  @override
  void initState() {
    super.initState();
    _syncFromState(_svc.snapshot);
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
      if (d.basicInfo.name.trim().isNotEmpty) newTitle = d.basicInfo.name.trim();
      newWatch = d.additionalData?.userWatchlisted ?? false;
    }
    if (newTitle != _title || newWatch != _watchlisted) {
      setState(() { _title = newTitle; _watchlisted = newWatch; });
    }
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  void _toggleWatchlist() {
    setState(() => _watchlisted = !_watchlisted);
    _svc.toggleWatchlist();
  }

  Future<void> _handleClose() async {
    try { if (Platform.isIOS) HapticFeedback.lightImpact(); } catch (_) {}
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: theme.background,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Left side - Cancel button (reduced width)
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: _handleClose,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 40, // Reduced from 56
                  height: 40, // Reduced from 56
                  alignment: Alignment.center,
                  child: const _CancelIconAsset(),
                ),
              ),
            ),

            // Center - Title (expanded to take available space)
            Expanded(
              child: Text(
                _title.isNotEmpty ? _title : widget.fallbackTitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.text,
                  fontFamily: "DM Sans",
                ),
              ),
            ),

            // Right side - Notification and Bookmark icons (reduced spacing)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 40, // Reduced from 44
                      height: 40, // Reduced from 44
                      alignment: Alignment.center,
                      child: Icon(Icons.notifications_outlined, size: 22, color: theme.icon),
                    ),
                  ),
                ),
                const SizedBox(width: 2), // Reduced from 4
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: _toggleWatchlist,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 40, // Reduced from 44
                      height: 40, // Reduced from 44
                      alignment: Alignment.center,
                      child: Icon(
                        _watchlisted ? Icons.bookmark : Icons.bookmark_border,
                        size: 22,
                        color: theme.icon,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CancelIconAsset extends StatelessWidget {
  const _CancelIconAsset();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    return Image.asset(
      "assets/images/cancel.png",
      height: 27,
      width: 27,
      color: theme.icon,
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
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.box,
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
                        color: theme.text,
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
                        color: theme.text,
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
                        color: theme.text,
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
                        color: theme.text,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: theme.icon, size: 18),
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