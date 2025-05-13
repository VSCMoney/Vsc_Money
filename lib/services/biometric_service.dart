import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import 'package:local_auth/local_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  final LocalAuthentication _auth = LocalAuthentication();


  /// Emits true if user authenticated, false if failed
  final BehaviorSubject<bool> _authStateSubject = BehaviorSubject.seeded(false);
  Stream<bool> get authStateStream => _authStateSubject.stream;

  /// Whether user enabled biometric usage manually
  bool _biometricEnabled = false;

  /// Load setting from storage (e.g., SharedPreferences)
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
  }

  bool get isBiometricEnabled => _biometricEnabled;

  // Future<void> toggleBiometric(bool enabled) async {
  //   final prefs = await SharedPreferences.getInstance();
  //
  //   if (enabled) {
  //     final canCheck = await _auth.canCheckBiometrics;
  //     final isSupported = await _auth.isDeviceSupported();
  //
  //     if (!canCheck || !isSupported) {
  //       print("❌ Device does not support biometrics.");
  //       _authStateSubject.add(false);
  //       return;
  //     }
  //
  //     final success = await _auth.authenticate(
  //       localizedReason: 'Please authenticate to enable biometrics',
  //       options: const AuthenticationOptions(
  //         biometricOnly: true,
  //         stickyAuth: true,
  //         useErrorDialogs: true,
  //       ),
  //     );
  //
  //     if (success) {
  //       _biometricEnabled = true;
  //       await prefs.setBool('biometric_enabled', true);
  //       _authStateSubject.add(true);
  //     } else {
  //       print("❌ Biometric auth failed or cancelled.");
  //       _authStateSubject.add(false);
  //     }
  //   } else {
  //     _biometricEnabled = false;
  //     await prefs.setBool('biometric_enabled', false);
  //     _authStateSubject.add(false);
  //   }
  // }



  Future<bool> toggleBiometric(bool enabled, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    if (enabled) {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();

      if (!canCheck || !isSupported) {
        _authStateSubject.add(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Biometrics not supported on this device')),
        );
        return false;
      }

      final success = await _auth.authenticate(
        localizedReason: 'Please authenticate to enable biometrics',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (success) {
        _biometricEnabled = true;
        await prefs.setBool('biometric_enabled', true);
        _authStateSubject.add(true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Biometric enabled')),
        );
        return true;
      } else {
        _authStateSubject.add(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Biometric auth cancelled')),
        );
        return false;
      }
    } else {
      _biometricEnabled = false;
      await prefs.setBool('biometric_enabled', false);
      _authStateSubject.add(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🔒 Biometric disabled')),
      );
      return false;
    }
  }

  Future<bool> isBiometricEnabledAsync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled') ?? false;
  }


  Future<void> requestBiometricPermission() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isSupported) {
        print("Device does not support biometrics");
        return;
      }

      final success = await _auth.authenticate(
        localizedReason: 'Please authenticate to enable biometric login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      _authStateSubject.add(success);
    } catch (e) {
      print('Biometric setup error: $e');
      _authStateSubject.add(false);
    }
  }

  Future<bool> authenticate() async {
    try {
      print("🧪 Checking biometric support");
      final support = await _auth.canCheckBiometrics;
      print("✅ canCheckBiometrics: $support");

      final success = await _auth.authenticate(
        localizedReason: 'Please authenticate to enable biometrics',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      print("🔐 Authentication result: $success");
      _authStateSubject.add(success);
      return success;
    } catch (e) {
      print('❌ Biometric error: $e');
      _authStateSubject.add(false);
      return false;
    }
  }


  void dispose() {
    _authStateSubject.close();
  }
}


