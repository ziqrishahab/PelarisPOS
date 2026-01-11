import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:pelaris/providers/providers.dart';

import '../test/helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Cart Flow Integration Tests', () {
    late MockAuthService mockAuthService;
    late CartProvider cartProvider;
    late ProductProvider productProvider;

    setUp(() {
      mockAuthService = MockAuthService();
      mockAuthService.setMockUser(createMockUser(cabangId: 'cabang-1'));
      cartProvider = CartProvider(mockAuthService);
      productProvider = ProductProvider(mockAuthService);
    });

    testWidgets('add product to cart and checkout flow', (
      WidgetTester tester,
    ) async {
      // Create a test widget with providers
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(mockAuthService)..init(),
            ),
            ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
            ChangeNotifierProvider<ProductProvider>.value(
              value: productProvider,
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Column(
                    children: [
                      // Product list simulation
                      ElevatedButton(
                        key: const Key('add-product-btn'),
                        onPressed: () {
                          final product = createMockProduct();
                          final variant = product.variants.first;
                          context.read<CartProvider>().addFromVariant(
                            product,
                            variant,
                            'cabang-1',
                          );
                        },
                        child: const Text('Add Product'),
                      ),
                      // Cart display
                      Consumer<CartProvider>(
                        builder: (_, cart, __) {
                          return Column(
                            children: [
                              Text('Items: ${cart.itemCount}'),
                              Text('Total: ${cart.total}'),
                              if (!cart.isEmpty)
                                ElevatedButton(
                                  key: const Key('checkout-btn'),
                                  onPressed: () {
                                    // Checkout logic
                                  },
                                  child: const Text('Checkout'),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state - empty cart
      expect(find.text('Items: 0'), findsOneWidget);
      expect(find.text('Checkout'), findsNothing);

      // Add product
      await tester.tap(find.byKey(const Key('add-product-btn')));
      await tester.pumpAndSettle();

      // Cart should update
      expect(find.text('Items: 1'), findsOneWidget);
      expect(find.text('Checkout'), findsOneWidget);

      // Add same product again
      await tester.tap(find.byKey(const Key('add-product-btn')));
      await tester.pumpAndSettle();

      // Quantity should increase, item count stays 1
      expect(find.text('Items: 1'), findsOneWidget);
      expect(cartProvider.totalQuantity, 2);
    });

    testWidgets('modify cart quantities', (WidgetTester tester) async {
      // Pre-populate cart
      cartProvider.addItem(createMockCartItem(maxStock: 10));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Consumer<CartProvider>(
                    builder: (_, cart, __) {
                      if (cart.isEmpty) {
                        return const Text('Cart is empty');
                      }
                      final item = cart.items.first;
                      return Column(
                        children: [
                          Text('Qty: ${item.quantity}'),
                          Row(
                            children: [
                              IconButton(
                                key: const Key('decrement-btn'),
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  cart.decrementQuantity(item.productVariantId);
                                },
                              ),
                              IconButton(
                                key: const Key('increment-btn'),
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  cart.incrementQuantity(item.productVariantId);
                                },
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial quantity
      expect(find.text('Qty: 1'), findsOneWidget);

      // Increment
      await tester.tap(find.byKey(const Key('increment-btn')));
      await tester.pumpAndSettle();
      expect(find.text('Qty: 2'), findsOneWidget);

      // Increment again
      await tester.tap(find.byKey(const Key('increment-btn')));
      await tester.pumpAndSettle();
      expect(find.text('Qty: 3'), findsOneWidget);

      // Decrement
      await tester.tap(find.byKey(const Key('decrement-btn')));
      await tester.pumpAndSettle();
      expect(find.text('Qty: 2'), findsOneWidget);
    });

    testWidgets('remove item from cart', (WidgetTester tester) async {
      // Pre-populate cart
      cartProvider.addItem(createMockCartItem());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Consumer<CartProvider>(
                    builder: (_, cart, __) {
                      if (cart.isEmpty) {
                        return const Text('Cart is empty');
                      }
                      final item = cart.items.first;
                      return Column(
                        children: [
                          Text(item.productName),
                          IconButton(
                            key: const Key('remove-btn'),
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              cart.removeItem(item.productVariantId);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Item should be visible
      expect(find.text('Baju SD'), findsOneWidget);
      expect(find.text('Cart is empty'), findsNothing);

      // Remove item
      await tester.tap(find.byKey(const Key('remove-btn')));
      await tester.pumpAndSettle();

      // Cart should be empty
      expect(find.text('Cart is empty'), findsOneWidget);
      expect(find.text('Baju SD'), findsNothing);
    });

    testWidgets('clear entire cart', (WidgetTester tester) async {
      // Pre-populate cart with multiple items
      cartProvider.addItem(createMockCartItem(productVariantId: 'var-1'));
      cartProvider.addItem(createMockCartItem(productVariantId: 'var-2'));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Consumer<CartProvider>(
                    builder: (_, cart, __) {
                      return Column(
                        children: [
                          Text('Items: ${cart.itemCount}'),
                          if (!cart.isEmpty)
                            ElevatedButton(
                              key: const Key('clear-btn'),
                              onPressed: cart.clearCart,
                              child: const Text('Clear Cart'),
                            ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should have 2 items
      expect(find.text('Items: 2'), findsOneWidget);

      // Clear cart
      await tester.tap(find.byKey(const Key('clear-btn')));
      await tester.pumpAndSettle();

      // Should be empty
      expect(find.text('Items: 0'), findsOneWidget);
      expect(find.text('Clear Cart'), findsNothing);
    });
  });

  group('Cart Calculations Integration Tests', () {
    late MockAuthService mockAuthService;
    late CartProvider cartProvider;

    setUp(() {
      mockAuthService = MockAuthService();
      mockAuthService.setMockUser(createMockUser());
      cartProvider = CartProvider(mockAuthService);
    });

    testWidgets('calculates subtotal correctly', (WidgetTester tester) async {
      // Add items
      cartProvider.addItem(
        createMockCartItem(
          productVariantId: 'var-1',
          price: 100000,
          maxStock: 10,
        ),
      );
      cartProvider.updateQuantity('var-1', 2);

      cartProvider.addItem(
        createMockCartItem(
          productVariantId: 'var-2',
          price: 50000,
          maxStock: 10,
        ),
      );
      cartProvider.updateQuantity('var-2', 3);

      await tester.pumpWidget(
        ChangeNotifierProvider<CartProvider>.value(
          value: cartProvider,
          child: MaterialApp(
            home: Consumer<CartProvider>(
              builder: (_, cart, __) {
                return Text('Subtotal: ${cart.subtotal}');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 100000 * 2 + 50000 * 3 = 350000
      expect(find.text('Subtotal: 350000.0'), findsOneWidget);
    });

    testWidgets('applies discount correctly', (WidgetTester tester) async {
      cartProvider.addItem(createMockCartItem(price: 200000));
      cartProvider.setDiscount(20000);

      await tester.pumpWidget(
        ChangeNotifierProvider<CartProvider>.value(
          value: cartProvider,
          child: MaterialApp(
            home: Consumer<CartProvider>(
              builder: (_, cart, __) {
                return Column(
                  children: [
                    Text('Subtotal: ${cart.subtotal}'),
                    Text('Discount: ${cart.discount}'),
                    Text('Total: ${cart.total}'),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Subtotal: 200000.0'), findsOneWidget);
      expect(find.text('Discount: 20000.0'), findsOneWidget);
      expect(find.text('Total: 180000.0'), findsOneWidget);
    });
  });
}
