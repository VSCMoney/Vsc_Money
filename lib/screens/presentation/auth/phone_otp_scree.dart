import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/colors.dart';
import '../../../controllers/auth_controller.dart';
import '../../../services/auth_service.dart';
import '../../../services/locator.dart';
import '../../../services/theme_service.dart';
import '../../widgets/auth_button.dart';
import 'otp_screen.dart';

// class PhoneOtpScreen extends StatefulWidget {
//   const PhoneOtpScreen({super.key});
//
//   @override
//   State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
// }
//
// class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
//   final _phoneController = TextEditingController();
//   bool isLoading = false;
//   bool isPhoneMode = false;
//
//   @override
//   void dispose() {
//     _phoneController.dispose();
//     super.dispose();
//   }
//
//   void _handleGetOtp() {
//     final phone = _phoneController.text.trim();
//     if (phone.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please enter a valid phone number")),
//       );
//       return;
//     }
//
//     // Format phone number properly (with country code)
//     final fullPhone = phone.startsWith("+") ? phone : "+91$phone"; // Assuming India
//
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => OtpVerification(phoneNumber: fullPhone),
//       ),
//     );
//   }
//
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0),
//           child: Column(
//             children: [
//               const SizedBox(height: 30),
//               Hero(
//                 tag: 'penny_logo',
//                 child: Column(
//                   children: [
//                     // SvgPicture.asset('assets/images/Vitty_logo.svg', height: 80),
//                     // const SizedBox(height: 8),
//                     // const Text(
//                     //   "Vitty.ai",
//                     //   style: TextStyle(
//                     //     fontSize: 28,
//                     //     fontWeight: FontWeight.bold,
//                     //     color: Colors.orange,
//                     //   ),
//                     // ),
//                     Image.asset('assets/images/new_app_logo.png', width:80, height: 50),
//                    // const SizedBox(width: 16),
//                   ],
//                 ),
//               ),
//               Image.asset('assets/images/Vitty.ai.png', width: 80, height: 50),
//               const SizedBox(height: 64),
//               const Text(
//                 "Your AI Financial Consultant",
//                 style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500,fontFamily: "Inter"),
//               ),
//               const SizedBox(height: 12),
//               Padding(
//                 padding:  EdgeInsets.symmetric(horizontal:24.0),
//                 child: const Text(
//                   "Where smart advice meets zero awkward phone calls.",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 15, color: Colors.black,fontWeight: FontWeight.w400,fontFamily: 'SF Pro Text'),
//                 ),
//               ),
//               const SizedBox(height: 32),
//               Column(
//                 children: [
//                   Row(
//                     children: [
//                       Text(
//                         "Phone Number*",
//                         textAlign: TextAlign.center,
//                         style: TextStyle(fontSize: 15, color: Colors.black,fontWeight: FontWeight.w400,fontFamily: 'SF Pro Text'),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   TextField(
//                     controller: _phoneController,
//                     keyboardType: TextInputType.phone,
//                     decoration: InputDecoration(
//                       hintText: 'Phone number',
//                       hintStyle: TextStyle(
//                         color: Colors.grey.shade500,
//                       ),
//                       prefixIcon: Padding(
//                         padding: const EdgeInsets.only(left: 12, right: 8),
//                         child: Text(
//                           '+91',
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.black,
//                             fontWeight: FontWeight.w500,
//                             fontFamily: 'SF Pro Text'
//                           ),
//                         ),
//                       ),
//                       prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(5),
//                         borderSide: BorderSide(
//                           color: Colors.black54, // Purple on focus
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
//                       contentPadding: EdgeInsets.symmetric(horizontal: 10),
//                       filled: true,
//                       fillColor: Colors.white,
//                     ),
//                     style: TextStyle(fontSize: 15),
//                   )
//
//                 ],
//               ),
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: isLoading ? null : _handleGetOtp,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.blackButton,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text("Get OTP", style: TextStyle(fontSize: 16,color: Colors.white,fontFamily: "SF Pro Text",fontWeight: FontWeight.w500)),
//                 ),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }



