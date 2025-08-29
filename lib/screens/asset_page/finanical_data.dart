// financials_content.dart (where FinancialChartsWidget lives)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../constants/colors.dart';
import '../../services/asset_service.dart';            // <-- path where AssetService is
import '../../models/asset_model.dart' as models;
import '../../services/theme_service.dart';     // <-- your API models

class FinancialChartsWidget extends StatefulWidget {
  const FinancialChartsWidget({super.key});
  @override
  State<FinancialChartsWidget> createState() => _FinancialChartsWidgetState();
}

class _FinancialChartsWidgetState extends State<FinancialChartsWidget> {
  // 0 = Revenue, 1 = Profit, 2 = Net Worth
  int selectedTab = 0;
  // 'Quarterly' | 'Yearly'
  String selectedPeriod = 'Quarterly';

  // service
  late final AssetService _svc = GetIt.I<AssetService>();
  StreamSubscription<AssetViewState>? _sub;

  // normalized series (period, value)
  List<_BarPoint> _revQ = const [];
  List<_BarPoint> _revY = const [];
  List<_BarPoint> _profQ = const [];
  List<_BarPoint> _profY = const [];
  List<_BarPoint> _netQ = const [];
  List<_BarPoint> _netY = const [];
  String _valueUnit = 'Rs. CR';

  @override
  void initState() {
    super.initState();
    // subscribe to service state (no StreamBuilder)
    _sub = _svc.state.listen(_onState);
    // also hydrate from current snapshot (instant first paint if already loaded)
    _onState(_svc.snapshot);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onState(AssetViewState s) {
    final d = s.data;
    if (d == null) return;

    // ✅ Charts are under root -> expandableTiles.financials (nullable)
    final charts = d.expandableTiles?.financials;
    if (charts == null) return;

    _valueUnit = charts.valueUnit.isNotEmpty ? charts.valueUnit : _valueUnit;

    _revQ  = _toBars(charts.revenueQuarterly);
    _revY  = _toBars(charts.revenueYearly);
    _profQ = _toBars(charts.profitQuarterly);
    _profY = _toBars(charts.profitYearly);
    _netQ  = _toBars(charts.netWorthQuarterly);
    _netY  = _toBars(charts.netWorthYearly);

    // if current selection has no data but the other period has, auto-switch
    if (_activeList.isEmpty) {
      if (_hasQuarterlyForTab) {
        selectedPeriod = 'Quarterly';
      } else if (_hasYearlyForTab) {
        selectedPeriod = 'Yearly';
      }
    }

    if (mounted) setState(() {});
  }


  // ------- helpers to select the active list -------
  List<_BarPoint> get _activeList {
    switch (selectedTab) {
      case 0: return selectedPeriod == 'Quarterly' ? _revQ  : _revY;
      case 1: return selectedPeriod == 'Quarterly' ? _profQ : _profY;
      case 2: return selectedPeriod == 'Quarterly' ? _netQ  : _netY;
      default: return const [];
    }
  }

  bool get _hasQuarterlyForTab {
    switch (selectedTab) {
      case 0: return _revQ.isNotEmpty;
      case 1: return _profQ.isNotEmpty;
      case 2: return _netQ.isNotEmpty;
      default: return false;
    }
  }

  bool get _hasYearlyForTab {
    switch (selectedTab) {
      case 0: return _revY.isNotEmpty;
      case 1: return _profY.isNotEmpty;
      case 2: return _netY.isNotEmpty;
      default: return false;
    }
  }

  // normalize any model list with {period, value}
  List<_BarPoint> _toBars(List<models.ChartDataPoint> list) {
    if (list.isEmpty) return const [];
    return list
        .where((e) => (e.period).toString().trim().isNotEmpty)
        .map((e) => _BarPoint(period: e.period, value: e.value))
        .toList();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    final active = _activeList;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTab('Revenue', 0),
              const SizedBox(width: 40),
              _buildTab('Profit', 1),
              const SizedBox(width: 40),
              _buildTab('Net Worth', 2),
            ],
          ),

