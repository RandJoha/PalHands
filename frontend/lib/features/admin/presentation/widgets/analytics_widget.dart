import 'package:flutter/material.dart';

class AnalyticsWidget extends StatelessWidget {
  const AnalyticsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Analytics – Platform growth and performance metrics (not implemented yet).',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
} 