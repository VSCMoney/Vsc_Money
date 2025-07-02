import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vscmoney/screens/presentation/home/home_screen.dart';
import 'package:vscmoney/services/locator.dart';

import '../../../constants/colors.dart';
import '../../../controllers/auth_controller.dart';
import '../../../routes/AppRoutes.dart';
import '../../../services/auth_service.dart';
import '../../../services/theme_service.dart';
 // Replace with your home screen route

// class EnterNameScreen extends StatefulWidget {
//   const EnterNameScreen({super.key});
//
//   @override
//   State<EnterNameScreen> createState() => _EnterNameScreenState();
// }
//
// class _EnterNameScreenState extends State<EnterNameScreen> {
//   final TextEditingController _fullNameController = TextEditingController();
//   bool isLoading = false;
//
//   void _submitName() async {
//     final fullName = _fullNameController.text.trim();
//     if (fullName.isEmpty || !fullName.contains(" ")) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please enter full name (first & last)")),
//       );
//       return;
//     }
//
//     final parts = fullName.split(" ");
//     final firstName = parts.first;
//     final lastName = parts.sublist(1).join(" ");
//
//     setState(() => isLoading = true);
//     final auth = Provider.of<AuthController>(context, listen: false);
//     await auth.completeUserProfile(firstName, lastName);
//     setState(() => isLoading = false);
//
//     if (auth.error == null) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const DashboardScreen()),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(auth.error ?? "Something went wrong")),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
//           child: Column(
//             children: [
//               SizedBox(height: screenHeight * 0.05),
//               Hero(
//                 tag: 'penny_logo',
//                 child: Column(
//                   children: [
//                     Image.asset(
//                       'assets/images/auth.png',
//                       width: screenWidth * 0.2,
//                       height: screenHeight * 0.1,
//                     ),
//                   ],
//                 ),
//               ),
//               // const SizedBox(height: 64),
//               // const Text(
//               //   "Enter Your Name",
//               //   style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//               // ),
//               // const SizedBox(height: 12),
//               // Padding(
//               //   padding:  EdgeInsets.symmetric(horizontal:44.0),
//               //   child: const Text(
//               //     "Even the smartest AI likes to know who it’s talking to.",
//               //     textAlign: TextAlign.center,
//               //     style: TextStyle(fontSize: 14, color: Colors.black54),
//               //   ),
//               // ),
//               // Image.asset(
//               //   'assets/images/Vitty.ai.png',
//               //   width: screenWidth * 0.28,
//               //   height: screenHeight * 0.05,
//               // ),
//               SizedBox(height: screenHeight * 0.090),
//               // Text(
//               //   "Enter Your Name",
//               //   textAlign: TextAlign.center,
//               //   style: TextStyle(
//               //     fontSize: screenWidth * 0.06,
//               //     fontWeight: FontWeight.w500,
//               //     fontFamily: "Inter",
//               //   ),
//               // ),
//               SizedBox(height: screenHeight * 0.060),
//               // Padding(
//               //   padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
//               //   child: Text(
//               //     "Even the smartest AI likes to know who it’s talking to.",
//               //     textAlign: TextAlign.center,
//               //     style: TextStyle(
//               //       fontSize: screenWidth * 0.04,
//               //       fontWeight: FontWeight.w400,
//               //       fontFamily: 'SF Pro Text',
//               //       color: Colors.black87,
//               //     ),
//               //   ),
//               // ),
//               SizedBox(height: screenHeight * 0.01),
//               const SizedBox(height: 22),
//               Column(
//                 children: [
//                   Row(
//                     children: [
//                       Text(
//                         "What should Vitty call you?",
//                         style: TextStyle(
//                           fontSize: screenWidth * 0.042,
//                           fontWeight: FontWeight.w400,
//                           fontFamily: 'SF Pro Text',
//                           color: Colors.black,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   // TextField(
//                   //   controller: _fullNameController,
//                   //   decoration: InputDecoration(
//                   //     hintText: "Full Name",
//                   //     border: OutlineInputBorder(
//                   //       borderSide: BorderSide(
//                   //         color: Colors.black,
//                   //         width: 0.1
//                   //       ),
//                   //       borderRadius: BorderRadius.circular(8),
//                   //     ),
//                   //   ),
//                   // ),
//                   TextField(
//                     controller: _fullNameController,
//                     keyboardType: TextInputType.text,
//                     decoration: InputDecoration(
//                       hintText: 'Your Full Name',
//                       hintStyle: TextStyle(
//                         color: Colors.grey.shade500,
//                         fontSize: screenWidth * 0.04,
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(5),
//                         borderSide: const BorderSide(
//                           color: Colors.black54,
//                           width: 2,
//                         ),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(5),
//                         borderSide: BorderSide(
//                           color: Colors.grey.withOpacity(0.6),
//                           width: 1.5,
//                         ),
//                       ),
//                       contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
//                       filled: true,
//                       fillColor: Colors.white,
//                     ),
//                     style: TextStyle(fontSize: screenWidth * 0.045),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 24),
//
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: isLoading ? null : _submitName,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.blackButton,
//                     padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: isLoading
//                       ? const SizedBox(
//                     width: 24,
//                     height: 24,
//                     child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
//                   )
//                       : Text(
//                     "Continue",
//                     style: TextStyle(
//                       fontSize: screenWidth * 0.045,
//                       color: Colors.white,
//                       fontFamily: "SF Pro Text",
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




