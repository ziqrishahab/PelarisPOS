import 'package:flutter_test/flutter_test.dart';
import 'package:pelaris/data/models/transaction_model.dart';

void main() {
  group('Transaction Model Tests', () {
    test('fromJson creates transaction correctly', () {
      final json = {
        'id': 'trx-1',
        'transactionNo': 'TRX-001',
        'cabangId': 'cab-1',
        'kasirId': 'kasir-1',
        'customerName': 'John Doe',
        'customerPhone': '08123456789',
        'subtotal': 200000,
        'discount': 10000,
        'tax': 0,
        'total': 190000,
        'paymentMethod': 'CASH',
        'paymentStatus': 'COMPLETED',
        'createdAt': '2024-01-01T10:00:00.000Z',
        'items': [
          {
            'id': 'item-1',
            'transactionId': 'trx-1',
            'productVariantId': 'var-1',
            'productName': 'Baju SD',
            'variantInfo': 'Ukuran: M',
            'quantity': 2,
            'price': 100000,
            'subtotal': 200000,
          },
        ],
      };

      final transaction = Transaction.fromJson(json);

      expect(transaction.id, 'trx-1');
      expect(transaction.transactionNo, 'TRX-001');
      expect(transaction.total, 190000);
      expect(transaction.paymentMethod, PaymentMethod.cash);
      expect(transaction.paymentStatus, PaymentStatus.completed);
      expect(transaction.items.length, 1);
    });

    test('parses all payment methods correctly', () {
      expect(
        Transaction.fromJson({
          'paymentMethod': 'CASH',
          'createdAt': '2024-01-01T10:00:00.000Z',
        }).paymentMethod,
        PaymentMethod.cash,
      );
      expect(
        Transaction.fromJson({
          'paymentMethod': 'DEBIT',
          'createdAt': '2024-01-01T10:00:00.000Z',
        }).paymentMethod,
        PaymentMethod.debit,
      );
      expect(
        Transaction.fromJson({
          'paymentMethod': 'TRANSFER',
          'createdAt': '2024-01-01T10:00:00.000Z',
        }).paymentMethod,
        PaymentMethod.transfer,
      );
      expect(
        Transaction.fromJson({
          'paymentMethod': 'QRIS',
          'createdAt': '2024-01-01T10:00:00.000Z',
        }).paymentMethod,
        PaymentMethod.qris,
      );
    });

    test('parses all payment statuses correctly', () {
      expect(
        Transaction.fromJson({
          'paymentStatus': 'PENDING',
          'createdAt': '2024-01-01T10:00:00.000Z',
        }).paymentStatus,
        PaymentStatus.pending,
      );
      expect(
        Transaction.fromJson({
          'paymentStatus': 'COMPLETED',
          'createdAt': '2024-01-01T10:00:00.000Z',
        }).paymentStatus,
        PaymentStatus.completed,
      );
      expect(
        Transaction.fromJson({
          'paymentStatus': 'CANCELLED',
          'createdAt': '2024-01-01T10:00:00.000Z',
        }).paymentStatus,
        PaymentStatus.cancelled,
      );
    });

    test('handles split payment fields', () {
      final json = {
        'id': 'trx-1',
        'isSplitPayment': true,
        'paymentMethod': 'CASH',
        'paymentAmount1': 100000,
        'paymentMethod2': 'QRIS',
        'paymentAmount2': 50000,
        'createdAt': '2024-01-01T10:00:00.000Z',
      };

      final transaction = Transaction.fromJson(json);

      expect(transaction.isSplitPayment, isTrue);
      expect(transaction.paymentAmount1, 100000);
      expect(transaction.paymentMethod2, PaymentMethod.qris);
      expect(transaction.paymentAmount2, 50000);
    });

    test('handles return status', () {
      expect(
        Transaction.fromJson({
          'returnStatus': 'PENDING',
          'createdAt': '2024-01-01T10:00:00.000Z',
        }).returnStatus,
        ReturnStatus.pending,
      );
      expect(
        Transaction.fromJson({
          'returnStatus': 'COMPLETED',
          'createdAt': '2024-01-01T10:00:00.000Z',
        }).returnStatus,
        ReturnStatus.completed,
      );
      expect(
        Transaction.fromJson({
          'returnStatus': 'REJECTED',
          'createdAt': '2024-01-01T10:00:00.000Z',
        }).returnStatus,
        ReturnStatus.rejected,
      );
    });

    test('handles hasReturn field', () {
      final json = {'hasReturn': true, 'createdAt': '2024-01-01T10:00:00.000Z'};

      final transaction = Transaction.fromJson(json);
      expect(transaction.hasReturn, isTrue);
    });

    test('defaults to correct values for missing fields', () {
      final json = <String, dynamic>{'createdAt': '2024-01-01T10:00:00.000Z'};

      final transaction = Transaction.fromJson(json);

      expect(transaction.id, '');
      expect(transaction.discount, 0);
      expect(transaction.tax, 0);
      expect(transaction.isSplitPayment, isFalse);
      expect(transaction.hasReturn, isFalse);
      expect(transaction.paymentMethod, PaymentMethod.cash);
      expect(transaction.paymentStatus, PaymentStatus.completed);
    });
  });

  group('TransactionItem Model Tests', () {
    test('fromJson creates item correctly', () {
      final json = {
        'id': 'item-1',
        'transactionId': 'trx-1',
        'productVariantId': 'var-1',
        'productName': 'Baju SD',
        'variantInfo': 'Ukuran: M',
        'sku': 'SKU-001',
        'quantity': 3,
        'price': 50000,
        'subtotal': 150000,
      };

      final item = TransactionItem.fromJson(json);

      expect(item.id, 'item-1');
      expect(item.productName, 'Baju SD');
      expect(item.quantity, 3);
      expect(item.price, 50000);
      expect(item.subtotal, 150000);
    });

    test('toJson serializes correctly', () {
      final item = TransactionItem(
        id: 'item-1',
        transactionId: 'trx-1',
        productVariantId: 'var-1',
        productName: 'Baju SD',
        variantInfo: 'M',
        quantity: 2,
        price: 75000,
        subtotal: 150000,
      );

      final json = item.toJson();

      expect(json['productVariantId'], 'var-1');
      expect(json['quantity'], 2);
      expect(json['price'], 75000);
    });

    test('handles missing optional fields', () {
      final json = {
        'id': 'item-1',
        'transactionId': 'trx-1',
        'productVariantId': 'var-1',
        'productName': 'Product',
        'variantInfo': 'M',
        'quantity': 1,
        'price': 10000,
        'subtotal': 10000,
      };

      final item = TransactionItem.fromJson(json);
      expect(item.sku, isNull);
    });
  });

  group('PaymentMethod Enum Tests', () {
    test('has all expected values', () {
      expect(PaymentMethod.values.length, 4);
      expect(PaymentMethod.values, contains(PaymentMethod.cash));
      expect(PaymentMethod.values, contains(PaymentMethod.debit));
      expect(PaymentMethod.values, contains(PaymentMethod.transfer));
      expect(PaymentMethod.values, contains(PaymentMethod.qris));
    });
  });

  group('PaymentStatus Enum Tests', () {
    test('has all expected values', () {
      expect(PaymentStatus.values.length, 3);
      expect(PaymentStatus.values, contains(PaymentStatus.pending));
      expect(PaymentStatus.values, contains(PaymentStatus.completed));
      expect(PaymentStatus.values, contains(PaymentStatus.cancelled));
    });
  });

  group('ReturnStatus Enum Tests', () {
    test('has all expected values', () {
      expect(ReturnStatus.values.length, 3);
      expect(ReturnStatus.values, contains(ReturnStatus.pending));
      expect(ReturnStatus.values, contains(ReturnStatus.completed));
      expect(ReturnStatus.values, contains(ReturnStatus.rejected));
    });
  });
}
