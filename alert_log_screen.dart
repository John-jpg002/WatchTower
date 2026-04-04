// lib/screens/alert_log_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../utils/constants.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';

class AlertLogScreen extends StatefulWidget {
  const AlertLogScreen({super.key});

  @override
  State<AlertLogScreen> createState() => _AlertLogScreenState();
}

class _AlertLogScreenState extends State<AlertLogScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    setState(() => _loading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      final data = await supabase
          .from('alert_logs')
          .select()
          .eq('user_id', userId ?? '')
          .order('id', ascending: false);
      setState(() => _alerts = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      // If table is empty or error, show empty state
      setState(() => _alerts = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  // Call this from Arduino service when motion is detected
  static Future<void> logAlert({
    required String type,
    required String status,
    required String time,
    required String period,
  }) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      await Supabase.instance.client.from('alert_logs').insert({
        'type': type,
        'status': status,
        'time': time,
        'period': period,
        'user_id': userId,
      });
    } catch (e) {
      // Handle silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final alert in _alerts) {
      grouped.putIfAbsent(alert['period'] ?? 'Latest', () => []).add(alert);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const WatchtowerAppBar(),
      endDrawer: const AppDrawer(),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.cyan))
          : _alerts.isEmpty
              ? const Center(
                  child: Text('No alerts yet.',
                      style: TextStyle(color: AppColors.textSecondary)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Alert Log', style: AppTextStyles.heading),
                      const SizedBox(height: 16),
                      ...grouped.entries.map((entry) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.key,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              ...entry.value
                                  .map((alert) => _alertCard(alert)),
                              const SizedBox(height: 16),
                            ],
                          )),
                    ],
                  ),
                ),
    );
  }

  Widget _alertCard(Map<String, dynamic> alert) {
    final isAlert = alert['status'] == 'Alert';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardMid,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlert
              ? AppColors.alertRed.withOpacity(0.3)
              : AppColors.alertGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isAlert ? Icons.warning_amber : Icons.sms,
              color:
                  isAlert ? AppColors.alertRed : AppColors.alertGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${alert['type']} ',
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13),
                    ),
                    TextSpan(
                      text: '(${alert['status']})',
                      style: TextStyle(
                        color: isAlert
                            ? AppColors.alertRed
                            : AppColors.alertGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text('Time: ${alert['time']}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
