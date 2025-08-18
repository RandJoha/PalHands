import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../services/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String? token;
  final String? returnPath;
  const VerifyEmailScreen({super.key, this.token, this.returnPath});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  String? _status; // null = idle; 'ok' | error text

  Future<void> _verifyNow() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() => _status = 'Invalid or missing token.');
      return;
    }
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      // Try account verification; if that fails, try email-change confirmation
      var res = await auth.verifyEmail(token);
      if ((res['success'] ?? res['ok'] ?? false) != true) {
        res = await auth.confirmEmailChange(token);
      }
      if ((res['success'] ?? res['ok'] ?? false) == true) {
        setState(() => _status = 'ok');
      } else {
        setState(() => _status = (res['message'] ?? 'Verification failed').toString());
      }
    } catch (e) {
      setState(() => _status = 'Verification failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_status == null) ...[
              const Icon(Icons.mark_email_read, color: Colors.blueAccent, size: 48),
              const SizedBox(height: 12),
              const Text('Click verify to confirm your email.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _verifyNow,
                child: const Text('Verify Email'),
              ),
            ] else if (_status == 'ok') ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 12),
              const Text('Your email has been verified.'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Return to previous page or user dashboard, preserving state
                  final r = widget.returnPath;
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else if (r != null && r.isNotEmpty) {
                    Navigator.of(context).pushReplacementNamed(r);
                  } else {
                    Navigator.of(context).pushReplacementNamed('/user');
                  }
                },
                child: const Text('Continue'),
              ),
            ] else ...[
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(_status ?? 'Verification failed'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushReplacementNamed('/user');
                  }
                },
                child: const Text('Back'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
