// lib/screens/alert_log_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
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
    // Ensure the stream is active (safe to call multiple times — guarded)
    _arduino.startListening();

    // ── Subscribe to the live stream ──────────────────────
    // The ArduinoService streams the full alert_logs table ordered by id desc.
    // Every INSERT on alert_logs triggers a Supabase realtime event which
    // pushes a fresh list here — no manual reload needed.
    _alertSubscription = _arduino.alertStream.listen((alerts) {
      if (!mounted) return;
      setState(() {
        _alerts = List<Map<String, dynamic>>.from(alerts);
        _loading = false;
      });
    });

    // Show a spinner until the first stream event arrives.
    // Belt-and-suspenders: if the stream takes > 5 s, stop the spinner.
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _loading) setState(() => _loading = false);
    });
  }

  String _formatTimestamp(dynamic raw) {
    if (raw == null) return 'Time unavailable';
    final value = raw.toString();
    if (value.isEmpty) return 'Time unavailable';
    final normalized = value.replaceAll(' ', 'T');
    final parsed = DateTime.tryParse(normalized);
    if (parsed != null) {
      return parsed.toLocal().toString().split('.').first;
    }
    return value;
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Group alerts by their 'period' field (or 'Latest' fallback)
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final alert in _alerts) {
      grouped
          .putIfAbsent(alert['period'] ?? 'Latest', () => [])
          .add(alert);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const WatchtowerAppBar(),
      endDrawer: const AppDrawer(),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.cyan))
          : _alerts.isEmpty
              ? const Center(
                  child: Text('No alerts yet.',
                      style:
                          TextStyle(color: AppColors.textSecondary)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Alert Log',
                              style: AppTextStyles.heading),
                          const Spacer(),
                          // Live indicator dot
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.alertGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('Live',
                              style: TextStyle(
                                  color: AppColors.alertGreen,
                                  fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (grouped.isEmpty)
                        const Center(
                          child: Text('No alerts yet.',
                              style: TextStyle(
                                  color: AppColors.textSecondary)),
                        )
                      else
                        ...grouped.entries.map((entry) => Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
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
    final rawTimestamp =
        alert['created_at'] ?? alert['time'] ?? '';
    final timestamp = _formatTimestamp(rawTimestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              color: isAlert
                  ? AppColors.alertRed
                  : AppColors.alertGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${alert['type']}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  timestamp,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isAlert
                  ? AppColors.alertRed.withOpacity(0.15)
                  : AppColors.alertGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              alert['status'] ?? '',
              style: TextStyle(
                color: isAlert
                    ? AppColors.alertRed
                    : AppColors.alertGreen,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
