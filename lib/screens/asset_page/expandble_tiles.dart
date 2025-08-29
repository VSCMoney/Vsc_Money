import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vscmoney/screens/asset_page/share_holding_pattern.dart';
import 'package:vscmoney/services/locator.dart';

import '../../constants/colors.dart';
import '../../models/asset_model.dart';
import '../../models/asset_model.dart' as models;
import '../../services/asset_service.dart';
import '../../services/theme_service.dart';
import '../../testpage.dart';
import 'assets_page.dart';
import 'chart_data.dart';
import 'financial_metrics.dart';
import 'finanical_data.dart';
import 'market_depth.dart';




class MarketDepthProps {
  final double buyPercentage;
  final double sellPercentage;
  final List<OrderData> bidOrders;
  final List<OrderData> askOrders;
  final int bidTotal;
  final int askTotal;

  const MarketDepthProps({
    required this.buyPercentage,
    required this.sellPercentage,
    required this.bidOrders,
    required this.askOrders,
    required this.bidTotal,
    required this.askTotal,
  });
}

// Customizable version with external data
class CustomExpandableTiles extends StatefulWidget {
  final List<ExpandableTileItem> tiles;

  const CustomExpandableTiles({
    Key? key,
    required this.tiles,
  }) : super(key: key);

  @override
  _CustomExpandableTilesState createState() => _CustomExpandableTilesState();
}

