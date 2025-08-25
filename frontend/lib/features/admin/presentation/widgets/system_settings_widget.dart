import 'package:flutter/material.dart';

class SystemSettingsWidget extends StatelessWidget {
  const SystemSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'System Settings – Platform configurations and feature flags (not implemented yet).',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
} 