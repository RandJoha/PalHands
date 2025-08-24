import 'package:flutter/material.dart';

class ReportsWidget extends StatelessWidget {
  const ReportsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Report and Dispute Manager – User report and resolve dispute (not implemented yet).',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
} 