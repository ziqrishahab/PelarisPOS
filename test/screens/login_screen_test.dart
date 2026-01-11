import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pelaris/providers/auth_provider.dart';
import 'package:pelaris/screens/auth/login_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginScreen Widget Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    Widget createLoginScreen() {
      return ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(mockAuthService),
        child: const MaterialApp(home: LoginScreen()),
      );
    }

    testWidgets('renders login form correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      // Verify title
      expect(find.text('Pelaris.id'), findsOneWidget);
      expect(find.text('Silakan login untuk melanjutkan'), findsOneWidget);

      // Verify form fields
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email & Password

      // Verify login button
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('shows email validation error for empty email', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      // Tap login without entering anything
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.textContaining('Email'), findsWidgets);
    });

    testWidgets('shows password validation error for empty password', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      // Enter email only
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@test.com');

      // Tap login
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Should show password validation error
      expect(find.textContaining('Password'), findsWidgets);
    });

    testWidgets('can enter text in email field', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      // Enter email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      // Verify text was entered
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('can enter text in password field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      // Enter password
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'mypassword123');
      await tester.pump();

      // Text was entered (obscured but still in field)
      final textField = tester.widget<TextFormField>(passwordField);
      expect(textField.controller?.text, 'mypassword123');
    });

    testWidgets('email field validates email format', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      // Enter invalid email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'invalid-email');

      // Enter password
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'password123');

      // Tap login
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Should show email validation error
      expect(find.textContaining('email'), findsWidgets);
    });

    testWidgets('logo and branding are displayed', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      // Verify store icon
      expect(find.byIcon(Icons.store_rounded), findsOneWidget);

      // Verify Pelaris.id title
      expect(find.text('Pelaris.id'), findsOneWidget);
    });
  });

  group('LoginScreen Accessibility Tests', () {
    testWidgets('form fields exist', (WidgetTester tester) async {
      final mockAuthService = MockAuthService();

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(mockAuthService),
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify TextFormFields are accessible
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('button is tappable', (WidgetTester tester) async {
      final mockAuthService = MockAuthService();

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(mockAuthService),
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Find and verify login button
      final loginButton = find.text('Login');
      expect(loginButton, findsOneWidget);

      // Button should be tappable
      await tester.tap(loginButton);
      await tester.pump();
    });
  });
}
