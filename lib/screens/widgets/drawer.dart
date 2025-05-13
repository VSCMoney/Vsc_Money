import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
//import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vscmoney/screens/presentation/auth/auth_screen.dart';
import 'package:vscmoney/screens/presentation/auth/phone_otp_scree.dart';
import 'package:vscmoney/screens/presentation/home/assets.dart';
import 'package:vscmoney/screens/presentation/home/home_screen.dart';
import 'package:vscmoney/screens/presentation/home/portfolio_screen.dart';

import '../../../models/chat_session.dart';
import '../../../services/chat_service.dart';
import '../../constants/colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/session_manager.dart';
import '../../routes/AppRoutes.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../services/locator.dart';
import '../../services/theme_service.dart';
import '../presentation/conversations.dart';
import '../presentation/search_stock_screen.dart';
import 'package:http/http.dart' as http;


class CustomDrawer extends StatefulWidget {
  final ChatService? chatService;
  final Function(ChatSession)? onSessionTap;
  final VoidCallback? onCreateNewChat;
  final String selectedRoute;

  const CustomDrawer({
    Key? key,
    this.chatService,
    this.onSessionTap,
    this.onCreateNewChat,
    this.selectedRoute = 'Vitty',
  }) : super(key: key);

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  late String _selectedItem;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.selectedRoute;
  }
  final theme = locator<ThemeService>().currentTheme;
  void _handleTap(String title, VoidCallback onTap) {
    setState(() => _selectedItem = title);
    onTap();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: theme.background,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: screenWidth * 0.04),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StockSearchScreen()));
                },
                child: Container(
                  height: screenHeight * 0.053,
                  decoration: BoxDecoration(
                    color: const Color(0XFFF1EFEF),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: const Color(0XFF7E7E7E), size: screenWidth * 0.05),
                      const SizedBox(width: 8),
                      Text('Search', style: TextStyle(color: const Color(0XFF7E7E7E), fontSize: screenWidth * 0.042)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0XFFE8E8E8)),
            const SizedBox(height: 16),
            // _buildDrawerItem(
            //   icon: 'assets/images/new_app_logo.png',
            //   title: 'Vitty',
            //   isActive: _selectedItem == 'Vitty',
            //   // onTap: () => _handleTap('Vitty', () {
            //   //   Navigator.of(context).pushReplacement(
            //   //     MaterialPageRoute(
            //   //       builder: (_) => DashboardScreen(),
            //   //     ),
            //   //   );
            //   //   widget.onCreateNewChat!.call();
            //   // }),
            //   onTap: () => _handleTap('Vitty', () {
            //     Navigator.of(context).pushReplacement(
            //       PageRouteBuilder(
            //         pageBuilder: (context, animation, secondaryAnimation) => DashboardScreen(),
            //         transitionsBuilder: (context, animation, secondaryAnimation, child) {
            //           return FadeTransition(
            //             opacity: animation,
            //             child: child,
            //           );
            //         },
            //         transitionDuration: const Duration(milliseconds: 500),
            //       ),
            //     );
            //
            //   }),
        _buildDrawerItem(
          icon: 'assets/images/new_app_logo.png',
          title: 'Vitty',
          isActive: _selectedItem == 'Vitty',
          onTap: () {
            if (_selectedItem == 'Vitty') {
              Navigator.pop(context); // Already on Vitty
            } else {
              _handleTap('Vitty', () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => DashboardScreen()),
                );
              });
            }
          },


        ),
            _buildDrawerItem(
              icon: "assets/images/port.png",
              title: 'Portfolio',
              isActive: _selectedItem == 'Portfolio',
              onTap: () => _handleTap('Portfolio', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const Assets()));
              }),
            ),
            _buildDrawerItem(
              icon: "assets/images/Vector.svg",
              title: 'Goals',
              isActive: _selectedItem == 'Goals',
              onTap: () => _handleTap('Goals', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => GoalsPage()));
              }),
            ),
            _buildDrawerItem(
              icon: "assets/images/Vector.png",
              title: 'Conversations',
              isActive: _selectedItem == 'Conversations',
              onTap: () => _handleTap('Conversations', () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 100), () async {
                  final selectedSession = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Conversations(
                        onSessionTap: widget.onSessionTap ?? (_) {}, // ✅ fallback to empty function
                      ),

                    ),
                  );
                  if (selectedSession is ChatSession) {
                    widget.onSessionTap?.call(selectedSession);
                  }
                });
              }),
            ),
            const Spacer(),
            const DrawerFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required String icon,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isSvg = icon.toLowerCase().endsWith('.svg');
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: InkWell(
        splashColor: Colors.transparent,       // ✅ disables ripple
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 6,
              height: screenHeight * 0.085,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.005,
                ),
                child: Row(
                  children: [
                    isSvg
                        ? SvgPicture.asset(icon, height: screenWidth * 0.055, width: screenWidth * 0.055, color: isActive ? AppColors.primary : theme.icon)
                        : Image.asset(icon, height: screenWidth * 0.06, width: screenWidth * 0.06, color: isActive ? AppColors.primary : theme.icon),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: screenWidth * 0.045,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          color: isActive ? AppColors.primary : theme.text,
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
    );
  }
}





class SearchBar extends StatelessWidget {
  const SearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = locator<ThemeService>().currentTheme;
    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: 20),
          child: Column(
            children: [
              Row(
                children: [
                   BackButton(color: theme.icon),
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search stocks, assets, goals...',
                        hintStyle: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: theme.shadow,
                        ),
                        filled: true,
                        fillColor: theme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Add search results or suggestions here
              const Text("Search results go here..."),
            ],
          ),
        ),
      ),
    );
  }
}





