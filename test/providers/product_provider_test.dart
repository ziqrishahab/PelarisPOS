import 'package:flutter_test/flutter_test.dart';
import 'package:pelaris/data/models/models.dart';
import 'package:pelaris/data/models/product_model.dart';
import 'package:pelaris/providers/product_provider.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ProductProvider Unit Tests', () {
    late ProductProvider productProvider;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockAuthService.setMockUser(createMockUser());
      productProvider = ProductProvider(mockAuthService);
    });

    test('initial state is correct', () {
      expect(productProvider.products, isEmpty);
      expect(productProvider.categories, isEmpty);
      expect(productProvider.selectedCategoryId, isNull);
      expect(productProvider.searchQuery, isEmpty);
      expect(productProvider.isLoading, isFalse);
    });

    test('setCategory updates selectedCategoryId', () {
      productProvider.setCategory('cat-1');
      expect(productProvider.selectedCategoryId, 'cat-1');
    });

    test('setCategory with null clears selection', () {
      productProvider.setCategory('cat-1');
      productProvider.setCategory(null);
      expect(productProvider.selectedCategoryId, isNull);
    });

    test('setSearchQuery updates search query', () {
      productProvider.setSearchQuery('baju');
      expect(productProvider.searchQuery, 'baju');
    });

    test('clearFilters resets category and search', () {
      productProvider.setCategory('cat-1');
      productProvider.setSearchQuery('baju');

      productProvider.clearFilters();

      expect(productProvider.selectedCategoryId, isNull);
      expect(productProvider.searchQuery, isEmpty);
    });
  });

  group('Product Model Tests', () {
    test('fromJson creates product correctly', () {
      final json = {
        'id': 'prod-1',
        'name': 'Baju SD',
        'description': 'Baju seragam SD',
        'categoryId': 'cat-1',
        'category': {'id': 'cat-1', 'name': 'Seragam'},
        'productType': 'VARIANT',
        'isActive': true,
        'variants': [
          {
            'id': 'var-1',
            'productId': 'prod-1',
            'variantName': 'Ukuran',
            'variantValue': 'M',
            'sku': 'BAJU-SD-M',
            'stocks': [],
          },
        ],
      };

      final product = Product.fromJson(json);

      expect(product.id, 'prod-1');
      expect(product.name, 'Baju SD');
      expect(product.categoryId, 'cat-1');
      expect(product.variants.length, 1);
      expect(product.isActive, isTrue);
    });

    test('copyWith creates new product with updated variants', () {
      final original = createMockProduct();
      final newVariants = [
        createMockVariant(id: 'var-new', variantValue: 'XL'),
      ];

      final copied = original.copyWith(variants: newVariants);

      expect(copied.variants.length, 1);
      expect(copied.variants.first.id, 'var-new');
      expect(original.variants.first.id, isNot('var-new'));
    });

    test('toJson serializes correctly', () {
      final product = createMockProduct();
      final json = product.toJson();

      expect(json['id'], product.id);
      expect(json['name'], product.name);
      expect(json['isActive'], isTrue);
    });
  });

  group('ProductVariant Model Tests', () {
    test('fromJson creates variant correctly', () {
      final json = {
        'id': 'var-1',
        'productId': 'prod-1',
        'variantName': 'Ukuran',
        'variantValue': 'L',
        'sku': 'SKU-001',
        'stocks': [
          {
            'id': 'stock-1',
            'productVariantId': 'var-1',
            'cabangId': 'cab-1',
            'quantity': 50,
            'price': 100000,
          },
        ],
      };

      final variant = ProductVariant.fromJson(json);

      expect(variant.id, 'var-1');
      expect(variant.variantValue, 'L');
      expect(variant.sku, 'SKU-001');
      expect(variant.stocks.length, 1);
    });

    test('getPrice returns correct price for cabang', () {
      final variant = createMockVariant(
        stocks: [
          createMockStock(cabangId: 'cab-1', price: 100000),
          createMockStock(cabangId: 'cab-2', price: 120000),
        ],
      );

      expect(variant.getPrice('cab-1'), 100000);
      expect(variant.getPrice('cab-2'), 120000);
    });

    test('getPrice returns 0 for unknown cabang', () {
      final variant = createMockVariant(
        stocks: [createMockStock(cabangId: 'cab-1', price: 100000)],
      );

      expect(variant.getPrice('unknown-cabang'), 0);
    });

    test('getQuantity returns correct quantity for cabang', () {
      final variant = createMockVariant(
        stocks: [
          createMockStock(cabangId: 'cab-1', quantity: 50),
          createMockStock(cabangId: 'cab-2', quantity: 30),
        ],
      );

      expect(variant.getQuantity('cab-1'), 50);
      expect(variant.getQuantity('cab-2'), 30);
    });

    test('getQuantity returns 0 for unknown cabang', () {
      final variant = createMockVariant(
        stocks: [createMockStock(cabangId: 'cab-1', quantity: 50)],
      );

      expect(variant.getQuantity('unknown-cabang'), 0);
    });

    test('displayName includes product name when available', () {
      final product = createMockProduct(name: 'Baju SD');
      final variant = ProductVariant(
        id: 'var-1',
        productId: product.id,
        variantName: 'Ukuran',
        variantValue: 'M',
        sku: 'SKU-001',
        product: product,
      );

      expect(variant.displayName, 'Baju SD - M');
    });

    test('displayName returns variantValue when no product', () {
      final variant = ProductVariant(
        id: 'var-1',
        productId: 'prod-1',
        variantName: 'Ukuran',
        variantValue: 'M',
        sku: 'SKU-001',
      );

      expect(variant.displayName, 'M');
    });
  });

  group('Category Model Tests', () {
    test('fromJson creates category correctly', () {
      final json = {
        'id': 'cat-1',
        'name': 'Seragam',
        'description': 'Kategori seragam sekolah',
        '_count': {'products': 15},
      };

      final category = Category.fromJson(json);

      expect(category.id, 'cat-1');
      expect(category.name, 'Seragam');
      expect(category.description, 'Kategori seragam sekolah');
      expect(category.productCount, 15);
    });

    test('toJson serializes correctly', () {
      final category = createMockCategory();
      final json = category.toJson();

      expect(json['id'], category.id);
      expect(json['name'], category.name);
    });

    test('handles missing _count field', () {
      final json = {'id': 'cat-1', 'name': 'Seragam'};

      final category = Category.fromJson(json);
      expect(category.productCount, 0);
    });
  });

  group('Stock Model Tests', () {
    test('fromJson creates stock correctly', () {
      final json = {
        'id': 'stock-1',
        'productVariantId': 'var-1',
        'cabangId': 'cab-1',
        'quantity': 100,
        'price': 150000.0,
      };

      final stock = Stock.fromJson(json);

      expect(stock.id, 'stock-1');
      expect(stock.productVariantId, 'var-1');
      expect(stock.cabangId, 'cab-1');
      expect(stock.quantity, 100);
      expect(stock.price, 150000);
    });

    test('toJson serializes correctly', () {
      final stock = createMockStock();
      final json = stock.toJson();

      expect(json['id'], stock.id);
      expect(json['quantity'], stock.quantity);
      expect(json['price'], stock.price);
    });

    test('handles integer price conversion', () {
      final json = {
        'id': 'stock-1',
        'productVariantId': 'var-1',
        'cabangId': 'cab-1',
        'quantity': 100,
        'price': 150000, // integer instead of double
      };

      final stock = Stock.fromJson(json);
      expect(stock.price, 150000.0);
    });
  });
}
