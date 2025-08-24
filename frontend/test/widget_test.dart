// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:palhands/main.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const PalHandsApp());
  // Avoid waiting for async providers/animations that may never settle in tests
  await tester.pump(const Duration(milliseconds: 16));

    // Basic smoke assertions
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
