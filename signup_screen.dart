// lib/screens/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../utils/constants.dart';
import 'dashboard_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _fullnameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _signUp() async {
    if (_fullnameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passwordCtrl.text.isEmpty ||
        _confirmCtrl.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      _showError('Passwords do not match');
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    setState(() => _loading = true);
    try {
      await supabase.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        data: {
          'full_name': _fullnameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
        },
      );
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (_) => false,
        );
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg), backgroundColor: AppColors.alertRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cyanDark),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cyanDark,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.remove_red_eye,
                      size: 36, color: AppColors.cyan),
                ),
                const SizedBox(height: 8),
                const Text('WATCHTOWER',
                    style: TextStyle(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3)),
                const Text('APP',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 10)),
                const SizedBox(height: 16),
                const Text('Create an Account',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const Text(
                    "Let's help you set up your account, it won't take long.",
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 16),
                _field('Fullname', _fullnameCtrl),
                const SizedBox(height: 10),
                _field('Email Address', _emailCtrl,
                    type: TextInputType.emailAddress),
                const SizedBox(height: 10),
                _field('Phone Number', _phoneCtrl,
                    type: TextInputType.phone),
                const SizedBox(height: 10),
                _field('New Password', _passwordCtrl, obscure: true),
                const SizedBox(height: 10),
                _field('Confirm Password', _confirmCtrl, obscure: true),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyan,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _loading ? null : _signUp,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Sign Up',
                            style:
                                TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text('Already have an account? Login',
                      style:
                          TextStyle(color: AppColors.cyan, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String hint, TextEditingController ctrl,
      {TextInputType type = TextInputType.text, bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: type,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        filled: true,
        fillColor: AppColors.cardMid,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      ),
    );
  }
}
