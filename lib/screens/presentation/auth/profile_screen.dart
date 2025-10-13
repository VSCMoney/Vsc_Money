import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vscmoney/screens/presentation/home/home_screen.dart';
import 'package:vscmoney/services/locator.dart';

import '../../../constants/colors.dart';
import '../../../routes/AppRoutes.dart';
import '../../../services/auth_service.dart';
import '../../../services/theme_service.dart';


import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';


class EnterNameScreen extends StatefulWidget {
  const EnterNameScreen({super.key});

  @override
  State<EnterNameScreen> createState() => _EnterNameScreenState();
}

class _EnterNameScreenState extends State<EnterNameScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final AuthService _authService = locator<AuthService>();

  late final StreamSubscription<AuthState> _stateSub;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _stateSub = _authService.authStateStream.listen((state) {
      if (!mounted) return;
      setState(() => isLoading = state.status == AuthStatus.loading);
      if (state.status == AuthStatus.error && state.error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.error!)));
      }
    });
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _submitName() async {
    HapticFeedback.selectionClick();
    final fullName = _fullNameController.text.trim();

    if (fullName.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }

    // strict rule: exactly 2 words, letters only
    final parts = fullName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length != 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            parts.length == 1
                ? 'Please enter both first and last name'
                : 'Please enter only first and last name (2 words maximum)',
          ),
        ),
      );
      return;
    }
    if (!RegExp(r'^[A-Za-z]+$').hasMatch(parts[0]) ||
        !RegExp(r'^[A-Za-z]+$').hasMatch(parts[1])) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name should contain only letters')),
      );
      return;
    }

    final firstName = parts[0];
    final lastName = parts[1];

    await _authService.completeUserProfile(firstName, lastName);
    if (!mounted) return;

    _authService.completeUserProfileAndNavigate((flow) {
      if (!mounted) return;
      switch (flow) {
        case AuthFlow.onboarding:
          context.go('/onboarding');
          break;
        case AuthFlow.home:
          final safe = Uri.encodeComponent(firstName);
          context.go('/warm/$safe'); // ✅ /warm/:name
          break;
        case AuthFlow.nameEntry:
        // stay
          break;
        case AuthFlow.login:
          context.go('/home');
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: mq.size.width * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: mq.size.height * 0.05),

              // ✅ one Hero or two unique tags (no duplicate)
              Hero(
                tag: 'penny_logo', // use same tag on the source/target screen
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/ying yang.png',
                      width: mq.size.width * 0.9,
                      height: mq.size.height * 0.08,
                    ),
                  //  const SizedBox(height: 8),
                    Image.asset(
                      'assets/images/Vitty.ai2.png',
                      width: mq.size.width * 0.3,
                      height: mq.size.height * 0.1,
                    ),
                  ],
                ),
              ),

              SizedBox(height: mq.size.height * 0.08),

              Text(
                'What should Vitty call you?',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: mq.size.width * 0.042,
                  fontWeight: FontWeight.w400,
                  color: theme.text,
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _fullNameController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => isLoading ? null : _submitName(),
                decoration: InputDecoration(
                  hintText: 'Your Full Name',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: mq.size.width * 0.04,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.searchBox, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.searchBox, width: 1.5),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: mq.size.width * 0.04,
                    vertical: 14,
                  ),
                  filled: true,
                  fillColor: theme.background,
                ),
                style: TextStyle(
                  fontSize: mq.size.width * 0.045,
                  color: theme.text,
                ),
              ),
              SizedBox(height: 20,),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitName,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Continue'),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}


