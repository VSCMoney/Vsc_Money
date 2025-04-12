import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:vscmoney/screens/presentation/home/home_screen.dart';

import '../../../constants/colors.dart';
import '../../../controllers/auth_controller.dart';
 // Replace with your home screen route

class EnterNameScreen extends StatefulWidget {
  const EnterNameScreen({super.key});

  @override
  State<EnterNameScreen> createState() => _EnterNameScreenState();
}

class _EnterNameScreenState extends State<EnterNameScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  bool _isLoading = false;

  void _submitName() async {
    final fullName = _fullNameController.text.trim();
    if (fullName.isEmpty || !fullName.contains(" ")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter full name (first & last)")),
      );
      return;
    }

    final parts = fullName.split(" ");
    final firstName = parts.first;
    final lastName = parts.sublist(1).join(" ");

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthController>(context, listen: false);
    await auth.completeUserProfile(firstName, lastName);
    setState(() => _isLoading = false);

    if (auth.error == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? "Something went wrong")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              SvgPicture.asset('assets/images/Vitty_logo.svg', height: 50),
              const Text(
                "Vitty.ai",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,color: Colors.orange),
              ),
              const SizedBox(height: 64),
              const Text(
                "Enter Your Name",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Padding(
                padding:  EdgeInsets.symmetric(horizontal:44.0),
                child: const Text(
                  "Even the smartest AI likes to know who it’s talking to.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 32),
              Column(
                children: [
                  Row(
                    children: [
                      Text(
                        "Full Name*",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 17, color: Colors.black,fontWeight: FontWeight.w300),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _fullNameController,
                    decoration: InputDecoration(
                      hintText: "Full Name",
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.black,
                          width: 0.1
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitName,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blackButton,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Continue", style: TextStyle(fontSize: 16,color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
