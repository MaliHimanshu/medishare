import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:medishare/app/app.dart';

void main() {
  testWidgets('MediShare app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MediShareApp());
    await tester.pump();
    // Advance time to allow the 2.8s splash timer to fire and complete
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    
    // App should render without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