// class EnterNameScreen extends StatefulWidget {
//   const EnterNameScreen({super.key});
//
//   @override
//   State<EnterNameScreen> createState() => _EnterNameScreenState();
// }
//
// class _EnterNameScreenState extends State<EnterNameScreen> {
//   final TextEditingController _fullNameController = TextEditingController();
//   final AuthService _authService = locator<AuthService>();
//
//   late StreamSubscription<AuthState> _stateSub;
//   bool isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _stateSub = _authService.authStateStream.listen((state) {
//       if (!mounted) return;
//
//       setState(() => isLoading = state.status == AuthStatus.loading);
//
//       if (state.status == AuthStatus.error && state.error != null) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
//       }
//     });
//   }
//
//
//
//
//   // void _submitName() async {
//   //   final fullName = _fullNameController.text.trim();
//   //
//   //   // Check if name is empty
//   //   if (fullName.isEmpty) {
//   //     if (!mounted) return;
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(content: Text("Please enter your full name")),
//   //     );
//   //     return;
//   //   }
//   //
//   //   // Split the name into parts and filter out empty strings
//   //   final parts = fullName.split(" ").where((part) => part.isNotEmpty).toList();
//   //
//   //   // Check if exactly 2 words (first name and last name only)
//   //   if (parts.length != 2) {
//   //     if (!mounted) return;
//   //     String errorMessage;
//   //     if (parts.length == 1) {
//   //       errorMessage = "Please enter both first and last name";
//   //     } else {
//   //       errorMessage = "Please enter only first and last name (2 words maximum)";
//   //     }
//   //
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(content: Text(errorMessage)),
//   //     );
//   //     return;
//   //   }
//   //
//   //   // Validate that each part contains only letters (optional - remove if you want to allow numbers/special chars)
//   //   for (final part in parts) {
//   //     if (!RegExp(r'^[a-zA-Z]+$').hasMatch(part)) {
//   //       if (!mounted) return;
//   //       ScaffoldMessenger.of(context).showSnackBar(
//   //         const SnackBar(content: Text("Name should contain only letters")),
//   //       );
//   //       return;
//   //     }
//   //   }
//   //
//   //   final firstName = parts[0];
//   //   final lastName = parts[1];
//   //
//   //   await _authService.completeUserProfile(firstName, lastName);
//   //
//   //   if (!mounted) return;
//   //
//   //   _authService.completeUserProfileAndNavigate((flow) {
//   //     if (!mounted) return;
//   //     switch (flow) {
//   //       case AuthFlow.onboarding:
//   //         context.go('/onboarding');
//   //         break;
//   //       case AuthFlow.home:
//   //         GoRouter.of(context).go('/warm${firstName}');
//   //         break;
//   //       case AuthFlow.nameEntry:
//   //         break;
//   //       case AuthFlow.login:
//   //         context.go('/home');
//   //         break;
//   //     }
//   //   });
//   // }
//
//
//
//
//   @override
//   void dispose() {
//     _fullNameController.dispose();
//     _stateSub.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
//     return Scaffold(
//       backgroundColor: theme.background,
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
//           child: Column(
//             children: [
//               SizedBox(height: screenHeight * 0.05),
//               Column(
//                 children: [
//                   Hero(
//                     tag: 'penny_logo',
//                     child: Image.asset(
//                       'assets/images/ying yang.png',
//                       width: screenWidth * 0.4,
//                       height: screenHeight * 0.09,
//                     ),
//                   ),
//                   Hero(
//                     tag: 'penny_logo',
//                     child: Image.asset(
//                       'assets/images/Vitty.ai2.png',
//                       width: screenWidth * 0.2,
//                       height: screenHeight * 0.1,
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: screenHeight * 0.10),
//               Row(
//                 children: [
//                   Text(
//                     "What should Vitty call you?",
//                     style: TextStyle(
//                       fontSize: screenWidth * 0.042,
//                       fontWeight: FontWeight.w400,
//                       fontFamily: 'DM Sans',
//                       color: theme.text,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: _fullNameController,
//                 keyboardType: TextInputType.text,
//                 decoration: InputDecoration(
//                   hintText: 'Your Full Name',
//                   hintStyle: TextStyle(
//                     color: Colors.grey.shade500,
//                     fontSize: screenWidth * 0.04,
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(5),
//                     borderSide:  BorderSide(color: theme.searchBox, width: 2),
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(5),
//                     borderSide: BorderSide(color: theme.searchBox, width: 1.5),
//                   ),
//                   contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
//                   filled: true,
//                   fillColor: theme.background,
//                 ),
//                 style: TextStyle(fontSize: screenWidth * 0.045,color: theme.text),
//               ),
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: isLoading ? null : _submitName,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.primary,
//                     padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                   ),
//                   child: isLoading
//                       ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
//                       : Text(
//                     "Continue",
//                     style: TextStyle(
//                       fontSize: screenWidth * 0.045,
//                       color: Colors.white,
//                       fontFamily: "DM Sans",
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