class PhoneOtpScreen extends StatefulWidget {
  const PhoneOtpScreen({super.key});

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  final _phoneController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
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

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _handleGetOtp() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid phone number")),
      );
      return;
    }

    final fullPhone = phone.startsWith("+") ? phone : "+91$phone";
    FocusScope.of(context).unfocus();

    // Navigator.push(
    //   context,

    //   MaterialPageRoute(
    //     builder: (_) => OtpVerification(phoneNumber: fullPhone),
    //   ),
    GoRouter.of(context).go('/otp', extra: {'phone': fullPhone}


    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
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
        child: SingleChildScrollView(
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
                SizedBox(height: screenHeight * 0.07),
                Text(
                  "Your AI Financial Consultant",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.w500,
                    fontFamily: "Inter",
                  ),
                ),
                SizedBox(height: screenHeight * 0.010),
                Text(
                  "Super Intelligent. Bias Free. Always Available.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'SF Pro Text',
                    color: theme.text,
                  ),
                ),
                SizedBox(height: screenHeight * 0.06),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isLoading
                        ? Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.border ?? Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                        color: theme.background,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFF666666),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    )
                        : AuthButton(
                      icon: Image.asset('assets/images/Group 10.png', height: 18),
                      label: 'Continue with Google',
                      onTap: () async {
                        await locator<AuthService>().handleGoogleSignIn((flow) {
                          if (!mounted) return;
                          if (flow == AuthFlow.home) {
                            context.go('/home');
                          } else if (flow == AuthFlow.nameEntry) {
                            context.go('/enter_name');
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    AuthButton(
                      icon: Icon(Icons.apple,color: Colors.black,size: 24,),
                      label: 'Continue with Apple',
                      onTap: () async {}
                    ),
                   const SizedBox(height: 16),
                    // Text(
                    //   "Phone Number*",
                    //   style: TextStyle(
                    //     fontSize: screenWidth * 0.042,
                    //     fontWeight: FontWeight.w400,
                    //     fontFamily: 'SF Pro Text',
                    //     color: theme.text,
                    //   ),
                    // ),
                    // SizedBox(height: screenHeight * 0.01),
                    // SizedBox(
                    //   height: screenHeight * 0.060,
                    //   child: TextField(
                    //     maxLength: 10,
                    //     textInputAction: TextInputAction.done,
                    //     onChanged: (value) {
                    //       if (value.length == 10) {
                    //         FocusScope.of(context).unfocus();
                    //       }
                    //     },
                    //     focusNode: _focusNode,
                    //     controller: _phoneController,
                    //     keyboardType: TextInputType.number,
                    //     decoration: InputDecoration(
                    //       counterText: "",
                    //       hintText: 'Phone number',
                    //       hintStyle: TextStyle(
                    //         color: theme.text,
                    //         fontSize: screenWidth * 0.04,
                    //       ),
                    //       prefixIcon: Padding(
                    //         padding: const EdgeInsets.only(left: 12, right: 8),
                    //         child: Text(
                    //           '+91',
                    //           style: TextStyle(
                    //             fontSize: screenWidth * 0.040,
                    //             fontWeight: FontWeight.w500,
                    //             fontFamily: 'SF Pro Text',
                    //             color: theme.text,
                    //           ),
                    //         ),
                    //       ),
                    //       prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0.005),
                    //       focusedBorder: OutlineInputBorder(
                    //         borderRadius: BorderRadius.circular(5),
                    //         borderSide:  BorderSide(color: theme.secondaryText, width: 2),
                    //       ),
                    //       enabledBorder: OutlineInputBorder(
                    //         borderRadius: BorderRadius.circular(5),
                    //         borderSide: BorderSide(color: Colors.grey.withOpacity(0.6), width: 1.5),
                    //       ),
                    //       contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04,vertical: 1),
                    //       filled: true,
                    //       fillColor: theme.background,
                    //     ),
                    //     style: TextStyle(
                    //       fontSize: screenWidth * 0.040,
                    //       fontWeight: FontWeight.w500,
                    //       fontFamily: 'SF Pro Text',
                    //       color: theme.text,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),
                // SizedBox(
                //   height: screenHeight * 0.060,
                //   width: double.infinity,
                //   child: ElevatedButton(
                //     onPressed: isLoading ? null : _handleGetOtp,
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: AppColors.primary,
                //       padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(8),
                //       ),
                //     ),
                //     child: isLoading
                //         ? const SizedBox(
                //       width: 24,
                //       height: 24,
                //       child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                //     )
                //         : Text(
                //       "Continue",
                //       style: TextStyle(
                //         fontSize: screenWidth * 0.045,
                //         color: Colors.white,
                //         fontFamily: "SF Pro Text",
                //         fontWeight: FontWeight.w500,
                //       ),
                //     ),
                //   ),
                // ),
                SizedBox(height: screenHeight * 0.3),

                // ✅ ADDED TERMS & CONDITIONS
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontFamily: 'SF Pro Text',
                        color: theme.text.withOpacity(0.7),
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: "By continuing, you agree to our "),
                        TextSpan(
                          text: "Terms & Conditions",
                          style: TextStyle(
                            color: Color(0xFFFF8A00), // Orange color
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // ✅ Handle Terms & Conditions tap
                            //  _showTermsAndConditions();
                            },
                        ),
                        const TextSpan(text: " and "),
                        TextSpan(
                          text: "Privacy Policy",
                          style: TextStyle(
                            color: Color(0xFFFF8A00), // Orange color
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // ✅ Handle Privacy Policy tap
                            //  _showPrivacyPolicy();
                            },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

