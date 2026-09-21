import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:medishare/features/auth/register_screen.dart';
import 'package:medishare/providers/auth_provider.dart';

class FakeAuthProvider extends AuthProvider {
  String? lastRegisteredRole;
  String? lastRegisteredName;
  String? lastRegisteredEmail;

  @override
  bool get isLoading => false;

  @override
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? address,
  }) async {
    lastRegisteredRole = role;
    lastRegisteredName = name;
    lastRegisteredEmail = email;
    return true;
  }
}

void main() {
  testWidgets('RegisterScreen displays all 4 role cards with correct titles, subtitles, and icons', (tester) async {
    final fakeAuth = FakeAuthProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: fakeAuth,
        child: const MaterialApp(
          home: RegisterScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify all 4 titles exist
    expect(find.text('Donor'), findsOneWidget);
    expect(find.text('NGO'), findsOneWidget);
    expect(find.text('Hospital'), findsOneWidget);
    expect(find.text('Recipient'), findsOneWidget);

    // Verify all 4 subtitles exist
    expect(find.text('Donate or rent medical equipment'), findsOneWidget);
    expect(find.text('Manage and distribute equipment'), findsOneWidget);
    expect(find.text('Request and manage equipment'), findsOneWidget);
    expect(find.text('Request equipment for personal use'), findsOneWidget);

    // Verify vector icons exist
    expect(find.byIcon(Icons.volunteer_activism_rounded), findsOneWidget);
    expect(find.byIcon(Icons.diversity_3_rounded), findsOneWidget);
    expect(find.byIcon(Icons.local_hospital_rounded), findsOneWidget);
    expect(find.byIcon(Icons.personal_injury_rounded), findsOneWidget);

    // Verify no emojis are displayed for roles
    expect(find.text('🤲'), findsNothing);
    expect(find.text('🏢'), findsNothing);
    expect(find.text('🏥'), findsNothing);
  });

  testWidgets('Selecting Recipient role card submits RECIPIENT to auth provider', (tester) async {
    final fakeAuth = FakeAuthProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: fakeAuth,
        child: const MaterialApp(
          home: RegisterScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Recipient card
    await tester.tap(find.text('Recipient'));
    await tester.pumpAndSettle();

    // Fill form
    await tester.enterText(find.widgetWithText(TextField, 'John Doe'), 'Jane Recipient');
    await tester.enterText(find.widgetWithText(TextField, 'you@example.com'), 'jane.recipient@example.com');
    await tester.enterText(find.widgetWithText(TextField, '10-digit mobile number'), '9876543210');
    await tester.enterText(find.widgetWithText(TextField, 'Min 8 chars, uppercase + number'), 'Password123');
    await tester.enterText(find.widgetWithText(TextField, 'Repeat your password'), 'Password123');

    // Tap submit button
    await tester.ensureVisible(find.text('Create Free Account'));
    await tester.tap(find.text('Create Free Account'));
    await tester.pumpAndSettle();

    // Verify RECIPIENT was passed
    expect(fakeAuth.lastRegisteredRole, 'RECIPIENT');
    expect(fakeAuth.lastRegisteredName, 'Jane Recipient');
    expect(fakeAuth.lastRegisteredEmail, 'jane.recipient@example.com');
  });

  testWidgets('Selecting Hospital role card submits HOSPITAL to auth provider', (tester) async {
    final fakeAuth = FakeAuthProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: fakeAuth,
        child: const MaterialApp(
          home: RegisterScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Hospital card
    await tester.tap(find.text('Hospital'));
    await tester.pumpAndSettle();

    // Fill form
    await tester.enterText(find.widgetWithText(TextField, 'John Doe'), 'City Care Hospital');
    await tester.enterText(find.widgetWithText(TextField, 'you@example.com'), 'hospital@example.com');
    await tester.enterText(find.widgetWithText(TextField, '10-digit mobile number'), '9876543211');
    await tester.enterText(find.widgetWithText(TextField, 'Min 8 chars, uppercase + number'), 'Password123');
    await tester.enterText(find.widgetWithText(TextField, 'Repeat your password'), 'Password123');

    // Tap submit button
    await tester.ensureVisible(find.text('Create Free Account'));
    await tester.tap(find.text('Create Free Account'));
    await tester.pumpAndSettle();

    // Verify HOSPITAL was passed
    expect(fakeAuth.lastRegisteredRole, 'HOSPITAL');
  });
}
