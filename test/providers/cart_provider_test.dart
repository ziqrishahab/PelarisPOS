import 'package:flutter_test/flutter_test.dart';
import 'package:pelaris/data/models/models.dart';
import 'package:pelaris/providers/cart_provider.dart';
import 'package:pelaris/core/utils/currency_formatter.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('CartProvider Unit Tests', () {
    late CartProvider cartProvider;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockAuthService.setMockUser(createMockUser());
      cartProvider = CartProvider(mockAuthService);
    });

    test('initial state is empty', () {
      expect(cartProvider.isEmpty, isTrue);
      expect(cartProvider.items, isEmpty);
      expect(cartProvider.itemCount, 0);
      expect(cartProvider.totalQuantity, 0);
      expect(cartProvider.subtotal, 0);
      expect(cartProvider.total, 0);
    });

    test('addItem adds new item to cart', () {
      final cartItem = createMockCartItem();
      cartProvider.addItem(cartItem);

      expect(cartProvider.isEmpty, isFalse);
      expect(cartProvider.itemCount, 1);
      expect(
        cartProvider.items.first.productVariantId,
        cartItem.productVariantId,
      );
    });

    test('addItem increments quantity for existing item', () {
      final cartItem = createMockCartItem(quantity: 1, maxStock: 10);

      cartProvider.addItem(cartItem);
      expect(cartProvider.items.first.quantity, 1);

      // Add same item again
      cartProvider.addItem(cartItem);
      expect(cartProvider.items.first.quantity, 2);
      expect(cartProvider.itemCount, 1); // Still 1 item type
    });

    test('addItem respects max stock limit', () {
      final cartItem = createMockCartItem(quantity: 1, maxStock: 2);

      cartProvider.addItem(cartItem);
      cartProvider.addItem(cartItem);
      cartProvider.addItem(cartItem); // Should not increase beyond maxStock

      expect(cartProvider.items.first.quantity, 2);
    });

    test('removeItem removes item from cart', () {
      final cartItem = createMockCartItem();
      cartProvider.addItem(cartItem);

      expect(cartProvider.isEmpty, isFalse);

      cartProvider.removeItem(cartItem.productVariantId);

      expect(cartProvider.isEmpty, isTrue);
    });

    test('updateQuantity updates item quantity', () {
      final cartItem = createMockCartItem(maxStock: 10);
      cartProvider.addItem(cartItem);

      cartProvider.updateQuantity(cartItem.productVariantId, 5);

      expect(cartProvider.items.first.quantity, 5);
    });

    test('updateQuantity removes item when quantity is 0', () {
      final cartItem = createMockCartItem();
      cartProvider.addItem(cartItem);

      cartProvider.updateQuantity(cartItem.productVariantId, 0);

      expect(cartProvider.isEmpty, isTrue);
    });

    test('updateQuantity respects max stock', () {
      final cartItem = createMockCartItem(maxStock: 5);
      cartProvider.addItem(cartItem);

      cartProvider.updateQuantity(cartItem.productVariantId, 10);

      // Should remain at previous quantity since 10 > maxStock
      expect(cartProvider.items.first.quantity, 1);
    });

    test('incrementQuantity increases quantity by 1', () {
      final cartItem = createMockCartItem(maxStock: 10);
      cartProvider.addItem(cartItem);

      cartProvider.incrementQuantity(cartItem.productVariantId);

      expect(cartProvider.items.first.quantity, 2);
    });

    test('decrementQuantity decreases quantity by 1', () {
      final cartItem = createMockCartItem(quantity: 3, maxStock: 10);
      cartProvider.addItem(cartItem);
      // Reset quantity to 3 since addItem uses copyWith
      cartProvider.updateQuantity(cartItem.productVariantId, 3);

      cartProvider.decrementQuantity(cartItem.productVariantId);

      expect(cartProvider.items.first.quantity, 2);
    });

    test('decrementQuantity removes item when quantity becomes 0', () {
      final cartItem = createMockCartItem();
      cartProvider.addItem(cartItem);

      cartProvider.decrementQuantity(cartItem.productVariantId);

      expect(cartProvider.isEmpty, isTrue);
    });

    test('subtotal calculates correctly', () {
      cartProvider.addItem(
        createMockCartItem(
          productVariantId: 'var-1',
          price: 100000,
          quantity: 2,
          maxStock: 10,
        ),
      );
      cartProvider.updateQuantity('var-1', 2);

      cartProvider.addItem(
        createMockCartItem(
          productVariantId: 'var-2',
          price: 50000,
          quantity: 3,
          maxStock: 10,
        ),
      );
      cartProvider.updateQuantity('var-2', 3);

      // 100000 * 2 + 50000 * 3 = 350000
      expect(cartProvider.subtotal, 350000);
    });

    test('total includes discount', () {
      cartProvider.addItem(createMockCartItem(price: 100000));
      cartProvider.setDiscount(10000);

      expect(cartProvider.total, 90000);
    });

    test('setDiscount updates discount', () {
      cartProvider.setDiscount(5000);
      expect(cartProvider.discount, 5000);
    });

    test('clearCart removes all items', () {
      cartProvider.addItem(createMockCartItem(productVariantId: 'var-1'));
      cartProvider.addItem(createMockCartItem(productVariantId: 'var-2'));
      cartProvider.setDiscount(1000);

      cartProvider.clearCart();

      expect(cartProvider.isEmpty, isTrue);
      expect(cartProvider.discount, 0);
    });

    test('totalQuantity counts all items', () {
      cartProvider.addItem(
        createMockCartItem(productVariantId: 'var-1', maxStock: 10),
      );
      cartProvider.updateQuantity('var-1', 3);

      cartProvider.addItem(
        createMockCartItem(productVariantId: 'var-2', maxStock: 10),
      );
      cartProvider.updateQuantity('var-2', 2);

      expect(cartProvider.totalQuantity, 5);
    });
  });

  group('CartItem Model Tests', () {
    test('subtotal calculates correctly', () {
      final cartItem = CartItem(
        productVariantId: 'var-1',
        productId: 'prod-1',
        productName: 'Test Product',
        variantName: 'Size',
        variantValue: 'M',
        price: 50000,
        quantity: 3,
        maxStock: 10,
      );

      expect(cartItem.subtotal, 150000);
    });

    test('displayName formats correctly', () {
      final cartItem = createMockCartItem(
        productName: 'Baju SD',
        variantValue: 'L',
      );

      expect(cartItem.displayName, 'Baju SD - L');
    });

    test('variantInfo formats correctly', () {
      final cartItem = createMockCartItem(
        variantName: 'Ukuran',
        variantValue: 'XL',
      );

      expect(cartItem.variantInfo, 'Ukuran: XL');
    });

    test('copyWith creates new instance with updated values', () {
      final original = createMockCartItem(quantity: 1);
      final copied = original.copyWith(quantity: 5);

      expect(copied.quantity, 5);
      expect(original.quantity, 1);
      expect(copied.productVariantId, original.productVariantId);
    });

    test('toTransactionItem returns correct format', () {
      final cartItem = createMockCartItem(
        productVariantId: 'var-123',
        price: 75000,
        quantity: 2,
      );

      final transactionItem = cartItem.toTransactionItem();

      expect(transactionItem['productVariantId'], 'var-123');
      expect(transactionItem['quantity'], 2);
      expect(transactionItem['price'], 75000);
    });
  });

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

    test('formats very large number correctly', () {
      expect(CurrencyFormatter.format(10000000000), 'Rp 10.000.000.000');
    });
  });
}
