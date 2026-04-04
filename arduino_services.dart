// lib/services/arduino_service.dart
// This service handles communication with Arduino via Bluetooth (flutter_bluetooth_serial)
// or WiFi (http package). Adjust based on your hardware setup.

import 'dart:async';

class ArduinoService {
  static final ArduinoService _instance = ArduinoService._internal();
  factory ArduinoService() => _instance;
  ArduinoService._internal();

  // ─── State ─────────────────────────────────────────────────────────────────
  bool _ledStatus = false;
  bool _buzzerStatus = false;
  String _lcdText = 'NO NUMBER SAVED';
  String _savedNumber = '';

  final StreamController<Map<String, dynamic>> _dataController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;
  bool get ledStatus => _ledStatus;
  bool get buzzerStatus => _buzzerStatus;
  String get lcdText => _lcdText;
  String get savedNumber => _savedNumber;

  // ─── Simulated Arduino Data ─────────────────────────────────────────────────
  // Replace this section with actual Bluetooth or HTTP calls to your Arduino.
  //
  // For Bluetooth (HC-05/HC-06):
  //   Add flutter_bluetooth_serial to pubspec.yaml
  //   Use BluetoothConnection.toAddress(address) to connect
  //   Write: connection.output.add(Uint8List.fromList(utf8.encode(command)));
  //   Read: connection.input!.listen((data) { ... });
  //
  // For WiFi (ESP8266/ESP32):
  //   Use http.get(Uri.parse('http://192.168.x.x/status'))
  //   Use http.post(Uri.parse('http://192.168.x.x/control'), body: {'cmd': 'LED_ON'})

  Future<void> sendCommand(String command) async {
    // TODO: Replace with actual Bluetooth/WiFi send
    // Example Bluetooth:
    //   connection?.output.add(Uint8List.fromList(utf8.encode('$command\n')));
    //
    // Example WiFi (ESP32):
    //   await http.post(Uri.parse('http://192.168.1.100/command'),
    //     body: {'cmd': command});

    // Simulate response
    await Future.delayed(const Duration(milliseconds: 300));
    _handleResponse(command);
  }

  void _handleResponse(String command) {
    switch (command) {
      case 'LED_ON':
        _ledStatus = true;
        break;
      case 'LED_OFF':
        _ledStatus = false;
        break;
      case 'BUZZER_ON':
        _buzzerStatus = true;
        break;
      case 'BUZZER_OFF':
        _buzzerStatus = false;
        break;
    }
    _dataController.add({
      'led': _ledStatus,
      'buzzer': _buzzerStatus,
      'lcd': _lcdText,
      'savedNumber': _savedNumber,
    });
  }

  Future<void> toggleLED() async {
    await sendCommand(_ledStatus ? 'LED_OFF' : 'LED_ON');
  }

  Future<void> toggleBuzzer() async {
    await sendCommand(_buzzerStatus ? 'BUZZER_OFF' : 'BUZZER_ON');
  }

  Future<void> savePhoneNumber(String number) async {
    _savedNumber = number;
    _lcdText = 'NUMBER SAVE!\n$number';
    // TODO: Send to Arduino
    // await sendCommand('SAVE_NUM:$number');
    _dataController.add({
      'led': _ledStatus,
      'buzzer': _buzzerStatus,
      'lcd': _lcdText,
      'savedNumber': _savedNumber,
    });
  }

  // Simulate incoming motion alert (Arduino sends this)
  void simulateMotionAlert() {
    _dataController.add({
      'alert': 'Motion detected',
      'type': 'Alert',
      'time': DateTime.now().toString(),
    });
  }

  void dispose() {
    _dataController.close();
  }
}
