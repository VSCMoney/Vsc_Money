import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../constants/colors.dart';
import '../../services/asset_service.dart';        // <- adjust path if needed
import '../../models/asset_model.dart' as models;
import '../../services/locator.dart';  // <- adjust path if needed

class ShareholdingPatternWidget extends StatefulWidget {
  const ShareholdingPatternWidget({Key? key}) : super(key: key);

  @override
  _ShareholdingPatternWidgetState createState() => _ShareholdingPatternWidgetState();
}

class _ShareholdingPatternWidgetState extends State<ShareholdingPatternWidget> {
  // Service wiring (no StreamBuilder)
  late final AssetService _svc = locator<AssetService>();
  StreamSubscription<AssetViewState>? _sub;

  // Live state
  List<String> _timePeriods = const [];
  List<Map<String, double>> _seriesByPeriod = const [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // prime from snapshot (if already loaded)
    _pullFromService(_svc.snapshot);
    // listen for next updates
    _sub = _svc.state.listen(_pullFromService);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _pullFromService(AssetViewState s) {
    final data = s.data;
    if (data == null) return;

    final shp = data.performanceData.expandableTiles?.shareholdingPattern;
    if (shp == null) return;

    // Parse time periods
    final periods = List<String>.from(shp.timePeriods ?? const <String>[]);
    // Parse series list (each entry is a map of holder -> fraction [0..1])
    final rawList = shp.shareholdingData ?? const <Map<String, dynamic>>[];

    final parsedList = <Map<String, double>>[];
    for (final m in rawList) {
      final row = <String, double>{};
      m.forEach((k, v) {
        final val = (v is num) ? v.toDouble() : 0.0;
        row[k] = val.clamp(0.0, 1.0);
      });
      parsedList.add(row);
    }

    if (periods.isEmpty || parsedList.isEmpty) return;

    final defIndex = (shp.defaultSelectedIndex ?? 0)
        .clamp(0, periods.length - 1);

    setState(() {
      _timePeriods = periods;
      _seriesByPeriod = parsedList;
      _selectedIndex = defIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_timePeriods.isEmpty || _seriesByPeriod.isEmpty) {
      // Graceful fallback if API hasn’t provided shareholding yet
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SizedBox(height: 8),
          Text(
            'Shareholding pattern',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
              height: 1.2,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'No shareholding data available',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      );
    }

    final current = _seriesByPeriod[
    _selectedIndex.clamp(0, _seriesByPeriod.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateSelector(),
        const SizedBox(height: 14),
        ...current.entries.map((e) => _buildShareholdingRow(e.key, e.value)),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: List.generate(_timePeriods.length, (index) {
        final isSelected = _selectedIndex == index;
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFF0E6) : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                _timePeriods[index],
                style: TextStyle(
                  color: isSelected ? const Color(0xFFFB8C00) : const Color(0xFF7E7E7E),
                  fontWeight: FontWeight.w500,
                  fontFamily: 'DM Sans',
                  fontSize: 10,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildShareholdingRow(String label, double fraction) {
    final pct = (fraction * 100).clamp(0, 100);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // bar + label block
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label above bar
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ),
                // Progress bar
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: fraction.clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF97316),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              '${pct.toStringAsFixed(2)}%',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