          const SizedBox(height: 20),

          // Chart area
          SizedBox(
            height: 300,
            child: active.isEmpty ? _buildEmptyChart() : _buildBars(active),
          ),

          const SizedBox(height: 30),

          // Bottom controls
          Row(
            children: [
              // period toggles
              _buildPeriodSwitch(),
              const Spacer(),
              Text(
                'See details',
                style: const TextStyle(
                  fontFamily: 'SF Pro',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSwitch() {
    final canQ = _hasQuarterlyForTab;
    final canY = _hasYearlyForTab;

    return Container(
      height: 36,
      padding: const EdgeInsets.all(2),
      // decoration: BoxDecoration(
      //   color: const Color(0xFFF5F5F5),
      //   borderRadius: BorderRadius.circular(20),
      //   border: Border.all(color: const Color(0xFFE5E7EB)),
      // ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSegment(
            'Quarterly',
            isSelected: selectedPeriod == 'Quarterly',
            enabled: canQ,
            onTap: () {
              if (!canQ) return;
              setState(() => selectedPeriod = 'Quarterly');
            },
          ),
          _buildSegment(
            'Yearly',
            isSelected: selectedPeriod == 'Yearly',
            enabled: canY,
            onTap: () {
              if (!canY) return;
              setState(() => selectedPeriod = 'Yearly');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(
      String label, {
        required bool isSelected,
        required bool enabled,
        required VoidCallback onTap,
      }) {
    final bg = isSelected ? AppColors.primary : Colors.transparent;
    final textColor = isSelected
        ? Colors.white
        : (enabled ? const Color(0xFF6B7280) : const Color(0xFFCBD5E1));

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'SF Pro',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }


  Widget _buildTab(String title, int index) {
    final isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() {
        selectedTab = index;
        // if new tab has no data for the current period, auto-switch
        if (_activeList.isEmpty) {
          if (_hasQuarterlyForTab) {
            selectedPeriod = 'Quarterly';
          } else if (_hasYearlyForTab) {
            selectedPeriod = 'Yearly';
          }
        }
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'SF Pro',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? const Color(0xFFE87E2E) : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: title.length * 8.0,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE87E2E) : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBars(List<_BarPoint> data) {
    final maxValue = (data.map((e) => e.value).fold<double>(0, (a, b) => a > b ? a : b)).clamp(1.0, double.infinity);
    const maxBarHeight = 200.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // unit note
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(
            'All values are in $_valueUnit',
            style: const TextStyle(
              fontFamily: 'SF Pro',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7E7E7E),
            ),
          ),
        ),
        // bars
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: data.map((d) {
              final h = (d.value / maxValue) * maxBarHeight;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    d.value.toStringAsFixed(d.value == d.value.roundToDouble() ? 0 : 2),
                    style: const TextStyle(
                      fontFamily: 'SF Pro',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF7E7E7E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 24,
                    height: h,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        // period labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: data.map((d) => Text(
            d.period,
            style: const TextStyle(
              fontFamily: 'SF Pro',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7E7E7E),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildEmptyChart() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.bar_chart, size: 64, color: Color(0xFFE5E7EB)),
        SizedBox(height: 16),
        Text(
          'No data available',
          style: TextStyle(
            fontFamily: 'SF Pro',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9CA3AF),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Data for this metric will be displayed here when available',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'SF Pro',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFFD1D5DB),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodButton(String title, {required bool isSelected, required bool enabled}) {
    final textColor = isSelected
        ? AppColors.primary
        : (enabled ? const Color(0xFF6B7280) : const Color(0xFFCBD5E1));
    final bgColor = isSelected ? const Color(0xFFFDF2F2) : Colors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'SF Pro',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

// local normalized point (UI only)
class _BarPoint {
  final String period;
  final double value;
  const _BarPoint({required this.period, required this.value});
}
