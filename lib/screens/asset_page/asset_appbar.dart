import 'package:flutter/material.dart';
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
      if (d.basicInfo.name.trim().isNotEmpty) {
        newTitle = d.basicInfo.name.trim();
      }
      newWatch = d.additionalData?.userWatchlisted ?? false;
    }

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
    setState(() => _watchlisted = !_watchlisted);
    _svc.toggleWatchlist();
  }

  // ---- NEW: robust closer that works inside sheets/slivers on iOS too ----
  Future<void> _handleClose() async {
    // 1) Try any ChatGPTBottomSheetWrapper up the tree
    final wrapper = context.findAncestorStateOfType<ChatGPTBottomSheetWrapperState>();
    if (wrapper != null && wrapper.isSheetOpen) {
      await wrapper.closeSheet();
      return;
    }

    // 2) Use the callback provided by the parent (HomeScreen’s _closeSheet or similar)
    try {
      widget.onClose();
      return;
    } catch (_) {}

    // 3) Final fallback: pop the current route if possible
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return SafeArea( // ensure not under the notch
      top: false,
      bottom: false,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: theme.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            children: [
              // CENTER title first so buttons paint on top (no accidental overlay)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 80),
                  child: Text(
                    _title.isNotEmpty ? _title : widget.fallbackTitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.text,
                      fontFamily: "Inter",
                      height: 1.0,
                      letterSpacing: 0.0,
                    ),
                  ),
                ),
              ),

              // LEFT close button (now always tappable, bigger hit area, on top)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: _handleClose,
                      borderRadius: BorderRadius.circular(28),
                      child: SizedBox(

                        child: Center(
                          child: Image.asset(
                            "assets/images/cancel.png",
                            height: 32,
                            color: theme.icon,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // RIGHT icons
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          onTap: () {
                            // TODO: open alerts/notifications sheet
                          },
                          borderRadius: BorderRadius.circular(28),
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(Icons.notifications_outlined, size: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          onTap: _toggleWatchlist,
                          borderRadius: BorderRadius.circular(28),
                          child: SizedBox(
                            width: 44, height: 44,
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
                ),
              ),
            ],
          ),
        ),
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
                        fontFamily: 'SF Pro',
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
                        fontFamily: 'SF Pro',
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
                        fontFamily: 'SF Pro',
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
                            fontFamily: 'SF Pro',
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
                        fontFamily: 'SF Pro',
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