class DrawerFooter extends StatefulWidget {
  const DrawerFooter({super.key});

  @override
  State<DrawerFooter> createState() => _DrawerFooterState();
}

class _DrawerFooterState extends State<DrawerFooter> {
  final AuthService _authService = locator<AuthService>();
  final SecurityService _securityService = locator<SecurityService>();

  late StreamSubscription<AuthState> _sub;
  String fullName = "User";
  bool isBiometricEnabled = false;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();

    final user = _authService.currentState.user;
    if (user != null) {
      fullName = "${user.firstName ?? ''} ${user.lastName ?? ''}".trim();
    }

    _sub = _authService.authStateStream.listen((state) {
      final user = state.user;
      if (user != null) {
        setState(() {
          fullName = "${user.firstName ?? ''} ${user.lastName ?? ''}".trim();
        });
      }
    });

    _loadTogglePrefs();
    _loadBiometricStatus();
  }
  void _loadBiometricStatus() async {
    final status = await _securityService.isBiometricEnabledAsync();
    setState(() {
      isBiometricEnabled = status;
    });
  }
  Future<void> _loadTogglePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      isDarkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  Future<void> _enableBiometrics() async {
    final success = await _securityService.authenticate();
    if (success) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('biometric_enabled', true);
      setState(() {
        isBiometricEnabled = true;
      });
    } else {
      setState(() {
        isBiometricEnabled = false;
      });

      if (mounted) {
        // Fluttertoast.showToast(
        //   msg: "Biometric authentication failed or was cancelled.",
        //   toastLength: Toast.LENGTH_SHORT,
        //   gravity: ToastGravity.TOP,
        //   backgroundColor: Colors.black87,
        //   textColor: Colors.white,
        //   fontSize: 14.0,
        // );

      }
    }
  }



  void _navigateTo(String route) {
    if (!mounted) return;
    GoRouter.of(rootNavigatorKey.currentContext!).go('/phone_otp');

  }


  void _showLogoutMenu(BuildContext context) {
    Future.microtask(() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Enable Biometric'),
                  value: isBiometricEnabled,
                  onChanged: (value) async {
                    // Close drawer before showing Snackbar (for visibility)
                    Navigator.pop(context);

                    // Let drawer fully close before continuing
                    await Future.delayed(const Duration(milliseconds: 300));

                    final updated = await _securityService.toggleBiometric(value, context);

                    if (mounted) {
                      setState(() {
                        isBiometricEnabled = updated;
                      });
                    }
                  },
                ),


                // SwitchListTile(
                //   title: const Text('Dark Mode'),
                //   value: isDarkMode,
                //   onChanged: (value) {
                //     locator<ThemeService>().toggleTheme(value);
                //   },
                // ),
                StreamBuilder<bool>(
                  stream: locator<ThemeService>().isDarkModeStream, // expose isDarkMode as stream
                  builder: (context, snapshot) {
                    final isDarkMode = snapshot.data ?? false;

                    return SwitchListTile(
                      title: Text(isDarkMode ? 'Dark Mode' : 'Light Mode'),
                      value: isDarkMode,
                      onChanged: (value) {
                        locator<ThemeService>().toggleTheme(value);
                      },
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmLogout(context);
                  },
                ),
              ],
            ),
          );
        },
      );
    });
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
                backgroundColor: Colors.red,
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

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initials = fullName.isNotEmpty ? fullName[0].toUpperCase() : '';
    final theme = locator<ThemeService>().currentTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0XFFC4765E),
            child: Text(initials, style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Text(
            fullName,
            style:  TextStyle(
              color: theme.text,
              fontWeight: FontWeight.w500,
              fontSize: 16,
              fontFamily: 'DM Sans',
            ),
          ),
          const Spacer(),
          IconButton(
            icon:  Icon(Icons.more_horiz, color: theme.icon),
            onPressed: () => _showLogoutMenu(context),
          ),
        ],
      ),
    );
  }
}







// class Conversations extends StatefulWidget {
//   final ChatService chatService;
//   final Function(ChatSession) onSessionTap;
//   final VoidCallback onCreateNewChat;
//   const Conversations({super.key, required this.chatService, required this.onSessionTap,});
//
//   @override
//   State<Conversations> createState() => _ConversationsState();
// }
//
// class _ConversationsState extends State<Conversations> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(100),
//         child: Builder(
//           builder: (context) => appBar(context, "Converations", (){},false),
//         ),
//       ),
//     floatingActionButton: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
//         child: FloatingActionButton(
//           onPressed: () {
//             Navigator.pop(context);
//             widget.onCreateNewChat();
//           },
//           backgroundColor: Colors.black,
//           child: SvgPicture.asset('assets/images/addnewchat.svg'),
//           shape: const CircleBorder(),
//           elevation: 4,
//         ),
//       ),
//       body: FutureBuilder<List<ChatSession>>(
//         future: widget.chatService.fetchSessions(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (snapshot.hasError) {
//             return const Center(child: Text('Error loading sessions'));
//           }
//
//           final sessions = snapshot.data ?? [];
//
//           if (sessions.isEmpty) {
//             return const Center(child: Text('No conversations yet.'));
//           }
//
//           return ListView.builder(
//             itemCount: sessions.length,
//             itemBuilder: (context, index) {
//               final session = sessions[index];
//               return ListTile(
//                 title: Text(session.title),
//                 trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                 onTap: () {
//                   if (Navigator.canPop(context)) {
//                     Navigator.pop(context);
//                   }
//                   // Close AllChatsPage
//                   Future.delayed(Duration(milliseconds: 100), () {
//                     if (mounted) {
//                       setState(() {
//                        widget.onSessionTap(session);
//                       });
//                     }
//                   });
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }









