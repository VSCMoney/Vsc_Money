import 'package:flutter/material.dart';

import '../../services/theme_service.dart';


class AuthButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  const AuthButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side:  BorderSide(color: theme.google),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style:  TextStyle(color: theme.text,fontFamily: "SF Pro"),
            ),
          ],
        ),
      ),
    );
  }
}
