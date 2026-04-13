import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../services/arduino_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../main.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _arduino = ArduinoService();
  StreamSubscription<List<Map<String, dynamic>>>? _alertStreamSubscription;
  StreamSubscription<Map<String, dynamic>>? _deviceStateSubscription;

  bool _led = false;
  bool _buzzer = false;
  bool _armed = false;
  bool _pirEnabled = true;
  bool _ultrasonicEnabled = true;
  bool _pirLoading = false;
  bool _ultrasonicLoading = false;
  int _distanceThreshold = 50;
  int _alertCount = 0;
  String _lastAlert = 'No alerts yet';
  bool _ledLoading = false;
  bool _buzzerLoading = false;
  bool _armLoading = false;
  int? previousLastAlertId;

  @override
  void initState() {
    super.initState();
    _loadSavedThreshold();
    _initializeDashboard();
    _arduino.startListening();

    // Real-time alert stream
    _alertStreamSubscription = _arduino.alertStream.listen((alerts) {
      if (!mounted) return;
      setState(() {
        _alertCount = alerts.length;
        _lastAlert = alerts.isNotEmpty
            ? '${alerts.first['type']} (${alerts.first['status']})'
            : 'No alerts yet';
      });
      if (alerts.isNotEmpty &&
          (previousLastAlertId == null ||
              alerts.first['id'] != previousLastAlertId)) {
        previousLastAlertId = alerts.first['id'];
        _showAlertBanner(alerts.first['type'] ?? 'Alert');
        // ESP32 auto-turns LED+Buzzer OFF after alert (2 s window).
        // Mirror that in the UI after 3 s.
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() {
            _led = false;
            _buzzer = false;
          });
        });
      }
    });

    // Device state stream — keeps LED/Buzzer UI in sync with ESP32
    _deviceStateSubscription = _arduino.dataStream.listen((data) {
      if (!mounted) return;
      setState(() {
        if (data.containsKey('led_enabled')) _led = data['led_enabled'];
        if (data.containsKey('buzzer_enabled')) _buzzer = data['buzzer_enabled'];
        if (data.containsKey('monitoringArmed')) _armed = data['monitoringArmed'];
      });
    });
  }

  Future<void> _initializeDashboard() async {
    await _arduino.startKeypadListening();
    if (!mounted) return;
    setState(() {
      _armed = _arduino.monitoringArmed;
      _led = _arduino.ledStatus;
      _buzzer = _arduino.buzzerStatus;
      _pirEnabled = _arduino.pirEnabled;
      _ultrasonicEnabled = _arduino.ultrasonicEnabled;
    });
  }

  Future<void> _sendSensorCommand(String command, VoidCallback onSuccess) async {
    await _arduino.sendCommand(command);
    onSuccess();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Command sent: $command'),
        backgroundColor: AppColors.alertGreen,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _setDistanceThreshold(int cm) async {
    await _arduino.setDistanceThreshold(cm);
    await _saveThreshold(cm);
    if (mounted) {
      setState(() => _distanceThreshold = cm);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ultrasonic threshold set to $cm cm'),
        backgroundColor: AppColors.alertGreen,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _loadSavedThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('ultrasonic_threshold');
    if (saved != null && mounted) setState(() => _distanceThreshold = saved);
  }

  Future<void> _saveThreshold(int cm) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ultrasonic_threshold', cm);
  }

  void _showAlertBanner(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.warning_amber, color: Colors.white),
        const SizedBox(width: 8),
        Text('ALERT: $message',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
      backgroundColor: AppColors.alertRed,
      duration: const Duration(seconds: 4),
    ));
  }

  /// ARM -> sends MONITORING_ON, then immediately turns LED ON (buzzer stays OFF).
  /// DISARM -> sends MONITORING_OFF + LED_OFF + BUZZER_OFF.
  Future<void> _toggleArm() async {
    setState(() => _armLoading = true);
    final newArmed = !_armed;

    if (newArmed) {
      // ARM - turn ON monitoring and LED immediately, buzzer stays OFF until actual alert
      await _arduino.setMonitoring(true);
      await _arduino.setLed(true);
      await _arduino.setBuzzer(false); // Buzzer should be OFF when armed (only LED as status)
      // LCD text updated automatically by Arduino
      if (mounted) {
        setState(() {
          _armed = true;
          _led = true;
          _buzzer = false; // Buzzer OFF when armed
          _armLoading = false;
        });
      }
    } else {
      // DISARM - turn everything off
      await _arduino.setMonitoring(false);
      await _arduino.setLed(false);
      await _arduino.setBuzzer(false);
      // LCD text updated automatically by Arduino
      if (mounted) {
        setState(() {
          _armed = false;
          _led = false;
          _buzzer = false;
          _armLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _alertStreamSubscription?.cancel();
    _deviceStateSubscription?.cancel();
    super.dispose();
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
            Row(
              children: [
                _statCard('🔴', 'Monitor\nEvents: $_alertCount'),
                const SizedBox(width: 8),
                _statCard('📡', 'Device\nOnline: 1'),
              ],
            ),
            const SizedBox(height: 16),

            // ARM / DISARM
            GestureDetector(
              onTap: _armLoading ? null : _toggleArm,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _armed
                      ? AppColors.alertRed.withOpacity(0.15)
                      : AppColors.cardMid,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _armed
                          ? AppColors.alertRed
                          : AppColors.cyanDark),
                ),
                child: Row(
                  children: [
                    _armLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.cyan))
                        : Icon(
                            _armed ? Icons.shield : Icons.shield_outlined,
                            color: _armed
                                ? AppColors.alertRed
                                : AppColors.cyan,
                            size: 22),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _armed ? 'SYSTEM ARMED' : 'SYSTEM DISARMED',
                          style: TextStyle(
                            color: _armed
                                ? AppColors.alertRed
                                : AppColors.cyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _armed
                              ? 'LED ON - Buzzer activates on alert'
                              : 'No alerts triggered - tap to arm',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Text('Sensor Control', style: AppTextStyles.heading),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _alarmCard(
                    icon: '👁',
                    label: 'PIR Sensor',
                    status: _pirEnabled,
                    loading: _pirLoading,
                    subtitle: _pirEnabled
                        ? 'Motion detection active'
                        : 'PIR sensor disabled',
                    onTap: () async {
                      setState(() => _pirLoading = true);
                      await _sendSensorCommand(
                          _pirEnabled ? 'PIR_OFF' : 'PIR_ON', () {
                        _pirEnabled = !_pirEnabled;
                      });
                      setState(() => _pirLoading = false);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _alarmCard(
                    icon: '📡',
                    label: 'Ultrasonic',
                    status: _ultrasonicEnabled,
                    loading: _ultrasonicLoading,
                    subtitle: _ultrasonicEnabled
                        ? 'Distance monitoring active'
                        : 'Ultrasonic disabled',
                    onTap: () async {
                      setState(() => _ultrasonicLoading = true);
                      await _sendSensorCommand(
                          _ultrasonicEnabled
                              ? 'ULTRASONIC_OFF'
                              : 'ULTRASONIC_ON', () {
                        _ultrasonicEnabled = !_ultrasonicEnabled;
                      });
                      setState(() => _ultrasonicLoading = false);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Ultrasonic threshold slider
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardMid,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cyanDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ultrasonic Threshold',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(height: 6),
                  Text('Trigger alert below $_distanceThreshold cm',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.cyan,
                      inactiveTrackColor: AppColors.cyanDark,
                      thumbColor: AppColors.cyan,
                      overlayColor: AppColors.cyan.withOpacity(0.2),
                    ),
                    child: Slider(
                      min: 10,
                      max: 200,
                      divisions: 19,
                      value: _distanceThreshold.toDouble(),
                      onChanged: _ultrasonicEnabled
                          ? (val) =>
                              setState(() => _distanceThreshold = val.toInt())
                          : null,
                      onChangeEnd: _ultrasonicEnabled
                          ? (val) => _setDistanceThreshold(val.toInt())
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Last alert banner
            if (_lastAlert != 'No alerts yet')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.alertRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.alertRed.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: AppColors.alertRed, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Last alert: $_lastAlert',
                          style: const TextStyle(
                              color: AppColors.alertRed, fontSize: 13)),
                    ),
                  ],
                ),
              ),

            const Text('Alarm Status', style: AppTextStyles.heading),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _alarmCard(
                    icon: '💡',
                    label: 'LED Indicator',
                    status: _led,
                    loading: _ledLoading,
                    subtitle: _led
                        ? 'Light is ON'
                        : _armed
                            ? 'Tap to turn back ON'
                            : 'Light is OFF',
                    onTap: () async {
                      setState(() => _ledLoading = true);
                      final newState = !_led;
                      await _arduino.setLed(newState);
                      setState(() {
                        _led = newState;
                        _ledLoading = false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _alarmCard(
                    icon: '🔔',
                    label: 'Buzzer Alarm',
                    status: _buzzer,
                    loading: _buzzerLoading,
                    subtitle: _buzzer
                        ? 'Alarm is ON'
                        : _armed
                            ? 'Activates during alerts'
                            : 'Alarm is OFF',
                    onTap: () async {
                      setState(() => _buzzerLoading = true);
                      final newState = !_buzzer;
                      await _arduino.setBuzzer(newState);
                      setState(() {
                        _buzzer = newState;
                        _buzzerLoading = false;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
          border:
              Border.all(color: AppColors.cyanDark.withOpacity(0.5)),
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
    required bool loading,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
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
            loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.cyan))
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: status
                          ? AppColors.alertGreen
                          : AppColors.cardDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status ? 'ON' : 'OFF',
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
