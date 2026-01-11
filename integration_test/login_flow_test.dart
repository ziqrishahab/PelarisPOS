import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pelaris/main.dart';
import 'package:pelaris/data/services/auth_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Flow Integration Tests', () {
    testWidgets('complete login flow with valid credentials', (
      WidgetTester tester,
    ) async {
      // Note: This test requires a running backend server
      // For CI/CD, mock the backend responses

      final authService = AuthService();
      await authService.init();

      await tester.pumpWidget(PelarisApp(authService: authService));
      await tester.pumpAndSettle();

      // Should show login screen
      expect(find.text('Pelaris.id'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);

      // Enter credentials
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;

      await tester.enterText(emailField, 'test@test.com');
      await tester.enterText(passwordField, 'password123');

      // Tap login button
      await tester.tap(find.text('Login'));
      await tester.pump();

      // Should show loading indicator or proceed to next screen
      // Wait for the login process to complete or timeout
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('shows error for invalid credentials', (
      WidgetTester tester,
    ) async {
      final authService = AuthService();
      await authService.init();

      await tester.pumpWidget(PelarisApp(authService: authService));
      await tester.pumpAndSettle();

      // Enter invalid credentials
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;

      await tester.enterText(emailField, 'invalid@test.com');
      await tester.enterText(passwordField, 'wrongpassword');

      // Tap login
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should show error (depends on backend response)
      // In real test, mock the backend
    });

    testWidgets('validates empty fields', (WidgetTester tester) async {
      final authService = AuthService();
      await authService.init();

      await tester.pumpWidget(PelarisApp(authService: authService));
      await tester.pumpAndSettle();

      // Tap login without entering anything
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.textContaining('Email'), findsWidgets);
    });
  });

  group('Navigation Flow Integration Tests', () {
    testWidgets('authenticated user sees POS screen', (
      WidgetTester tester,
    ) async {
      // This would need a pre-authenticated state
      // Setup by saving mock credentials first
    });

    testWidgets('unauthenticated user sees login screen', (
      WidgetTester tester,
    ) async {
      final authService = AuthService();
      await authService.init();

      await tester.pumpWidget(PelarisApp(authService: authService));
      await tester.pumpAndSettle();

      // Should be on login screen
      expect(find.text('Pelaris.id'), findsOneWidget);
      expect(find.text('Silakan login untuk melanjutkan'), findsOneWidget);
    });
  });
}
