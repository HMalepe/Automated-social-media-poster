// ============================================
// Login Screen
// ============================================
//
// This is the first screen users see (if not logged in).
// Two steps:
// 1. Enter phone number → tap "Send Code"
// 2. Enter the 6-digit OTP code → tap "Verify"
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../map/map_screen.dart';
import 'profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers hold the text that users type into input fields
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  // Tracks which step we're on: entering phone or entering OTP
  bool _otpSent = false;

  @override
  void dispose() {
    // Clean up controllers when screen is closed (prevents memory leaks)
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Consumer listens to AuthProvider and rebuilds when state changes
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return Scaffold(
          // The main body of the screen
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ============================================
                  // LOGO & TITLE
                  // ============================================
                  Icon(
                    Icons.handshake_outlined,
                    size: 80,
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'VouchSA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trust-based services for your suburb',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // ============================================
                  // PHONE NUMBER INPUT (Step 1)
                  // ============================================
                  if (!_otpSent) ...[
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '+27 82 123 4567',
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: auth.isLoading
                          ? null // Disable button while loading
                          : () async {
                              final phone = _phoneController.text.trim();
                              if (phone.isEmpty) return;
                              final success = await auth.sendOtp(phone);
                              if (success) {
                                setState(() => _otpSent = true);
                              }
                            },
                      child: auth.isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Send Code'),
                    ),
                  ],

                  // ============================================
                  // OTP INPUT (Step 2)
                  // ============================================
                  if (_otpSent) ...[
                    Text(
                      'Enter the code sent to ${_phoneController.text}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 8,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Verification Code',
                        hintText: '123456',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: auth.isLoading
                          ? null
                          : () async {
                              final code = _otpController.text.trim();
                              if (code.length != 6) return;
                              final success = await auth.verifyOtp(
                                _phoneController.text.trim(),
                                code,
                              );
                              if (success && context.mounted) {
                                // Check if they have a profile
                                if (auth.currentProfile != null) {
                                  // Existing user → go to map
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const MapScreen(),
                                    ),
                                  );
                                } else {
                                  // New user → set up profile first
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ProfileSetupScreen(),
                                    ),
                                  );
                                }
                              }
                            },
                      child: auth.isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Verify'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _otpSent = false;
                          _otpController.clear();
                        });
                      },
                      child: const Text('Change phone number'),
                    ),
                  ],

                  // ============================================
                  // ERROR MESSAGE
                  // ============================================
                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      auth.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
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
