// lib/screens/keypad_screen.dart

import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/arduino_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';

class KeypadScreen extends StatefulWidget {
  const KeypadScreen({super.key});

  @override
  State<KeypadScreen> createState() => _KeypadScreenState();
}

class _KeypadScreenState extends State<KeypadScreen> {
  String _input = '';
  final _arduino = ArduinoService();
  String _savedNumber = '';
  String _lcdText = 'NO NUMBER SAVED';

  @override
  void initState() {
    super.initState();
    _savedNumber = _arduino.savedNumber;
    _lcdText = _arduino.lcdText;
    _arduino.dataStream.listen((data) {
      if (mounted) {
        setState(() {
          _savedNumber = data['savedNumber'] ?? _savedNumber;
          _lcdText = data['lcd'] ?? _lcdText;
        });
      }
    });
  }

  void _press(String val) {
    setState(() => _input += val);
  }

  void _delete() {
    if (_input.isNotEmpty) {
      setState(() => _input = _input.substring(0, _input.length - 1));
    }
  }

  Future<void> _save() async {
    if (_input.isNotEmpty) {
      await _arduino.savePhoneNumber(_input);
      setState(() {
        _savedNumber = _input;
        _input = '';
      });
    }
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
            const Text('Keypad', style: AppTextStyles.heading),
            const SizedBox(height: 16),

            // Enter number label
            const Text('ENTER PHONE NUMBER',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 1)),
            const SizedBox(height: 8),

            // Display field
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.cardMid,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cyanDark),
              ),
              child: Text(
                _input.isEmpty ? '|' : _input,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    letterSpacing: 2),
              ),
            ),
            const SizedBox(height: 16),

            // Keypad grid
            _buildKeypad(),
            const SizedBox(height: 20),

            // LCD Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardMid,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.alertGreen,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('LCD Display output',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.lcdBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _lcdText,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        color: AppColors.lcdGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Currently saved number
            const Text('CURRENTLY SAVE NUMBER',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardMid,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cyanDark),
              ),
              child: Text(_savedNumber,
                  style: const TextStyle(color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.cyanDark),
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {},
                    child: const Text('View Saved'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _save,
                    child: const Text('Replace'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    return Column(
      children: [
        ...rows.map((row) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: row.map((d) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _keyButton(d, onTap: () => _press(d)),
              ),
            )).toList(),
          ),
        )),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _keyButton('⌫',
                    color: AppColors.alertRed.withOpacity(0.8),
                    onTap: _delete),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _keyButton('0', onTap: () => _press('0')),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _keyButton('✓ Save',
                    color: AppColors.alertGreen, onTap: _save),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _keyButton(String label,
      {Color? color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: color ?? AppColors.cardMid,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
