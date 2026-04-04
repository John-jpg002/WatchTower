// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/arduino_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _arduino = ArduinoService();
  bool _led = false;
  bool _buzzer = false;
  String _lcdText = 'NUMBER SAVE!\n+63955213232';

  @override
  void initState() {
    super.initState();
    _arduino.dataStream.listen((data) {
      if (mounted) {
        setState(() {
          _led = data['led'] ?? _led;
          _buzzer = data['buzzer'] ?? _buzzer;
          _lcdText = data['lcd'] ?? _lcdText;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const WatchtowerAppBar(),
      endDrawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard', style: AppTextStyles.heading),
            const SizedBox(height: 16),

            // Stats Row
            Row(
              children: [
                _statCard('🔴', 'Monitor\nEvents: 0'),
                const SizedBox(width: 8),
                _statCard('📱', 'Saved\nContact: 1'),
                const SizedBox(width: 8),
                _statCard('📡', 'Device\nOnline: 3'),
              ],
            ),
            const SizedBox(height: 20),

            const Text('Alarm Status', style: AppTextStyles.heading),
            const SizedBox(height: 12),

            // LED & Buzzer controls
            Row(
              children: [
                Expanded(child: _alarmCard(
                  icon: '💡',
                  label: 'LED Indicator',
                  status: _led,
                  activeLabel: 'ON',
                  inactiveLabel: 'OFF',
                  subtitle: _led
                      ? 'Light is currently active'
                      : 'Light is currently inactive',
                  onTap: () async {
                    await _arduino.toggleLED();
                    setState(() => _led = _arduino.ledStatus);
                  },
                )),
                const SizedBox(width: 12),
                Expanded(child: _alarmCard(
                  icon: '🔔',
                  label: 'Buzzer Alarm',
                  status: _buzzer,
                  activeLabel: 'ON',
                  inactiveLabel: 'OFF',
                  subtitle: _buzzer
                      ? 'Alarm is triggered'
                      : 'Waiting for alarm trigger',
                  onTap: () async {
                    await _arduino.toggleBuzzer();
                    setState(() => _buzzer = _arduino.buzzerStatus);
                  },
                )),
              ],
            ),
            const SizedBox(height: 20),

            // LCD Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardMid,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cyanDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.alertGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('LCD Display output',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.lcdBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _lcdText,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        color: AppColors.lcdGreen,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.cardMid,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cyanDark.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _alarmCard({
    required String icon,
    required String label,
    required bool status,
    required String activeLabel,
    required String inactiveLabel,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardMid,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: status
                ? AppColors.alertGreen.withOpacity(0.5)
                : AppColors.cyanDark.withOpacity(0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: status
                    ? AppColors.alertGreen
                    : AppColors.cardDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status ? activeLabel : inactiveLabel,
                style: TextStyle(
                  color: status
                      ? Colors.white
                      : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(subtitle,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
