// lib/utils/constants.dart
import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0A0E1A);
  static const cardDark = Color(0xFF111827);
  static const cardMid = Color(0xFF1A2235);
  static const cyan = Color(0xFF00C8E0);
  static const cyanDark = Color(0xFF0A4F6E);
  static const cyanLight = Color(0xFF4DD9EC);
  static const headerBlue = Color(0xFF7BA7C4);
  static const alertRed = Color(0xFFE53E3E);
  static const alertGreen = Color(0xFF38A169);
  static const alertOrange = Color(0xFFDD6B20);
  static const textPrimary = Color(0xFFEDF2F7);
  static const textSecondary = Color(0xFF718096);
  static const lcdGreen = Color(0xFF00FF41);
  static const lcdBg = Color(0xFF0D1F0D);
}

class AppTextStyles {
  static const heading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static const label = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
  static const cyan = TextStyle(
    color: AppColors.cyan,
    fontWeight: FontWeight.w600,
  );
}

class MockData {
  static final List<Map<String, dynamic>> alerts = [
    {
      'type': 'SMS Alert',
      'status': 'Successful',
      'time': '10:30AM',
      'period': 'Latest',
    },
    {
      'type': 'Motion detected',
      'status': 'Alert',
      'time': '10:30AM',
      'period': 'Latest',
    },
    {
      'type': 'Motion detected',
      'status': 'Alert',
      'time': '11:33PM',
      'period': 'Last Week',
    },
    {
      'type': 'SMS Alert',
      'status': 'Successful',
      'time': '7:43AM',
      'period': 'Last Month',
    },
  ];

  static final List<Map<String, String>> contacts = [
    {'name': 'John Pablo', 'number': '+63 917 583 2491'},
    {'name': 'Smart Smith', 'number': '+63 905 672 3184'},
    {'name': 'Wallie B', 'number': '+63 939 451 7826'},
    {'name': 'Alezy Antan', 'number': '+63 906 845 1732'},
  ];
}
