import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'app_toast.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? token;
  const ResetPasswordScreen({super.key, this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.token != null && widget.token!.isNotEmpty) {
      _tokenCtrl.text = widget.token!;
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final res = await auth.resetPassword(token: _tokenCtrl.text.trim(), newPassword: _newCtrl.text);
      final ok = res['success'] == true;
      if (ok) {
        if (mounted) {
          AppToast.show(context, message: 'Password reset successfully. Please login.', type: AppToastType.success);
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } else {
        final msg = (res['message'] as String?) ?? 'Failed to reset password';
        if (mounted) {
          AppToast.show(context, message: msg, type: AppToastType.error);
        }
      }
    } catch (e) {
      if (mounted) {
  AppToast.show(context, message: 'Error: $e', type: AppToastType.error);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _tokenCtrl,
                    decoration: const InputDecoration(labelText: 'Token'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New Password'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm New Password'),
                    validator: (v) => (v != _newCtrl.text) ? 'Passwords do not match' : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text('Reset', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
