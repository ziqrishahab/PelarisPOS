// Test helpers and mocks for Pelaris.id tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pelaris/data/models/models.dart';
import 'package:pelaris/providers/providers.dart';
import 'package:pelaris/data/services/auth_service.dart';

// ============================================
// MOCK DATA
// ============================================

/// Mock user untuk testing
User createMockUser({
  String id = 'user-1',
  String email = 'test@test.com',
  String name = 'Test User',
  String role = 'KASIR',
  String? cabangId = 'cabang-1',
  Cabang? cabang,
}) {
  return User(
    id: id,
    email: email,
    name: name,
    role: role,
    isActive: true,
    cabangId: cabangId,
    cabang: cabang ?? createMockCabang(id: cabangId ?? 'cabang-1'),
  );
}

/// Mock cabang untuk testing
Cabang createMockCabang({
  String id = 'cabang-1',
  String name = 'Cabang Utama',
  String? address = 'Jl. Test No. 1',
  String? phone = '08123456789',
}) {
  return Cabang(
    id: id,
    name: name,
    address: address,
    phone: phone,
    isActive: true,
  );
}

/// Mock category untuk testing
Category createMockCategory({
  String id = 'cat-1',
  String name = 'Seragam',
  String? description = 'Kategori Seragam',
  int productCount = 10,
}) {
  return Category(
    id: id,
    name: name,
    description: description,
    productCount: productCount,
  );
}

/// Mock product untuk testing
Product createMockProduct({
  String id = 'prod-1',
  String name = 'Baju SD',
  String categoryId = 'cat-1',
  Category? category,
  List<ProductVariant>? variants,
}) {
  return Product(
    id: id,
    name: name,
    categoryId: categoryId,
    category: category ?? createMockCategory(),
    isActive: true,
    variants: variants ?? [createMockVariant(productId: id)],
  );
}

/// Mock product variant untuk testing
ProductVariant createMockVariant({
  String id = 'var-1',
  String productId = 'prod-1',
  String variantName = 'Ukuran',
  String variantValue = 'M',
  String sku = 'BAJU-SD-M',
  List<Stock>? stocks,
}) {
  return ProductVariant(
    id: id,
    productId: productId,
    variantName: variantName,
    variantValue: variantValue,
    sku: sku,
    stocks: stocks ?? [createMockStock(variantId: id)],
  );
}

/// Mock stock untuk testing
Stock createMockStock({
  String id = 'stock-1',
  String variantId = 'var-1',
  String cabangId = 'cabang-1',
  int quantity = 100,
  double price = 150000,
}) {
  return Stock(
    id: id,
    productVariantId: variantId,
    cabangId: cabangId,
    quantity: quantity,
    price: price,
  );
}

/// Mock cart item untuk testing
CartItem createMockCartItem({
  String productVariantId = 'var-1',
  String productId = 'prod-1',
  String productName = 'Baju SD',
  String variantName = 'Ukuran',
  String variantValue = 'M',
  String sku = 'BAJU-SD-M',
  double price = 150000,
  int quantity = 1,
  int maxStock = 100,
}) {
  return CartItem(
    productVariantId: productVariantId,
    productId: productId,
    productName: productName,
    variantName: variantName,
    variantValue: variantValue,
    sku: sku,
    price: price,
    quantity: quantity,
    maxStock: maxStock,
  );
}

/// Mock transaction untuk testing
Transaction createMockTransaction({
  String id = 'trx-1',
  String transactionNo = 'TRX-001',
  String cabangId = 'cabang-1',
  double subtotal = 150000,
  double discount = 0,
  double total = 150000,
  PaymentMethod paymentMethod = PaymentMethod.cash,
  List<TransactionItem>? items,
}) {
  return Transaction(
    id: id,
    transactionNo: transactionNo,
    cabangId: cabangId,
    subtotal: subtotal,
    discount: discount,
    total: total,
    paymentMethod: paymentMethod,
    items: items ?? [],
    createdAt: DateTime.now(),
  );
}

