// lib/screens/about_screen.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
            const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.cyan, size: 18),
                SizedBox(width: 6),
                Text('About Us', style: AppTextStyles.heading),
              ],
            ),
            const SizedBox(height: 24),
            // ── Row 1: Founder + Co-Founder ─────────────────
            Row(
              children: [
                _teamCard(
                  initials: 'KQ',
                  name: 'Keanne Emmarcs\nQuicoy',
                  role: 'Founder',
                  description: 'Maker of Watchtower',
                ),
                const SizedBox(width: 12),
                _teamCard(
                  initials: 'JA',
                  name: 'Jude\nAndres',
                  role: 'Co-Founder',
                  description: 'Maker of Watchtower',
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ── Row 2: Ezekiel (centered) ────────────────────
            Row(
              children: [
                _teamCard(
                  initials: 'EC',
                  name: 'Ezekiel\nCarag',
                  role: 'Co-Founder',
                  description: 'Maker of Watchtower',
                ),
                // Empty expanded to keep card same width as above
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamCard({
    required String initials,
    required String name,
    required String role,
    required String description,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardMid,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.cyanDark,
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              role,
              style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
