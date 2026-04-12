// lib/services/arduino_service.dart
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class ArduinoService {
  static final ArduinoService _instance = ArduinoService._internal();
  factory ArduinoService() => _instance;
  ArduinoService._internal();

  final _supabase = Supabase.instance.client;

  // ── Device status flags ────────────────────────────────
  bool _ledStatus = false;
  bool _buzzerStatus = false;
  bool _pirEnabled = true;
  bool _ultrasonicEnabled = true;
  bool _monitoringArmed = false;
  bool _smsEnabled = true;
  int _distanceThreshold = 50;

  bool _isKeypadListening = false;
  bool _isAlertListening = false;

  bool get ledStatus => _ledStatus;
  bool get buzzerStatus => _buzzerStatus;
  bool get pirEnabled => _pirEnabled;
  bool get ultrasonicEnabled => _ultrasonicEnabled;
  bool get monitoringArmed => _monitoringArmed;
  bool get smsEnabled => _smsEnabled;
  int get distanceThreshold => _distanceThreshold;

  // ── Phone + LCD state ──────────────────────────────────
  String _savedNumber = '';
  // Default LCD text shown when the system starts up
  String _lcdText = 'SYSTEM READY';

  String get savedNumber => _savedNumber;
  String get lcdText => _lcdText;

  // ── Streams ────────────────────────────────────────────
  final StreamController<Map<String, dynamic>> _dataController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;

  final StreamController<List<Map<String, dynamic>>> _alertController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get alertStream =>
      _alertController.stream;

  // ── Device state loader ────────────────────────────────
  Future<void> loadDeviceState() async {
    try {
      final data = await _supabase
          .from('device_state')
          .select()
          .order('id', ascending: false)
          .limit(1);

      if (data is List && data.isNotEmpty) {
        final latest = Map<String, dynamic>.from(data.first);
        _savedNumber = latest['phone'] ?? _savedNumber;
        _lcdText = latest['lcd'] ?? _lcdText;
        _smsEnabled = latest['sms_enabled'] ?? _smsEnabled;
        _monitoringArmed =
            latest['monitoring_armed'] ?? _monitoringArmed;
        _dataController.add({
          'savedNumber': _savedNumber,
          'lcd': _lcdText,
          'smsEnabled': _smsEnabled,
          'monitoringArmed': _monitoringArmed,
        });
      }
    } catch (e) {
      print('Device state load error: $e');
    }
  }

  // ── Keypad / LCD listener ──────────────────────────────
  Future<void> startKeypadListening() async {
    if (_isKeypadListening) return;
    _isKeypadListening = true;
    await loadDeviceState();

    _supabase
        .from('device_state')
        .stream(primaryKey: ['id'])
        .order('id', ascending: false)
        .limit(1)
        .listen((data) {
          if (data.isNotEmpty) {
            final latest = data.first;
            _savedNumber = latest['phone'] ?? _savedNumber;
            _lcdText = latest['lcd'] ?? _lcdText;
            _smsEnabled = latest['sms_enabled'] ?? _smsEnabled;
            _monitoringArmed =
                latest['monitoring_armed'] ?? _monitoringArmed;
            _dataController.add({
              'savedNumber': _savedNumber,
              'lcd': _lcdText,
              'smsEnabled': _smsEnabled,
              'monitoringArmed': _monitoringArmed,
            });
          }
        });
  }

  // ── Alert log listener ─────────────────────────────────
  // Uses Supabase Realtime — fires on every INSERT to alert_logs.
  void startListening() {
    if (_isAlertListening) return;
    _isAlertListening = true;

    _supabase
        .from('alert_logs')
        .stream(primaryKey: ['id'])
        .order('id', ascending: false)
        .listen((data) {
          _alertController.add(data);
        });
  }

  // ── Save phone number ──────────────────────────────────
  Future<void> savePhoneNumber(String number) async {
    try {
      await _supabase.from('device_state').insert({
        'phone': number,
        'lcd': 'NUMBER SAVED',
        'sms_enabled': _smsEnabled,
        'monitoring_armed': _monitoringArmed,
      });
      _savedNumber = number;
      _lcdText = 'NUMBER SAVED';
      _dataController.add({'savedNumber': _savedNumber, 'lcd': _lcdText});
    } catch (e) {
      print('Save error: $e');
    }
  }

  // ── Generic command sender ─────────────────────────────
  Future<void> sendCommand(String command) async {
    try {
      await _supabase.from('device_commands').insert({
        'command': command,
        'executed': 'false',
      });
    } catch (e) {
      print('Command error: $e');
    }
  }

  // ── LED ────────────────────────────────────────────────
  /// Explicitly set LED to [on] state (does NOT toggle).
  Future<void> setLed(bool on) async {
    _ledStatus = on;
    await sendCommand(on ? 'LED_ON' : 'LED_OFF');
  }

  /// Toggle LED (convenience wrapper).
  Future<void> toggleLED() async {
    await setLed(!_ledStatus);
  }

  // ── Buzzer ─────────────────────────────────────────────
  /// Explicitly set Buzzer to [on] state (does NOT toggle).
  /// This fixes the bug where turning buzzer OFF still played sound
  /// because toggleBuzzer() was racing with the previous state.
  Future<void> setBuzzer(bool on) async {
    _buzzerStatus = on;
    await sendCommand(on ? 'BUZZER_ON' : 'BUZZER_OFF');
  }

  /// Toggle Buzzer (convenience wrapper).
  Future<void> toggleBuzzer() async {
    await setBuzzer(!_buzzerStatus);
  }

  // ── PIR sensor ─────────────────────────────────────────
  Future<void> togglePIR() async {
    _pirEnabled = !_pirEnabled;
    await sendCommand(_pirEnabled ? 'PIR_ON' : 'PIR_OFF');
  }

  // ── Ultrasonic sensor ──────────────────────────────────
  Future<void> toggleUltrasonic() async {
    _ultrasonicEnabled = !_ultrasonicEnabled;
    await sendCommand(
        _ultrasonicEnabled ? 'ULTRASONIC_ON' : 'ULTRASONIC_OFF');
  }

  // ── ARM / DISARM monitoring ────────────────────────────
  /// Sets monitoring armed state WITHOUT touching LED/Buzzer.
  /// The dashboard calls setLed() and setBuzzer() explicitly after this.
  Future<void> setMonitoringArmed(bool armed) async {
    _monitoringArmed = armed;
    await sendCommand(armed ? 'MONITORING_ON' : 'MONITORING_OFF');
  }

  /// Legacy method kept for compatibility — now delegates to setMonitoringArmed.
  Future<void> setMonitoring(bool armed) async {
    await setMonitoringArmed(armed);
  }

  // ── LCD text update ────────────────────────────────────
  /// Inserts a new device_state row with the given LCD text so the
  /// ESP32 can pick it up and display it on the physical LCD.
  Future<void> setLcdText(String text) async {
    try {
      await _supabase.from('device_state').insert({
        'phone': _savedNumber,
        'lcd': text,
        'sms_enabled': _smsEnabled,
        'monitoring_armed': _monitoringArmed,
      });
      _lcdText = text;
      _dataController.add({'savedNumber': _savedNumber, 'lcd': _lcdText});
    } catch (e) {
      print('LCD update error: $e');
    }
  }

  // ── Distance threshold ─────────────────────────────────
  Future<void> setDistanceThreshold(int cm) async {
    _distanceThreshold = cm;
    await sendCommand('SET_DISTANCE_$cm');
  }

  // ── SMS toggle ─────────────────────────────────────────
  Future<void> setSmsEnabled(bool enabled) async {
    _smsEnabled = enabled;
    await sendCommand(enabled ? 'SMS_ON' : 'SMS_OFF');
  }

  // ── Cleanup ────────────────────────────────────────────
  void dispose() {
    _alertController.close();
    _dataController.close();
  }
}