// ============================================
// MOCK AUTH SERVICE
// ============================================

/// Mock AuthService untuk testing (tidak pakai secure storage)
class MockAuthService extends AuthService {
  User? _mockUser;
  String? _mockToken;
  bool _mockIsLoggedIn = false;

  @override
  User? get currentUser => _mockUser;

  @override
  Future<String?> getToken() async => _mockToken;

  @override
  bool get isLoggedIn => _mockIsLoggedIn;

  @override
  Future<void> init() async {
    // No-op for testing
  }

  @override
  Future<void> saveAuth(String token, User user) async {
    _mockToken = token;
    _mockUser = user;
    _mockIsLoggedIn = true;
  }

  @override
  Future<void> logout() async {
    _mockToken = null;
    _mockUser = null;
    _mockIsLoggedIn = false;
  }

  @override
  Future<void> updateUser(User user) async {
    _mockUser = user;
  }

  /// Helper untuk set user langsung (testing)
  void setMockUser(User? user) {
    _mockUser = user;
    _mockIsLoggedIn = user != null;
    _mockToken = user != null ? 'mock-token' : null;
  }
}

// ============================================
// TEST WRAPPER WIDGET
// ============================================

/// Wrapper untuk testing widget dengan providers
Widget createTestApp({
  required Widget child,
  MockAuthService? authService,
  AuthProvider? authProvider,
  ProductProvider? productProvider,
  CartProvider? cartProvider,
  ThemeData? theme,
}) {
  final mockAuthService = authService ?? MockAuthService();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => authProvider ?? AuthProvider(mockAuthService),
      ),
      ChangeNotifierProvider<ProductProvider>(
        create: (_) => productProvider ?? ProductProvider(mockAuthService),
      ),
      ChangeNotifierProvider<CartProvider>(
        create: (_) => cartProvider ?? CartProvider(mockAuthService),
      ),
    ],
    child: MaterialApp(
      home: child,
      theme: theme ?? ThemeData.light(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

/// Wrapper minimal (tanpa providers)
Widget createMinimalTestApp(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    home: child,
    theme: theme ?? ThemeData.light(),
    debugShowCheckedModeBanner: false,
  );
}

// ============================================
// TEST UTILITIES
// ============================================

/// Find widget by key
Finder findByKey(String key) => find.byKey(Key(key));

/// Find widget by text
Finder findByText(String text) => find.text(text);

/// Find widget by type (top level function)
Finder findWidgetByType<T extends Widget>() => find.byType(T);

// ============================================
// GOLDEN TEST HELPERS
// ============================================

/// Setup untuk golden tests dengan ukuran layar standar
Future<void> setUpGoldenTest(WidgetTester tester, {Size? size}) async {
  tester.view.physicalSize = size ?? const Size(1080, 1920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

// ============================================
// EXTENSION METHODS
// ============================================

extension WidgetTesterExtension on WidgetTester {
  /// Enter text ke TextField dengan key
  Future<void> enterTextByKey(String key, String text) async {
    await enterText(find.byKey(Key(key)), text);
    await pump();
  }

  /// Tap button dengan key
  Future<void> tapByKey(String key) async {
    await tap(find.byKey(Key(key)));
    await pumpAndSettle();
  }

  /// Tap button dengan text
  Future<void> tapByText(String text) async {
    await tap(find.text(text));
    await pumpAndSettle();
  }

  /// Verify text exists
  void expectText(String text) {
    expect(find.text(text), findsOneWidget);
  }

  /// Verify text not exists
  void expectNoText(String text) {
    expect(find.text(text), findsNothing);
  }

  /// Verify widget exists
  void expectWidget<T extends Widget>() {
    expect(find.byType(T), findsOneWidget);
  }

  /// Verify widget count
  void expectWidgetCount<T extends Widget>(int count) {
    expect(find.byType(T), findsNWidgets(count));
  }
}