class _CustomExpandableTilesState extends State<CustomExpandableTiles> {
  Set<int> expandedTiles = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFF5F5F5),
      child: Column(
        children: List.generate(widget.tiles.length, (index) {
          final tile = widget.tiles[index];
          final isExpanded = expandedTiles.contains(index);

          return Container(
            margin: EdgeInsets.only(bottom: 1),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: index == 0 ? BorderSide(color: Color(0xFFE5E5E5), width: 1) : BorderSide.none,
                bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
              ),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        expandedTiles.remove(index);
                      } else {
                        expandedTiles.add(index);
                      }
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tile.title,
                          style: TextStyle(
                            fontFamily: 'SF Pro',
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0.0,
                          duration: Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.black,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  // height: isExpanded ? null : 0,
                  constraints: isExpanded
                      ? BoxConstraints()
                      : BoxConstraints(maxHeight: 0),

                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 250),
                    opacity: isExpanded ? 1.0 : 0.0,
                    child: isExpanded
                        ? Container(
                      width: double.infinity,
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 24,
                      ),
                      child: tile.content,
                    )
                        : SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class ExpandableTileItem {
  final String title;
  final Widget content;

  ExpandableTileItem({required this.title, required this.content});
}

class TileData {
  final String title;
  final Widget content;

  TileData({required this.title, required this.content});
}


class ExpandableTilesSection extends StatefulWidget {
  final MarketDepthProps? marketDepth; // ⬅️ new (optional)

  const ExpandableTilesSection({
    Key? key,
    this.marketDepth, // ⬅️ new
  }) : super(key: key);
  @override
  _ExpandableTilesSectionState createState() => _ExpandableTilesSectionState();
}

class _ExpandableTilesSectionState extends State<ExpandableTilesSection> {
  Set<int> expandedTiles = {};
  String? _aboutText;

  // —— Service wiring ——
  late final AssetService _svc = locator<AssetService>();
  StreamSubscription<AssetViewState>? _sub;

  // —— Fundamentals state (live from API) ——
  models.FinancialMetrics? _fundMetrics;

  @override
  void initState() {
    super.initState();
    // snapshot se prime
    _hydrateFrom(_svc.snapshot);
    // future updates
    _sub = _svc.state.listen(_hydrateFrom);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _hydrateFrom(AssetViewState s) {
    final d = s.data;
    if (d == null) return;

    // ── Tiles are on the root: d.expandableTiles (nullable) ──
    final tiles = d.expandableTiles; // may be null depending on payload

    // Fundamentals (take from tiles if present; no legacy fallback)
    final fmFromTiles = tiles?.fundamentals; // ✅ null-safe
    _fundMetrics = fmFromTiles;              // may be null → UI shows “No fundamentals…”

    // About/company text (prefer tiles.about_company, else basicInfo.description)
    final aboutFromTiles = tiles?.aboutCompany; // ✅ null-safe
    final basicDesc = d.basicInfo.description;
    _aboutText = (aboutFromTiles != null && aboutFromTiles.trim().isNotEmpty)
        ? aboutFromTiles.trim()
        : null;

    setState(() {});
  }




  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    final tiles = [
      TileData(
        title: "Market Depth",
        content: _buildMarketDepthContent(),
      ),
      TileData(
        title: "Fundamentals",
        content: _buildFundamentalsContent(),
      ),
      TileData(
        title: "Financials",
        content: _buildFinancialsContent(),
      ),
      TileData(
        title: "About",
        content: _buildAboutContent(),
      ),
      TileData(
        title: "Shareholding pattern",
        content: _buildShareholdingContent(),
      ),
    ];

    return Container(
      color: theme.background, // Light gray background
      child: Column(
        children: List.generate(tiles.length, (index) {
          return _buildExpandableTile(
            index,
            tiles[index].title,
            tiles[index].content,
          );
        }),
      ),
    );
  }

  Widget _buildExpandableTile(int index, String title, Widget content) {
    final isExpanded = expandedTiles.contains(index);
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    return Container(
      margin: EdgeInsets.only(bottom: 1), // Thin separator between tiles
      decoration: BoxDecoration(
        color: theme.background,
        border: Border(
          top: index == 0 ? BorderSide(color: theme.border, width: 1) : BorderSide.none,
          bottom: BorderSide(color: theme.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Tile Header
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  expandedTiles.remove(index);
                } else {
                  expandedTiles.add(index);
                }
              });
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'SF Pro',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.text,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(width: 10,),
                      isExpanded ?AnimatedOrb(size: 20,) : SizedBox.shrink()
                    ],
                  ),

                  // Chevron Icon
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: theme.icon,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable Content
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: isExpanded ? null : 0,
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 250),
              opacity: isExpanded ? 1.0 : 0.0,
              child: isExpanded
                  ? Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 24,
                ),
                child: content,
              )
                  : SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  // Content for each tile
  Widget _buildMarketDepthContent() {
    final md = widget.marketDepth;
    if (md != null) {
      // 🔗 live data from service
      return MarketDepthWidget(
        buyPercentage: md.buyPercentage,
        sellPercentage: md.sellPercentage,
        bidOrders: md.bidOrders,
        askOrders: md.askOrders,
        bidTotal: md.bidTotal,
        askTotal: md.askTotal,
      );
    }else{
      return SizedBox.shrink();
    }

    // // 🔙 fallback = your current static UI
    // return MarketDepthWidget(
    //   buyPercentage: 45.20,
    //   sellPercentage: 54.80,
    //   bidOrders: const [
    //     OrderData(price: 3664.50, quantity: 125),
    //     OrderData(price: 3664.00, quantity: 89),
    //     OrderData(price: 3663.50, quantity: 0),
    //     OrderData(price: 3663.00, quantity: 234),
    //     OrderData(price: 3662.50, quantity: 156),
    //   ],
    //   askOrders: const [
    //     OrderData(price: 3665.00, quantity: 2456),
    //     OrderData(price: 3665.50, quantity: 189),
    //     OrderData(price: 3666.00, quantity: 0),
    //     OrderData(price: 3666.50, quantity: 345),
    //     OrderData(price: 3667.00, quantity: 123),
    //   ],
    //   bidTotal: 245680,
    //   askTotal: 298450,
    // );
  }


  Widget _buildFundamentalsContent() {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    final fm = _fundMetrics;
    if (fm == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No fundamentals available',
          style: TextStyle(
            fontFamily: 'SF Pro',
            fontSize: 12,
            color: theme.text,
          ),
        ),
      );
    }

    // --- helpers ---
    double? _toDouble(String? s) {
      if (s == null) return null;
      final t = s.trim();
      if (t.isEmpty) return null;
      return double.tryParse(t);
    }

    String _addCommas(String numStr) {
      // Add comma separators for better readability
      final parts = numStr.split('.');
      final intPart = parts[0];
      final decPart = parts.length > 1 ? '.${parts[1]}' : '';

      // Add commas every 3 digits from right
      final reversedInt = intPart.split('').reversed.join();
      final withCommas = RegExp(r'.{1,3}').allMatches(reversedInt)
          .map((match) => match.group(0))
          .join(',');

      return '${withCommas.split('').reversed.join()}$decPart';
    }
    // Updated formatting - no compact notation, show full numbers
    String _fmtNum(double? v, {int fractionDigits = 2}) {
      if (v == null) return '-';

      // For very large numbers, use proper financial formatting with commas
      if (v.abs() >= 10000000) {
        // For crores (10M+), show in crores format
        final crores = v / 10000000;
        return '${crores.toStringAsFixed(2)}Cr';
      } else if (v.abs() >= 100000) {
        // For lakhs (1L+), show in lakhs format
        final lakhs = v / 100000;
        return '${lakhs.toStringAsFixed(2)}L';
      } else {
        // For smaller numbers, show with commas
        return _addCommas(v.toStringAsFixed(fractionDigits));
      }
    }

    // Alternative: Show full numbers with comma separators only
    String _fmtNumFull(double? v, {int fractionDigits = 2}) {
      if (v == null) return '-';
      return _addCommas(v.toStringAsFixed(fractionDigits));
    }



    String _fmtPct(double? v, {int fractionDigits = 2}) {
      if (v == null) return '-';
      return '${v.toStringAsFixed(fractionDigits)}%';
    }

    // Parse values
    final mcap = _toDouble(fm.marketCap) ?? double.tryParse('${fm.marketCap}');
    final pe   = _toDouble(fm.peRatio)    ?? double.tryParse('${fm.peRatio}');
    final pb   = _toDouble(fm.pbRatio)    ?? double.tryParse('${fm.pbRatio}');
    final indP = _toDouble(fm.industryPE) ?? double.tryParse('${fm.industryPE}');
    final divY = _toDouble(fm.divYield)   ?? double.tryParse('${fm.divYield}');
    final eps  = _toDouble(fm.eps)        ?? double.tryParse('${fm.eps}');
    final bv   = _toDouble(fm.bookValue)  ?? double.tryParse('${fm.bookValue}');
    final roe  = _toDouble(fm.roe)        ?? double.tryParse('${fm.roe}');
    final dte  = _toDouble(fm.debtToEquity) ?? double.tryParse('${fm.debtToEquity}');
    final fv   = _toDouble(fm.faceValue)  ?? double.tryParse('${fm.faceValue}');

    final data = <FinancialMetric>[
      FinancialMetric('Mkt Cap',            _fmtNum(mcap, fractionDigits: 0)),
      FinancialMetric('ROE',                _fmtPct(roe)),
      FinancialMetric('P/E Ratio (TTM)',   _fmtNumFull(pe)),
      FinancialMetric('EPS (TTM)',         _fmtNumFull(eps)),
      FinancialMetric('P/B Ratio',         _fmtNumFull(pb)),
      FinancialMetric('Div Yield',         _fmtPct(divY)),
      FinancialMetric('Industry P/E',      _fmtNumFull(indP)),
      FinancialMetric('Book Value',        _fmtNum(bv)),
      FinancialMetric('Debt to Equity',    _fmtNumFull(dte)),
      FinancialMetric('Face Value',        _fmtNumFull(fv, fractionDigits: 0)),
    ];

    return FinancialMetricsWidget(data: data);
  }



  Widget _buildFinancialsContent() {
    return FinancialChartsWidget();
  }

  Widget _buildAboutContent() {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    final text = _aboutText;
    if (text == null || text.isEmpty) {
      return  Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text(
          'No company overview available',
          style: TextStyle(
            fontFamily: 'SF Pro',
            fontSize: 12,
            color: theme.text,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style:  TextStyle(
            fontFamily: 'SF Pro',
            fontSize: 14,
            color:theme.text,
            height: 1.5,
          ),
        ),

      ],
    );
  }





  Widget _buildShareholdingContent() {
    return ShareholdingPatternWidget();
  }


}


class FinancialMetric {
  final String label;
  final String value;
  FinancialMetric(this.label, this.value);
}

class FinancialMetricsWidget extends StatelessWidget {
  final List<FinancialMetric> data;
  const FinancialMetricsWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, c) {
        final isNarrow = c.maxWidth < 340;
        final crossCount = isNarrow ? 1 : 2;

        return GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 20,
            mainAxisExtent: 28,
          ),
          itemBuilder: (context, i) {
            final m = data[i];
            return Row(
              children: [
                Expanded(
                  child: Text(
                    m.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SF Pro',
                      fontSize: 12,
                      color: theme.text,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      m.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 14,
                        color: theme.text,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
