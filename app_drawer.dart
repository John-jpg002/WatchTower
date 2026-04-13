// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../utils/constants.dart';
import '../services/arduino_service.dart';
import '../screens/dashboard_screen.dart';
import '../screens/alert_log_screen.dart';
import '../screens/contacts_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/login_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  /// Disarm by sending raw commands — works with ANY version of ArduinoService
  /// because sendCommand() has always existed.
  Future<void> _disarmOnLogout() async {
    final arduino = ArduinoService();
    await arduino.sendCommand('MONITORING_OFF');
    await arduino.sendCommand('LED_OFF');
    await arduino.sendCommand('BUZZER_OFF');
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final email = user?.email ?? 'user@email.com';

    return Drawer(
      backgroundColor: AppColors.cardDark,
      child: Column(
        children: [
          Container(
            color: AppColors.cyanDark,
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.remove_red_eye,
                      color: AppColors.cyan, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WATCHTOWER',
                        style: TextStyle(
                            color: AppColors.cyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      Text(
                        email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _sectionHeader('MONITOR'),
                _drawerItem(context, Icons.dashboard, 'Dashboard',
                    const DashboardScreen()),
                _drawerItem(context, Icons.notifications_active, 'Alert Log',
                    const AlertLogScreen()),
                _sectionHeader('MANAGE'),
                _drawerItem(context, Icons.contacts, 'Contacts',
                    const ContactsScreen()),
                _sectionHeader('SYSTEM'),
                _drawerItem(context, Icons.settings, 'Settings',
                    const SettingsScreen()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.alertRed.withOpacity(0.8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  await _disarmOnLogout();
                  await supabase.auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  }
                },
                child: const Text('Logout'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title,
          style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2)),
    );
  }

  Widget _drawerItem(
      BuildContext context, IconData icon, String label, Widget screen) {
    return ListTile(
      leading: Icon(icon, color: AppColors.cyan, size: 20),
      title: Text(label,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => screen));
      },
    );
  }
}