class EnterNameScreen extends StatefulWidget {
  const EnterNameScreen({super.key});

  @override
  State<EnterNameScreen> createState() => _EnterNameScreenState();
}

class _EnterNameScreenState extends State<EnterNameScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final AuthService _authService = locator<AuthService>();

  late StreamSubscription<AuthState> _stateSub;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    _stateSub = _authService.authStateStream.listen((state) {
      if (!mounted) return;

      setState(() => isLoading = state.status == AuthStatus.loading);

      if (state.status == AuthStatus.error && state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
      }
    });
  }

  void _submitName() async {
    final fullName = _fullNameController.text.trim();
    if (fullName.isEmpty || !fullName.contains(" ")) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter full name (first & last)")),
      );
      return;
    }

    final parts = fullName.split(" ");
    final firstName = parts.first;
    final lastName = parts.sublist(1).join(" ");

    await _authService.completeUserProfile(firstName, lastName);

    if (!mounted) return; // <- ADD THIS

    _authService.completeUserProfileAndNavigate((flow) {
      if (!mounted) return; // <- ADD THIS TOO
      switch (flow) {
        case AuthFlow.home:
          GoRouter.of(context).go('/home');
          break;
        case AuthFlow.nameEntry:
          break;
        case AuthFlow.login:
          context.go('/home');
          break;
      }
    });
  }


  @override
  void dispose() {
    _fullNameController.dispose();
    _stateSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.05),
              Hero(
                tag: 'penny_logo',
                child: Image.asset(
                  'assets/images/auth.png',
                  width: screenWidth * 0.2,
                  height: screenHeight * 0.1,
                ),
              ),
              SizedBox(height: screenHeight * 0.15),
              Row(
                children: [
                  Text(
                    "What should Vitty call you?",
                    style: TextStyle(
                      fontSize: screenWidth * 0.042,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'SF Pro Text',
                      color: theme.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _fullNameController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Your Full Name',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: screenWidth * 0.04,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide:  BorderSide(color: theme.border, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide(color: theme.border, width: 1.5),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  filled: true,
                  fillColor: theme.background,
                ),
                style: TextStyle(fontSize: screenWidth * 0.045,color: theme.text),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitName,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text(
                    "Continue",
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      color: Colors.white,
                      fontFamily: "SF Pro Text",
                      fontWeight: FontWeight.w500,
                    ),
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
