import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vscmoney/screens/asset_page/share_holding_pattern.dart';
import 'package:vscmoney/services/locator.dart';

import '../../constants/colors.dart';
import '../../models/asset_model.dart';
import '../../models/asset_model.dart' as models;
import '../../services/asset_service.dart';
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
                            fontFamily: 'DM Sans',
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
  String? _sector;
  String? _industry;
  String? _exchange;

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

    // Fundamentals (already added earlier) …
    final fmFromTiles = d.performanceData.expandableTiles?.fundamentals;
    final fmFallback  = d.performanceData.financialMetrics;
    _fundMetrics = fmFromTiles ?? fmFallback;

    // —— About/company text ——
    final aboutFromTiles = d.performanceData.expandableTiles?.aboutCompany; // model Field for `about_company`
    final basicDesc      = d.basicInfo.description;
    final pickedAbout    = (aboutFromTiles != null && aboutFromTiles.trim().isNotEmpty)
        ? aboutFromTiles.trim()
        : (basicDesc!.isNotEmpty ? basicDesc.trim() : null);

    _aboutText = pickedAbout;

    // meta (optional labels below description)
    _sector   = (d.basicInfo.sector).trim().isEmpty ? null : d.basicInfo.sector.trim();
    _industry = (d.basicInfo.industry).trim().isEmpty ? null : d.basicInfo.industry.trim();
    _exchange = (d.basicInfo.exchange).trim().isEmpty ? null : d.basicInfo.exchange.trim();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
      color: Color(0xFFF5F5F5), // Light gray background
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

    return Container(
      margin: EdgeInsets.only(bottom: 1), // Thin separator between tiles
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: index == 0 ? BorderSide(color: Color(0xFFE5E5E5), width: 1) : BorderSide.none,
          bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
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
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.black,
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
                      color: AppColors.black,
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
    final fm = _fundMetrics;

    if (fm == null) {
      // graceful fallback
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No fundamentals available',
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            color: Color(0xFF9CA3AF),
          ),
        ),
      );
    }

    // Safe string helper
    String s(String? v) => (v == null || v.trim().isEmpty) ? '-' : v.trim();

    // Model naming guard: industry_pe vs industryPE (handle both)
    final industryPeValue = (fm.industryPE);

    return FinancialMetricsWidget(
      marketCap:      s(fm.marketCap),
      roe:            s(fm.roe),
      peRatio:        s(fm.peRatio),
      eps:            s(fm.eps),
      pbRatio:        s(fm.pbRatio),
      divYield:       s(fm.divYield),
      industryPE:     s(industryPeValue),
      bookValue:      s(fm.bookValue),
      debtToEquity:   s(fm.debtToEquity),
      faceValue:      s(fm.faceValue),
    );
  }


  Widget _buildFinancialsContent() {
    return FinancialChartsWidget();
  }

  Widget _buildAboutContent() {
    final text = _aboutText;
    if (text == null || text.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text(
          'No company overview available',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            color: Color(0xFF9CA3AF),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            color: Color(0xFF4B5563),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),

        // Optional meta rows if present
        if (_sector != null || _industry != null || _exchange != null) ...[
          _aboutMetaRow('Sector', _sector),
          _aboutMetaRow('Industry', _industry),
          _aboutMetaRow('Exchange', _exchange),
        ],
      ],
    );
  }

  Widget _aboutMetaRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF7E7E7E),
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildShareholdingContent() {
    return ShareholdingPatternWidget();
  }


}
