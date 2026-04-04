// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                Icon(Icons.person, color: AppColors.cyan, size: 18),
                SizedBox(width: 6),
                Text('Profile', style: AppTextStyles.heading),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardMid,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cyanDark),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.cyanDark,
                    child: Icon(Icons.person,
                        color: AppColors.cyan, size: 30),
                  ),
                  SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('mike wazowski',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text('youremail@gmail.com',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      Text('+63 917 400 1235',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
