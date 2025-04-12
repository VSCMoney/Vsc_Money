import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:vscmoney/screens/presentation/auth/otp_screen.dart';

import '../../widgets/auth_button.dart';
import '../../widgets/common_button.dart';

// class AuthScreen extends StatefulWidget {
//   const AuthScreen({super.key});
//
//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }
//
// class _AuthScreenState extends State<AuthScreen> {
//   bool isPhoneMode = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: LayoutBuilder(
//         builder: (context, constraints) {
//           return Scaffold(
//             resizeToAvoidBottomInset: true,
//             backgroundColor: Colors.white,
//             body: SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     const SizedBox(height: 48),
//                     // Logo + App Name
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Image.asset('assets/images/Group.png', height: 34, width: 34),
//                         const SizedBox(width: 8),
//                         const Text(
//                           "Penny",
//                           style: TextStyle(
//                             fontSize: 28,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 48),
//                     const Text(
//                       'Invest, Save\nThrive',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 42,
//                         fontWeight: FontWeight.w500,
//                         fontStyle: FontStyle.normal,
//                         color: Colors.black,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     const Text(
//                       'AI-Driven Financial Guidance',
//                       style: TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.w400,
//                         fontStyle: FontStyle.normal,
//                         color: Colors.black,
//                       ),
//                     ),
//                     const SizedBox(height: 48),
//
//                     // Continue with Google button (always visible)
//                     AuthButton(
//                       icon: Image.asset('assets/images/Group 10.png', height: 18),
//                       label: 'Continue with Google',
//                       onTap: () {},
//                     ),
//                     const SizedBox(height: 16),
//
//                     // Conditional toggle area below Google button
//                     if (!isPhoneMode) ...[
//                       // Email Mode
//                       AuthButton(
//                         icon: const Icon(Icons.call_outlined),
//                         label: 'Continue with phone',
//                         onTap: () {
//                           setState(() {
//                             isPhoneMode = true;
//                           });
//                         },
//                       ),
//                       const SizedBox(height: 16),
//                       const Text('OR', style: TextStyle(fontWeight: FontWeight.w500)),
//                       const SizedBox(height: 16),
//                       TextField(
//                         decoration: InputDecoration(
//                           hintText: 'Enter your email',
//                           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(32),
//                             borderSide: const BorderSide(color: Colors.grey),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       CommonButton(
//                         label: 'Continue',
//                         onPressed: () {
//                           // Navigator.pushReplacement(
//                           //             context,
//                           //             MaterialPageRoute(builder: (context) => const OtpVerificationScreen()),
//                           //           );
//                           context.goNamed('otp');
//                         },
//                       ),
//                     ] else ...[
//                       // Phone Mode
//                       const Text('OR', style: TextStyle(fontWeight: FontWeight.w500)),
//                       const SizedBox(height: 16),
//                       Row(
//                         children: [
//                           Expanded(
//                             flex: 2,
//                             child: Container(
//                               height: 48,
//                               decoration: BoxDecoration(
//                                 border: Border.all(color: Colors.grey),
//                                 borderRadius: BorderRadius.circular(32),
//                               ),
//                               child: const Center(
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Text('+1'),
//                                     Icon(Icons.keyboard_arrow_down, size: 18),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             flex: 5,
//                             child: TextField(
//                               keyboardType: TextInputType.phone,
//                               decoration: InputDecoration(
//                                 hintText: 'Phone number',
//                                 contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(32),
//                                   borderSide: const BorderSide(color: Colors.grey),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 16),
//                       CommonButton(
//                         label: 'Get OTP',
//                         onPressed: () {
//                           // Navigator.pushReplacement(
//                           //   context,
//                           //   MaterialPageRoute(builder: (context) => const OtpVerificationScreen()),
//                           // );
//                          // _sendOtp('+91${phoneController.text}');
//                           context.goNamed('otp',extra: "");
//                         },
//                       ),
//                       const SizedBox(height: 16),
//
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }



class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  bool isLoading = false;
  bool isPhoneMode = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleGetOtp() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid phone number")),
      );
      return;
    }

    // Format phone number properly (with country code)
    final fullPhone = phone.startsWith("+") ? phone : "+91$phone"; // Assuming India

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerification(phoneNumber: fullPhone),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  // Logo + App Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset('assets/images/Vitty_logo.svg', height: 34, width: 34),
                      const SizedBox(width: 8),
                      const Text(
                        "Vitty.ai",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  const Text(
                    'Invest, Save\nThrive',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.normal,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'AI-Driven Financial Guidance',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.normal,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Continue with Google button (always visible)
                  AuthButton(
                    icon: Image.asset('assets/images/Group 10.png', height: 18),
                    label: 'Continue with Google',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),

                  // Conditional toggle area below Google button
                  if (!isPhoneMode) ...[
                    // Email Mode
                    AuthButton(
                      icon: const Icon(Icons.call_outlined),
                      label: 'Continue with phone',
                      onTap: () {
                        setState(() {
                          isPhoneMode = true;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('OR', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CommonButton(
                      label: 'Continue',
                      onPressed: () {
                        // Navigator.pushReplacement(
                        //             context,
                        //             MaterialPageRoute(builder: (context) => const OtpVerificationScreen()),
                        //           );
                        context.goNamed('otp');
                      },
                    ),
                  ] else ...[
                    // Phone Mode
                    const Text('OR', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 16),
                    Row(
                      children: [

                        Expanded(
                          flex: 5,
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: 'Phone number',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(32),
                                borderSide: const BorderSide(color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CommonButton(
                      label: 'Get OTP',
                      onPressed: () {

                       isLoading? null : _handleGetOtp();
                      },
                    ),
                    const SizedBox(height: 16),

                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}



