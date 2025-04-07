import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:vscmoney/screens/presentation/home/home_screen.dart';

import '../../../controllers/auth_controller.dart';
import '../../../services/auth_service.dart';
import '../../widgets/common_button.dart';

// class OtpVerificationScreen extends StatefulWidget {
//   const OtpVerificationScreen({super.key});
//
//   @override
//   State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
// }
//
// class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
//   int seconds = 30;
//
//
//   @override
//   void initState() {
//     super.initState();
//     _startTimer();
//   }
//
//   void _startTimer() {
//     Future.doWhile(() async {
//       await Future.delayed(const Duration(seconds: 1));
//       if (seconds > 0) {
//         setState(() {
//           seconds--;
//         });
//         return true;
//       } else {
//         return false;
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final defaultPinTheme = PinTheme(
//       width: 60,
//       height: 60,
//       textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade400),
//       ),
//     );
//     return SafeArea(
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         body: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               const SizedBox(height: 48),
//               // Logo
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Image.asset('assets/images/Group.png', height: 24, width: 24),
//                   const SizedBox(width: 8),
//                   const Text(
//                     "Penny",
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 48),
//               const Text(
//                 'Verify Code',
//                 style: TextStyle(
//                   fontSize: 42,
//                   fontWeight: FontWeight.w500,
//                   fontStyle: FontStyle.normal,
//                   color: Colors.black,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               const Text(
//                 'An authentication code has been sent to\nyour mobile number',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w400,
//                   fontStyle: FontStyle.normal,
//                   color: Colors.black,
//                 ),              ),
//               const SizedBox(height: 32),
//               // OTP fields
//               Pinput(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 length: 4,
//                 defaultPinTheme: defaultPinTheme,
//                 focusedPinTheme: defaultPinTheme.copyWith(
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.orange, width: 5),
//                   ),
//                 ),
//                 submittedPinTheme: defaultPinTheme,
//                 keyboardType: TextInputType.number,
//               ),
//               const SizedBox(height: 32),
//               // Verify Button
//               CommonButton(
//                 label: 'Verify',
//                 onPressed: () {
//                   // Navigator.pushReplacement(
//                   //   context,
//                   //   MaterialPageRoute(builder: (context) =>  DashboardScreen()),
//                   // );
//                   context.goNamed('home');
//                 },
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 seconds > 0 ? "00:${seconds.toString().padLeft(2, '0')}" : "Expired",
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinput/pinput.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? phoneNumber;

  const OtpVerificationScreen({super.key, this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _otpController = TextEditingController();
  String? _verificationId;
  bool isLoading = false;
  int? _resendToken;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  void _sendOtp() async {
    setState(() => isLoading = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (typically on Android)
          setState(() => isLoading = true);
          try {
            await _auth.signInWithCredential(credential);
            _navigateToHome();
          } catch (e) {
            setState(() => isLoading = false);
            _showErrorSnackBar("Auto-verification failed: $e");
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => isLoading = false);
          _showErrorSnackBar(e.message ?? "Verification failed");
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            isLoading = false;
          });
          _showSuccessSnackBar("OTP sent successfully");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar("Error sending OTP: $e");
      print(e);
    }
  }

  // void _verifyOtpManually() async {
  //   final otp = _otpController.text.trim();
  //   if (otp.length != 6 || _verificationId == null) {
  //     _showErrorSnackBar("Enter a valid 6-digit OTP");
  //     return;
  //   }
  //
  //   setState(() => isLoading = true);
  //   try {
  //     final credential = PhoneAuthProvider.credential(
  //       verificationId: _verificationId!,
  //       smsCode: otp,
  //     );
  //
  //     await _auth.signInWithCredential(credential);
  //     _navigateToHome();
  //   } catch (e) {
  //     setState(() => isLoading = false);
  //     _showErrorSnackBar("OTP verification failed: $e");
  //   }
  // }


  void _verifyOtpManually() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6 || _verificationId == null) {
      _showErrorSnackBar("Enter a valid 6-digit OTP");
      return;
    }

    setState(() => isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken != null) {
        final controller = Provider.of<AuthController>(context, listen: false);
        await controller.verifyPhoneOtp(idToken);
      }

      //final idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        final controller = Provider.of<AuthController>(context, listen: false);
        await controller.verifyPhoneOtp(idToken);
        _navigateToHome();
      } else {
        _showErrorSnackBar("Could not get ID token from Firebase");
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar("OTP verification failed: $e");
    }
  }


  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _navigateToHome() {
    if (!mounted) return;
    // Use GoRouter to navigate and clear history
    GoRouter.of(context).goNamed('home');
  }

  void _resendOtp() {
    _sendOtp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify OTP")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "OTP sent to ${widget.phoneNumber}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: "Enter OTP",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _verifyOtpManually,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Verify OTP"),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: isLoading ? null : _resendOtp,
              child: const Text("Resend OTP"),
            ),
          ],
        ),
      ),
    );
  }
}




class OtpBox extends StatelessWidget {
  final TextEditingController controller;
  const OtpBox({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        maxLength: 1,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          counterText: "",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
