import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medishare/app/app.dart';

void main() {
  testWidgets('MediShare app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MediShareApp());
    // App should render without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
