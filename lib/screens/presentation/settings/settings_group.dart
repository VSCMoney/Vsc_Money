import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vscmoney/screens/presentation/settings/settings_tile.dart';

import '../../../services/theme_service.dart';
import '../../widgets/drawer.dart';

class SettingsGroup extends StatelessWidget {
  final List<SettingsTile> tiles;
  const SettingsGroup({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    return Container(
      decoration: BoxDecoration(
        color: theme.box,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List.generate(tiles.length * 2 - 1, (index) {
          if (index.isOdd) {
            return const Divider(
              height: 1,
              thickness: 1,
              indent: 16,
              endIndent: 16,
              color: Color(0xFFE0E0E0),
            );
          }
          return tiles[index ~/ 2];
        }),
      ),
    );
  }
}