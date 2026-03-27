// ============================================
// Profile Setup Screen
// ============================================
//
// Shown to first-time users after OTP verification.
// They choose: "I'm a Client", "I'm a Pro", or "Both"
// Then enter their name and optional photo.
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../map/map_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  String _selectedUserType = 'client'; // Default

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Set Up Your Profile'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Welcome to VouchSA!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Let\'s get you set up.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),

                // ============================================
                // USER TYPE SELECTION
                // ============================================
                const Text(
                  'I want to...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                // Three options as selectable cards
                _UserTypeCard(
                  title: 'Find Services',
                  subtitle: 'Book barbers, cleaners, gardeners near me',
                  icon: Icons.search,
                  isSelected: _selectedUserType == 'client',
                  onTap: () => setState(() => _selectedUserType = 'client'),
                ),
                const SizedBox(height: 8),
                _UserTypeCard(
                  title: 'Offer Services',
                  subtitle: 'I\'m a pro — let clients find and book me',
                  icon: Icons.work_outline,
                  isSelected: _selectedUserType == 'pro',
                  onTap: () => setState(() => _selectedUserType = 'pro'),
                ),
                const SizedBox(height: 8),
                _UserTypeCard(
                  title: 'Both',
                  subtitle: 'I want to find AND offer services',
                  icon: Icons.swap_horiz,
                  isSelected: _selectedUserType == 'both',
                  onTap: () => setState(() => _selectedUserType = 'both'),
                ),

                const SizedBox(height: 24),

                // ============================================
                // NAME INPUT
                // ============================================
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your Name',
                    hintText: 'How should people know you?',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),

                const Spacer(),

                // ============================================
                // CONTINUE BUTTON
                // ============================================
                ElevatedButton(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          final name = _nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please enter your name')),
                            );
                            return;
                          }

                          final success = await auth.createProfile(
                            displayName: name,
                            userType: _selectedUserType,
                          );

                          if (success && context.mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const MapScreen(),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: auth.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Get Started',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A selectable card for choosing user type.
class _UserTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _UserTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppConstants.primaryColor.withOpacity(0.05)
              : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isSelected ? AppConstants.primaryColor : Colors.grey[400],
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppConstants.primaryColor
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppConstants.primaryColor),
          ],
        ),
      ),
    );
  }
}
