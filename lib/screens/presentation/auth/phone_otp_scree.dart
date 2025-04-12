import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../constants/colors.dart';
import '../../../controllers/auth_controller.dart';
import 'otp_screen.dart';

class PhoneOtpScreen extends StatefulWidget {
  const PhoneOtpScreen({super.key});

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
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

  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Hero(
                tag: 'vitty_logo',
                child: Column(
                  children: [
                    // SvgPicture.asset('assets/images/Vitty_logo.svg', height: 80),
                    // const SizedBox(height: 8),
                    // const Text(
                    //   "Vitty.ai",
                    //   style: TextStyle(
                    //     fontSize: 28,
                    //     fontWeight: FontWeight.bold,
                    //     color: Colors.orange,
                    //   ),
                    // ),
                    Image.asset('assets/images/new_app_logo.png', width:80, height: 50),
                    const SizedBox(width: 16),
                    Image.asset('assets/images/Vitty.ai.png', width: 80, height: 50),
                  ],
                ),
              ),

              const SizedBox(height: 64),
              const Text(
                "Your AI Financial Consultant",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Padding(
                padding:  EdgeInsets.symmetric(horizontal:24.0),
                child: const Text(
                  "Where smart advice meets zero awkward phone calls.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.black,fontWeight: FontWeight.w400),
                ),
              ),
              const SizedBox(height: 32),
              Column(
                children: [
                  Row(
                    children: [
                      Text(
                        "Phone Number*",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.black,fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Phone number',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: Text(
                          '+91',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide(
                          color: Colors.black54, // Purple on focus
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.6),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: TextStyle(fontSize: 15),
                  )

                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleGetOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blackButton,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Get OTP", style: TextStyle(fontSize: 16,color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
