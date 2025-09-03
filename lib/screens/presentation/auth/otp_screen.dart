// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:go_router/go_router.dart';
// import 'package:pinput/pinput.dart';
// import 'package:vscmoney/screens/presentation/home/home_screen.dart';
// import 'package:vscmoney/services/locator.dart';
//
// import '../../../constants/colors.dart';
// import '../../../services/auth_service.dart';
// import '../../../services/theme_service.dart';
// import '../../widgets/common_button.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// // class OtpVerification extends StatefulWidget {
// //   final String? phoneNumber;
// //   const OtpVerification({super.key, this.phoneNumber});
// //
// //   @override
// //   State<OtpVerification> createState() => _OtpVerificationState();
// // }
// //
// // class _OtpVerificationState extends State<OtpVerification> {
// //   int seconds = 30;
// //
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _startTimer();
// //     _sendOtp();
// //   }
// //
// //   void _startTimer() {
// //     Future.doWhile(() async {
// //       await Future.delayed(const Duration(seconds: 1));
// //       if (seconds > 0) {
// //         setState(() {
// //           seconds--;
// //         });
// //         return true;
// //       } else {
// //         return false;
// //       }
// //     });
// //   }
// //
// //
// //
// //
// //   final FirebaseAuth _auth = FirebaseAuth.instance;
// //   final TextEditingController _otpController = TextEditingController();
// //   String? _verificationId;
// //   bool isLoading = false;
// //   int? _resendToken;
// //
// //
// //   void _sendOtp() async {
// //     setState(() => isLoading = true);
// //
// //     try {
// //       await _auth.verifyPhoneNumber(
// //         phoneNumber: widget.phoneNumber,
// //         timeout: const Duration(seconds: 60),
// //         verificationCompleted: (PhoneAuthCredential credential) async {
// //           // Auto-verification (typically on Android)
// //           setState(() => isLoading = true);
// //           try {
// //             await _auth.signInWithCredential(credential);
// //             _navigateToHome();
// //           } catch (e) {
// //             setState(() => isLoading = false);
// //             _showErrorSnackBar("Auto-verification failed: $e");
// //           }
// //         },
// //         verificationFailed: (FirebaseAuthException e) {
// //           setState(() => isLoading = false);
// //           _showErrorSnackBar(e.message ?? "Verification failed");
// //         },
// //         codeSent: (String verificationId, int? resendToken) {
// //           setState(() {
// //             _verificationId = verificationId;
// //             _resendToken = resendToken;
// //             isLoading = false;
// //           });
// //           _showSuccessSnackBar("OTP sent successfully");
// //         },
// //         codeAutoRetrievalTimeout: (String verificationId) {
// //           setState(() {
// //             _verificationId = verificationId;
// //           });
// //         },
// //         forceResendingToken: _resendToken,
// //       );
// //     } catch (e) {
// //       setState(() => isLoading = false);
// //       _showErrorSnackBar("Error sending OTP: $e");
// //       print(e);
// //     }
// //   }
// //
// //
// //
// //
// //   void _verifyOtpManually() async {
// //     final otp = _otpController.text.trim();
// //     if (otp.length != 6 || _verificationId == null) {
// //       _showErrorSnackBar("Enter a valid 6-digit OTP");
// //       return;
// //     }
// //
// //     setState(() => isLoading = true);
// //     try {
// //       final credential = PhoneAuthProvider.credential(
// //         verificationId: _verificationId!,
// //         smsCode: otp,
// //       );
// //
// //       final userCredential = await _auth.signInWithCredential(credential);
// //       final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
// //       if (idToken != null) {
// //         final controller = Provider.of<AuthController>(context, listen: false);
// //         await controller.verifyPhoneOtp(idToken,context);
// //       }
// //
// //       //final idToken = await userCredential.user?.getIdToken();
// //
// //       if (idToken != null) {
// //         final controller = Provider.of<AuthController>(context, listen: false);
// //         await controller.verifyPhoneOtp(idToken,context);
// //         _navigateToHome();
// //       } else {
// //         _showErrorSnackBar("Could not get ID token from Firebase");
// //       }
// //     } catch (e) {
// //       setState(() => isLoading = false);
// //       _showErrorSnackBar("OTP verification failed: $e");
// //     }
// //   }
// //
// //
// //   void _showErrorSnackBar(String message) {
// //     if (!mounted) return;
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message),
// //         backgroundColor: Colors.red,
// //       ),
// //     );
// //   }
// //
// //   void _showSuccessSnackBar(String message) {
// //     if (!mounted) return;
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message),
// //         backgroundColor: Colors.green,
// //       ),
// //     );
// //   }
// //
// //   void _navigateToHome() {
// //     if (!mounted) return;
// //     // Use GoRouter to navigate and clear history
// //     GoRouter.of(context).goNamed('home');
// //   }
// //
// //   void _resendOtp() {
// //     _sendOtp();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final defaultPinTheme = PinTheme(
// //       width: 60,
// //       height: 60,
// //       textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12),
// //         border: Border.all(color: Colors.grey.shade400),
// //       ),
// //     );
// //     return SafeArea(
// //       child: Scaffold(
// //         backgroundColor: Colors.white,
// //         body: Padding(
// //           padding: const EdgeInsets.symmetric(horizontal: 24),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.center,
// //             children: [
// //               const SizedBox(height: 48),
// //               // Logo
// //               Column(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   Image.asset('assets/images/new_app_logo.png', width:80, height: 50),
// //                   const SizedBox(width: 16),
// //                   Image.asset('assets/images/Vitty.ai.png', width: 80, height: 50),
// //                 ],
// //               ),
// //               const SizedBox(height: 48),
// //               const Text(
// //                 'Verify Code',
// //                 style: TextStyle(
// //                   fontSize: 42,
// //                   fontWeight: FontWeight.w500,
// //                   fontStyle: FontStyle.normal,
// //                   color: Colors.black,
// //                 ),
// //               ),
// //               const SizedBox(height: 12),
// //                Text(
// //                 'An authentication code has been sent to\n${widget.phoneNumber}',
// //                 textAlign: TextAlign.center,
// //                 style: TextStyle(
// //                   fontSize: 18,
// //                   fontWeight: FontWeight.w400,
// //                   fontStyle: FontStyle.normal,
// //                   color: Colors.black,
// //                 ),              ),
// //               const SizedBox(height: 32),
// //               // OTP fields
// //               Pinput(
// //                 controller: _otpController,
// //                 mainAxisAlignment: MainAxisAlignment.spaceAround,
// //                 length: 6,
// //                 defaultPinTheme: defaultPinTheme,
// //                 focusedPinTheme: defaultPinTheme.copyWith(
// //                   decoration: BoxDecoration(
// //                     border: Border.all(color: Colors.orange, width: 3),
// //                   ),
// //                 ),
// //                 submittedPinTheme: defaultPinTheme,
// //                 keyboardType: TextInputType.number,
// //               ),
// //               const SizedBox(height: 32),
// //               // Verify Button
// //               CommonButton(
// //                 label: 'Verify',
// //                 onPressed: isLoading ? null : _verifyOtpManually,
// //               ),
// //
// //
// //               const SizedBox(height: 16),
// //               GestureDetector(
// //                 onTap: (){
// //                   isLoading ? null : _resendOtp();
// //                 },
// //                 child: Text(
// //                   'Resend OTP',
// //                   style: const TextStyle(
// //                     fontWeight: FontWeight.bold,
// //                     fontSize: 16,
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
//
//
//
//
//
//
// // class OtpVerificationScreen extends StatefulWidget {
// //   final String? phoneNumber;
// //
// //   const OtpVerificationScreen({super.key, this.phoneNumber});
// //
// //   @override
// //   State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
// // }
// //
// // class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
// //   final FirebaseAuth _auth = FirebaseAuth.instance;
// //   final TextEditingController _otpController = TextEditingController();
// //   String? _verificationId;
// //   bool isLoading = false;
// //   int? _resendToken;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _sendOtp();
// //   }
// //
// //   void _sendOtp() async {
// //     setState(() => isLoading = true);
// //
// //     try {
// //       await _auth.verifyPhoneNumber(
// //         phoneNumber: widget.phoneNumber,
// //         timeout: const Duration(seconds: 60),
// //         verificationCompleted: (PhoneAuthCredential credential) async {
// //           // Auto-verification (typically on Android)
// //           setState(() => isLoading = true);
// //           try {
// //             await _auth.signInWithCredential(credential);
// //             _navigateToHome();
// //           } catch (e) {
// //             setState(() => isLoading = false);
// //             _showErrorSnackBar("Auto-verification failed: $e");
// //           }
// //         },
// //         verificationFailed: (FirebaseAuthException e) {
// //           setState(() => isLoading = false);
// //           _showErrorSnackBar(e.message ?? "Verification failed");
// //         },
// //         codeSent: (String verificationId, int? resendToken) {
// //           setState(() {
// //             _verificationId = verificationId;
// //             _resendToken = resendToken;
// //             isLoading = false;
// //           });
// //           _showSuccessSnackBar("OTP sent successfully");
// //         },
// //         codeAutoRetrievalTimeout: (String verificationId) {
// //           setState(() {
// //             _verificationId = verificationId;
// //           });
// //         },
// //         forceResendingToken: _resendToken,
// //       );
// //     } catch (e) {
// //       setState(() => isLoading = false);
// //       _showErrorSnackBar("Error sending OTP: $e");
// //       print(e);
// //     }
// //   }
// //
// //
// //
// //
// //   void _verifyOtpManually() async {
// //     final otp = _otpController.text.trim();
// //     if (otp.length != 6 || _verificationId == null) {
// //       _showErrorSnackBar("Enter a valid 6-digit OTP");
// //       return;
// //     }
// //
// //     setState(() => isLoading = true);
// //     try {
// //       final credential = PhoneAuthProvider.credential(
// //         verificationId: _verificationId!,
// //         smsCode: otp,
// //       );
// //
// //       final userCredential = await _auth.signInWithCredential(credential);
// //       final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
// //       if (idToken != null) {
// //         final controller = Provider.of<AuthController>(context, listen: false);
// //         await controller.verifyPhoneOtp(idToken);
// //       }
// //
// //       //final idToken = await userCredential.user?.getIdToken();
// //
// //       if (idToken != null) {
// //         final controller = Provider.of<AuthController>(context, listen: false);
// //         await controller.verifyPhoneOtp(idToken);
// //         _navigateToHome();
// //       } else {
// //         _showErrorSnackBar("Could not get ID token from Firebase");
// //       }
// //     } catch (e) {
// //       setState(() => isLoading = false);
// //       _showErrorSnackBar("OTP verification failed: $e");
// //     }
// //   }
// //
// //
// //   void _showErrorSnackBar(String message) {
// //     if (!mounted) return;
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message),
// //         backgroundColor: Colors.red,
// //       ),
// //     );
// //   }
// //
// //   void _showSuccessSnackBar(String message) {
// //     if (!mounted) return;
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message),
// //         backgroundColor: Colors.green,
// //       ),
// //     );
// //   }
// //
// //   void _navigateToHome() {
// //     if (!mounted) return;
// //     // Use GoRouter to navigate and clear history
// //     GoRouter.of(context).goNamed('home');
// //   }
// //
// //   void _resendOtp() {
// //     _sendOtp();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: const Text("Verify OTP")),
// //       body: Padding(
// //         padding: const EdgeInsets.all(20),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.stretch,
// //           children: [
// //             Text(
// //               "OTP sent to ${widget.phoneNumber}",
// //               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
// //             ),
// //             const SizedBox(height: 20),
// //             TextField(
// //               controller: _otpController,
// //               keyboardType: TextInputType.number,
// //               maxLength: 6,
// //               decoration: const InputDecoration(
// //                 labelText: "Enter OTP",
// //                 border: OutlineInputBorder(),
// //               ),
// //             ),
// //             const SizedBox(height: 20),
// //             ElevatedButton(
// //               onPressed: isLoading ? null : _verifyOtpManually,
// //               style: ElevatedButton.styleFrom(
// //                 padding: const EdgeInsets.symmetric(vertical: 15),
// //               ),
// //               child: isLoading
// //                   ? const CircularProgressIndicator()
// //                   : const Text("Verify OTP"),
// //             ),
// //             const SizedBox(height: 15),
// //             TextButton(
// //               onPressed: isLoading ? null : _resendOtp,
// //               child: const Text("Resend OTP"),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
//
//
//
// // import 'dart:async';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter/material.dart';
// // import 'package:sms_autofill/sms_autofill.dart';
// // import 'package:provider/provider.dart';
// // import '../../../controllers/auth_controller.dart';
// //
// // class OtpVerification extends StatefulWidget {
// //   final String? phoneNumber;
// //   const OtpVerification({super.key, this.phoneNumber});
// //
// //   @override
// //   State<OtpVerification> createState() => _OtpVerificationState();
// // }
// //
// // class _OtpVerificationState extends State<OtpVerification> with CodeAutoFill {
// //   final FirebaseAuth _auth = FirebaseAuth.instance;
// //   final TextEditingController _otpController = TextEditingController();
// //   String? _verificationId;
// //   int _seconds = 30;
// //   bool isLoading = false;
// //   int? _resendToken;
// //   Timer? _resendTimer;
// //   bool _canResend = false;
// //   final FocusNode _focusNode = FocusNode();
// //   Future<void> _printAppSignature() async {
// //     final signature = await SmsAutoFill().getAppSignature;
// //     debugPrint("📲 App Signature (paste this in SMS): $signature");
// //   }
// //
// //
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     listenForCode();
// //     _printAppSignature();
// //     _sendOtp();
// //     _requestSMSPermission();
// //     _startTimer();
// //
// //     Future.delayed(Duration(milliseconds: 200), () {
// //       _focusNode.requestFocus(); // 👈 triggers the keyboard
// //     });
// //   }
// //
// //   @override
// //   void codeUpdated() {
// //     final newCode = code;
// //     if (newCode != null && newCode.length == 6) {
// //       _otpController.text = newCode;
// //       _verifyOtpManually();
// //     }
// //   }
// //
// //
// //   Future<void> _requestSMSPermission() async {
// //     try {
// //       // Request SMS permission
// //       await SmsAutoFill().listenForCode();
// //     } on PlatformException catch (e) {
// //       print('Failed to get SMS permission: ${e.message}');
// //     }
// //   }
// //
// //   void _startTimer() {
// //     _resendTimer?.cancel(); // cancel existing if any
// //     setState(() {
// //       _seconds = 30;
// //       _canResend = false;
// //     });
// //
// //     _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
// //       if (_seconds > 0) {
// //         setState(() => _seconds--);
// //       } else {
// //         timer.cancel();
// //         setState(() => _canResend = true);
// //       }
// //     });
// //   }
// //
// //   void _resendOtp() {
// //     if (!_canResend) return;
// //
// //     _otpController.clear(); // clear previous OTP
// //     _verificationId = null; // reset previous verification ID
// //
// //     _sendOtp();     // 🔁 Send OTP again
// //     _startTimer();  // 🔁 Restart timer
// //     listenForCode(); // 🔁 Start listening again
// //   }
// //
// //
// //
// //   void _sendOtp() async {
// //     setState(() => isLoading = true);
// //     try {
// //       await _auth.verifyPhoneNumber(
// //         phoneNumber: widget.phoneNumber!,
// //         timeout: const Duration(seconds: 60),
// //         verificationCompleted: (PhoneAuthCredential credential) async {
// //           await _auth.signInWithCredential(credential);
// //           final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
// //           if (idToken != null) {
// //             final controller = Provider.of<AuthController>(context, listen: false);
// //             await controller.verifyPhoneOtp(idToken, context);
// //           }
// //         },
// //         verificationFailed: (FirebaseAuthException e) {
// //           _showErrorSnackBar(e.message ?? 'Verification failed');
// //         },
// //         codeSent: (String verificationId, int? resendToken) {
// //           setState(() {
// //             _verificationId = verificationId;
// //             _resendToken = resendToken;
// //             isLoading = false;
// //             _seconds = 30;
// //           });
// //         },
// //         forceResendingToken: _resendToken,
// //         codeAutoRetrievalTimeout: (String verificationId) {
// //           _verificationId = verificationId;
// //         },
// //       );
// //     } catch (e) {
// //       _showErrorSnackBar("Error sending OTP: $e");
// //     }
// //   }
// //
// //   void _verifyOtpManually() async {
// //     final otp = _otpController.text.trim();
// //     if (otp.length != 6 || _verificationId == null) {
// //       _showErrorSnackBar("Enter a valid 6-digit OTP");
// //       return;
// //     }
// //
// //     setState(() => isLoading = true);
// //
// //     try {
// //       final credential = PhoneAuthProvider.credential(
// //         verificationId: _verificationId!,
// //         smsCode: otp,
// //       );
// //
// //       await _auth.signInWithCredential(credential);
// //       final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
// //
// //       if (idToken != null) {
// //         final controller = Provider.of<AuthController>(context, listen: false);
// //         await controller.verifyPhoneOtp(idToken, context);
// //       } else {
// //         _showErrorSnackBar("Could not retrieve token");
// //       }
// //     } catch (e) {
// //       _showErrorSnackBar("OTP verification failed");
// //     } finally {
// //       if (mounted) setState(() => isLoading = false);
// //     }
// //   }
// //
// //   void _showErrorSnackBar(String message) {
// //     if (!mounted) return;
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(content: Text(message), backgroundColor: Colors.red),
// //     );
// //   }
// //
// //   @override
// //   void dispose() {
// //     _focusNode.dispose();
// //     _resendTimer?.cancel();
// //     cancel(); // sms_autofill listener
// //     _otpController.dispose();
// //     super.dispose();
// //   }
// //
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final isResendAvailable = _seconds == 0;
// //     final defaultPinTheme = PinTheme(
// //       width: 60,
// //       height: 60,
// //       textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12),
// //         border: Border.all(color: Colors.grey.shade400),
// //       ),
// //     );
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       body: SafeArea(
// //         child: LayoutBuilder(builder: (context, constraints) {
// //           return SingleChildScrollView(
// //             child: ConstrainedBox(
// //               constraints: BoxConstraints(minHeight: constraints.maxHeight),
// //               child: IntrinsicHeight(
// //                 child: Padding(
// //                   padding: const EdgeInsets.symmetric(horizontal: 24),
// //                   child: Column(
// //                     children: [
// //                       const SizedBox(height: 48),
// //                       Image.asset('assets/images/new_app_logo.png', height: 50),
// //                       const SizedBox(height: 12),
// //                       Image.asset('assets/images/Vitty.ai.png', height: 30),
// //                       const SizedBox(height: 48),
// //                       const Text(
// //                         "Verify Code",
// //                         style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
// //                       ),
// //                       const SizedBox(height: 8),
// //                       Text(
// //                         "An authentication code has been sent to\n${widget.phoneNumber}",
// //                         textAlign: TextAlign.center,
// //                         style: const TextStyle(fontSize: 16),
// //                       ),
// //                       const SizedBox(height: 32),
// //
// //
// //                       Pinput(
// //                         focusNode: _focusNode,
// //                         controller: _otpController,
// //                         length: 6,
// //                         defaultPinTheme: defaultPinTheme,
// //                         focusedPinTheme: defaultPinTheme.copyWith(
// //                           decoration: BoxDecoration(
// //                             border: Border.all(color: Colors.orange, width: 3),
// //                           ),
// //                         ),
// //                         submittedPinTheme: defaultPinTheme,
// //                         keyboardType: TextInputType.number,
// //                         onCompleted: (value) {
// //                           _verifyOtpManually(); // optional fallback for manual
// //                         },
// //                       ),
// //
// //
// //                       const SizedBox(height: 24),
// //                       CommonButton(
// //                         label: "Verify",
// //                         onPressed: isLoading ? null : _verifyOtpManually,
// //                       ),
// //
// //                       const SizedBox(height: 16),
// //                       // GestureDetector(
// //                       //   onTap: _canResend ? _sendOtp : null,
// //                       //   child: Text(
// //                       //     _canResend ? "Resend OTP" : "Resend (${_seconds})",
// //                       //     style: TextStyle(
// //                       //       fontSize: 16,
// //                       //       fontWeight: FontWeight.bold,
// //                       //       color: _canResend ? Colors.black : Colors.grey,
// //                       //     ),
// //                       //   ),
// //                       // ),
// //                       GestureDetector(
// //                         onTap: _canResend ? _resendOtp : null,
// //                         child: Text(
// //                           _canResend ? "Resend OTP" : "Resend ($_seconds)",
// //                           style: TextStyle(
// //                             fontSize: 16,
// //                             fontWeight: FontWeight.bold,
// //                             color: _canResend ? Colors.black : Colors.grey,
// //                           ),
// //                         ),
// //                       ),
// //
// //                       const Spacer(),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           );
// //         }),
// //       ),
// //     );
// //   }
// // }
//
//
//
//
// // class OtpBox extends StatelessWidget {
// //   final TextEditingController controller;
// //   const OtpBox({super.key, required this.controller});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return SizedBox(
// //       width: 60,
// //       height: 60,
// //       child: TextField(
// //         controller: controller,
// //         textAlign: TextAlign.center,
// //         maxLength: 1,
// //         keyboardType: TextInputType.number,
// //         decoration: InputDecoration(
// //           counterText: "",
// //           border: OutlineInputBorder(
// //             borderRadius: BorderRadius.circular(12),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
//
//
//
//
//
//
//
//
// import 'dart:async';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:sms_autofill/sms_autofill.dart';
// import 'package:pinput/pinput.dart';
// import '../../widgets/common_button.dart';
//
// class OtpVerification extends StatefulWidget {
//   final String? phoneNumber;
//   const OtpVerification({super.key, this.phoneNumber});
//
//   @override
//   State<OtpVerification> createState() => _OtpVerificationState();
// }
//
// class _OtpVerificationState extends State<OtpVerification> with CodeAutoFill {
//   final TextEditingController _otpController = TextEditingController();
//   final FocusNode _focusNode = FocusNode();
//   final AuthService _authService = locator<AuthService>();
//
//   late StreamSubscription<AuthState> _stateSub;
//
//   bool isLoading = false;
//   int _seconds = 30;
//   Timer? _timer;
//   bool _canResend = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initOtpFlow();
//     _stateSub = _authService.authStateStream.listen((state) {
//       if (!mounted) return;
//       setState(() => isLoading = state.status == AuthStatus.loading);
//       if (state.status == AuthStatus.error && state.error != null) {
//         _showError(state.error!);
//       }
//     });
//   }
//
//   Future<void> _initOtpFlow() async {
//     await _printAppSignature();
//     _sendOtp();
//     _startTimer();
//     listenForCode();
//     Future.delayed(const Duration(milliseconds: 300), () {
//       _focusNode.requestFocus();
//     });
//   }
//
//   Future<void> _printAppSignature() async {
//     final signature = await SmsAutoFill().getAppSignature;
//     debugPrint("📲 App Signature: $signature");
//   }
//
//   void _startTimer() {
//     _timer?.cancel();
//     setState(() {
//       _seconds = 30;
//       _canResend = false;
//     });
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_seconds > 0) {
//         setState(() => _seconds--);
//       } else {
//         timer.cancel();
//         setState(() => _canResend = true);
//       }
//     });
//   }
//
//   void _sendOtp() {
//     setState(() => isLoading = true);
//     if (widget.phoneNumber == null) return;
//     _authService.sendOtp(
//       phoneNumber: widget.phoneNumber!,
//       onCodeSent: (_, __) {},
//       onAutoVerify: (credential) async {
//         final token = await _authService.autoVerifyCredential(credential);
//         if (token != null) {
//           await _authService.handleOtpTokenVerification(token, _handleFlow);
//         }
//       },
//       onError: _showError,
//     );
//   }
//
//   void _verifyManualOtp() async {
//     final otp = _otpController.text.trim();
//     if (otp.length != 6) {
//       _showError("Invalid OTP");
//       return;
//     }
//
//     final token = await _authService.verifyOtp(otp);
//     if (token != null) {
//       await _authService.handleOtpTokenVerification(token, _handleFlow);
//     } else {
//       _showError("Failed to verify OTP");
//     }
//   }
//
//   void _handleFlow(AuthFlow flow) {
//     switch (flow) {
//       case AuthFlow.onboarding:
//       // This shouldn't happen during OTP flow, but handle it gracefully
//         context.go('/onboarding');
//         break;
//       case AuthFlow.login:
//         context.go('/phone_otp');
//         break;
//       case AuthFlow.nameEntry:
//         context.go('/enter_name');
//         break;
//       case AuthFlow.home:
//         context.go('/home');
//         break;
//
//     }
//   }
//
//   void _resendOtp() {
//     if (_canResend) {
//       _otpController.clear();
//       _sendOtp();
//       _startTimer();
//     }
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }
//
//   @override
//   void codeUpdated() {
//     final code = this.code;
//     if (code != null && code.length == 6) {
//       _otpController.text = code;
//       _verifyManualOtp();
//     }
//   }
//
//   @override
//   void dispose() {
//     _otpController.dispose();
//     _focusNode.dispose();
//     _timer?.cancel();
//     _stateSub.cancel();
//     cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     final isResendAvailable = _seconds == 0;
//     final theme = Theme.of(context).extension<AppThemeExtension>()!.theme;
//     final defaultPinTheme = PinTheme(
//       width: 60,
//       height: 60,
//       textStyle:  TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.text),
//       decoration: BoxDecoration(
//         color: theme.box,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade400),
//       ),
//     );
//     return Scaffold(
//       backgroundColor: theme.background,
//       body: SafeArea(
//         child: LayoutBuilder(builder: (context, constraints) {
//           return SingleChildScrollView(
//             child: ConstrainedBox(
//               constraints: BoxConstraints(minHeight: constraints.maxHeight),
//               child: IntrinsicHeight(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 24),
//                   child: Column(
//                     children: [
//                       // const SizedBox(height: 48),
//                       // // Image.asset('assets/images/new_app_logo.png', height: 50),
//                       // // const SizedBox(height: 12),
//                       // // Image.asset('assets/images/Vitty.ai.png', height: 30),
//                       // const SizedBox(height: 48),
//                       SizedBox(height: screenHeight * 0.05),
//                       Hero(
//                         tag: 'penny_logo',
//                         child: Image.asset(
//                           'assets/images/auth.png',
//                           width: screenWidth * 0.2,
//                           height: screenHeight * 0.1,
//                         ),
//                       ),
//                       SizedBox(height: screenHeight * 0.07),
//                        Text(
//                         "Verify Code",
//                         style: TextStyle(fontSize: 28, fontWeight: FontWeight.w400,fontFamily: 'DM Sans',color: theme.text),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         "An authentication code has been sent to\n${widget.phoneNumber}",
//                         textAlign: TextAlign.center,
//                         style:  TextStyle(fontSize: 16,color: theme.text),
//                       ),
//                       const SizedBox(height: 32),
//
//
//                       Pinput(
//                         focusNode: _focusNode,
//                         controller: _otpController,
//                         length: 6,
//                         defaultPinTheme: defaultPinTheme,
//                         focusedPinTheme: defaultPinTheme.copyWith(
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Colors.orange, width: 3),
//                           ),
//                         ),
//                         submittedPinTheme: defaultPinTheme,
//                         keyboardType: TextInputType.number,
//                         onCompleted: (value) {
//                           _verifyManualOtp(); // optional fallback for manual
//                         },
//                       ),
//
//
//                       const SizedBox(height: 24),
//                       // CommonButton(
//                       //   label: "Verify",
//                       //   onPressed: isLoading ? null : _verifyManualOtp,
//                       // ),
//                       CommonButton(
//                         onPressed: isLoading ? null : _verifyManualOtp,
//                         child: isLoading
//                             ? SizedBox(
//                           child: const CircularProgressIndicator(
//                             strokeWidth: 1,
//                             color: Colors.white,
//                           ),
//                         )
//                             : const Text("Verify", style: TextStyle(fontSize: 18, color: Colors.white)),
//                       ),
//
//
//                       const SizedBox(height: 16),
//                       GestureDetector(
//                         onTap: _canResend ? _resendOtp : null,
//                         child: Text(
//                           _canResend ? "Resend OTP" : "Resend ($_seconds)",
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: _canResend ? theme.text : Colors.grey,
//                           ),
//                         ),
//                       ),
//
//                       const Spacer(),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           );
//         }),
//       ),
//     );
//   }
// }
//
//
//
