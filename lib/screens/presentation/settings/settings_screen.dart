import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vscmoney/screens/presentation/settings/section_header.dart';
import 'package:vscmoney/screens/presentation/settings/settings_group.dart';
import 'package:vscmoney/screens/presentation/settings/settings_tile.dart';

import '../../../constants/bottomsheet.dart';
import '../../../routes/AppRoutes.dart';
import '../../../services/auth_service.dart';
import '../../../services/locator.dart';
import '../../../services/theme_service.dart';
import '../../widgets/drawer.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onTap;
  const SettingsScreen({super.key, required this.onTap});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  final AuthService _authService = locator<AuthService>();



  Future<void> _closeSheet() async {
    // Prefer closing the actual wrapper ancestor (robust on iOS)
    final wrapper = context.findAncestorStateOfType<ChatGPTBottomSheetWrapperState>();
    if (wrapper != null && wrapper.isSheetOpen) {
      await wrapper.closeSheet(); // now returns Future<void>
      return;
    }

    // Fallback: use the callback you passed from HomeScreen
    try {
      widget.onTap();
    } catch (_) {}

    // Final fallback: pop if this sheet was presented as a route
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).maybePop();
    }
  }


  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          title: Row(
            children: const [
              Icon(Icons.logout, color: Colors.red, size: 24),
              SizedBox(width: 12),
              Text(
                'Log Out',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'DM Sans',
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(fontSize: 15, fontFamily: 'DM Sans'),
          ),
          actionsPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'DM Sans')),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout', style: TextStyle(fontFamily: 'DM Sans')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                await _authService.logout();
                _navigateTo('phone_otp');

              },
            ),
          ],
        );
      },
    );
  }

  void _navigateTo(String route) {
    if (!mounted) return;
    GoRouter.of(rootNavigatorKey.currentContext!).go('/phone_otp');

  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return Scaffold(
      backgroundColor: theme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Top Bar
            Row(
              //mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              Container(
                //color: Colors.black,
                child: GestureDetector(
                behavior: HitTestBehavior.opaque,        // <-- ensure taps register
                onTap: _closeSheet,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),   // <-- comfy hit area
                  child: Image.asset(
                    "assets/images/cancel.png",
                    height: 30,
                    color: theme.icon,
                  ),
                ),
                            ),
              ),

                SizedBox(width: 108),
                Text(
                  "Settings",
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: theme.text,
                  ),
                ),
                const SizedBox(width: 28), // Placeholder for alignment
              ],
            ),

            const SizedBox(height: 20),

            // Profile Card
            Container(
              padding:  EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.box,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundImage: NetworkImage("https://i.pravatar.cc/100"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("RGB",
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: theme.text,
                            )),
                        SizedBox(height: 2),
                        Text("+91 94XXXXXX32",
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              color: theme.text,
                            )),
                      ],
                    ),
                  ),
                  Icon(Icons.edit, size: 16,color: theme.icon,)
                ],
              ),
            ),

            const SizedBox(height: 28),

            // General
            const SectionHeader("General"),
            SettingsGroup(
              tiles: const [
                SettingsTile(icon: Icons.place_outlined, title: "Personalise"),
                SettingsTile(icon: Icons.dark_mode_outlined, title: "Dark Mode", hasSwitch: true),
              ],
            ),

            const SizedBox(height: 28),

            // Account
            const SectionHeader("Account"),
            SettingsGroup(
              tiles: const [
                SettingsTile(icon: Icons.group_outlined, title: "Nominee"),
                SettingsTile(
                  icon: Icons.add_circle_outline,
                  title: "Subscription",
                  trailingText: "Free Plan",
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Privacy
            const SectionHeader("Privacy"),
            SettingsGroup(
              tiles: const [
                SettingsTile(icon: Icons.security_outlined, title: "Data Protection"),
                SettingsTile(icon: Icons.lock_outline, title: "App Lock", hasSwitch: true),
              ],
            ),

            const SizedBox(height: 28),

            // Logout
            GestureDetector(
              onTap: () {
                _confirmLogout(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.box,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:  Row(
                  children: [
                    Icon(Icons.logout, color: theme.icon),
                    SizedBox(width: 10),
                    Text(
                      "Logout",
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: theme.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}