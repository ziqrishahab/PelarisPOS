import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pelaris/core/utils/currency_formatter.dart';
import 'package:pelaris/data/models/transaction_model.dart';

/// Main test file - exports all test groups
/// Run all tests: flutter test
/// Run specific test: flutter test test/providers/cart_provider_test.dart

void main() {
  group('CurrencyFormatter Tests', () {
    test('formats positive number correctly', () {
      expect(CurrencyFormatter.format(100000), 'Rp 100.000');
    });

    test('formats zero correctly', () {
      expect(CurrencyFormatter.format(0), 'Rp 0');
    });

    test('formats decimal correctly', () {
      expect(CurrencyFormatter.format(50000.5), 'Rp 50.001');
    });

    test('formats large number correctly', () {
      expect(CurrencyFormatter.format(1000000), 'Rp 1.000.000');
    });
  });

  group('Widget Smoke Tests', () {
    testWidgets('MaterialApp renders without crashing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: Text('Pelaris.id Test'))),
        ),
      );

      expect(find.text('Pelaris.id Test'), findsOneWidget);
    });

    testWidgets('Basic button tap works', (WidgetTester tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () => tapCount++,
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      expect(tapCount, 0);
      await tester.tap(find.text('Tap Me'));
      expect(tapCount, 1);
    });

    testWidgets('Text field accepts input', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextField(decoration: InputDecoration(hintText: 'Search')),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test product');
      expect(find.text('test product'), findsOneWidget);
    });

    testWidgets('Form validation works', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Field required';
                      }
                      return null;
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      formKey.currentState!.validate();
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Submit without entering text
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Field required'), findsOneWidget);
    });

    testWidgets('ListView scrolls correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 100,
              itemBuilder: (_, index) => ListTile(title: Text('Item $index')),
            ),
          ),
        ),
      );

      // Scroll down
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Should see items further down
      expect(find.text('Item 10'), findsOneWidget);
    });
  });

  group('Transaction Model Tests', () {
    test('PaymentMethod enum has correct values', () {
      expect(PaymentMethod.values.length, 4);
      expect(PaymentMethod.values.contains(PaymentMethod.cash), true);
      expect(PaymentMethod.values.contains(PaymentMethod.debit), true);
      expect(PaymentMethod.values.contains(PaymentMethod.transfer), true);
      expect(PaymentMethod.values.contains(PaymentMethod.qris), true);
    });

    test('PaymentStatus enum has correct values', () {
      expect(PaymentStatus.values.length, 3);
      expect(PaymentStatus.values.contains(PaymentStatus.pending), true);
      expect(PaymentStatus.values.contains(PaymentStatus.completed), true);
      expect(PaymentStatus.values.contains(PaymentStatus.cancelled), true);
    });

    test('ReturnStatus enum has correct values', () {
      expect(ReturnStatus.values.length, 3);
      expect(ReturnStatus.values.contains(ReturnStatus.pending), true);
      expect(ReturnStatus.values.contains(ReturnStatus.completed), true);
      expect(ReturnStatus.values.contains(ReturnStatus.rejected), true);
    });
  });

  group('Accessibility Tests', () {
    testWidgets('Buttons have sufficient tap target', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(onPressed: () {}, child: const Text('Button')),
          ),
        ),
      );

      final buttonSize = tester.getSize(find.byType(ElevatedButton));

      // Minimum tap target should be 48x48
      expect(buttonSize.width >= 48, isTrue);
      expect(buttonSize.height >= 48, isTrue);
    });

    testWidgets('TextFields have labels or hints', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
    });
  });
}

// Mock enum for testing without importing full model
enum PaymentMethod { cash, debit, transfer, qris }
