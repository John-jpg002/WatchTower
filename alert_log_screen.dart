// lib/screens/alert_log_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../utils/constants.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../services/arduino_service.dart';

class AlertLogScreen extends StatefulWidget {
  const AlertLogScreen({super.key});

  @override
  State<AlertLogScreen> createState() => _AlertLogScreenState();
}

class _AlertLogScreenState extends State<AlertLogScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _alertSubscription;
  final _arduino = ArduinoService();

  @override
  void initState() {
    super.initState();
    _arduino.startListening();
    _fetchAlerts();
    _subscribeAlerts();
  }

  Future<void> _fetchAlerts() async {
    setState(() => _loading = true);
    try {
      final data = await supabase
          .from('alert_logs')
          .select()
          .order('id', ascending: false);

      if (!mounted) return;
      setState(() => _alerts = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      setState(() => _alerts = []);
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _formatTimestamp(dynamic raw) {
    if (raw == null) return 'Time unavailable';
    final value = raw.toString();
    if (value.isEmpty) return 'Time unavailable';

    final normalized = value.replaceAll(' ', 'T');
    final parsed = DateTime.tryParse(normalized);
    if (parsed != null) {
      return parsed.toString().split('.').first;
    }

    return value;
  }

  void _subscribeAlerts() {
    _alertSubscription = _arduino.alertStream.listen((alerts) {
      if (!mounted) return;
      setState(() {
        _alerts = List<Map<String, dynamic>>.from(alerts);
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    super.dispose();
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
                              ...entry.value.map((alert) => _alertCard(alert)),
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
    final rawTimestamp = alert['created_at'] ?? alert['time'] ?? '';
    final timestamp = _formatTimestamp(rawTimestamp);

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
              color: isAlert ? AppColors.alertRed : AppColors.alertGreen,
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
                      text: '${alert['type']} at $timestamp',
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
