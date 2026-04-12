// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import 'profile_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const WatchtowerAppBar(),
      endDrawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settings', style: AppTextStyles.heading),
            const SizedBox(height: 20),
            _settingsTile(
                context, Icons.person, 'Profile', const ProfileScreen()),
            const SizedBox(height: 10),
            _settingsTile(
                context, Icons.info, 'About Us', const AboutScreen()),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile(BuildContext context, IconData icon, String label,
      Widget screen) {
    return GestureDetector(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardMid,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.cyan),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(color: AppColors.textPrimary)),
            const Spacer(),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
