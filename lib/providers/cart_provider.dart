import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/services/auth_service.dart';
import '../data/api/api_client.dart';

class CartProvider extends ChangeNotifier {
  final AuthService _authService;
  late final TransactionRepository _transactionRepository;

  List<CartItem> _items = [];
  double _discount = 0;
  double _tax = 0;
  String? _customerName;
  String? _customerPhone;
  String? _notes;
  bool _isProcessing = false;
  String? _errorMessage;
  Transaction? _lastTransaction;

  CartProvider(this._authService) {
    final apiClient = ApiClient.getInstance(_authService);
    _transactionRepository = TransactionRepository(apiClient);
  }

  // Getters
  List<CartItem> get items => _items;
  double get discount => _discount;
  double get tax => _tax;
  String? get customerName => _customerName;
  String? get customerPhone => _customerPhone;
  String? get notes => _notes;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  Transaction? get lastTransaction => _lastTransaction;
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.length;
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  // Calculate totals
  double get subtotal => _items.fold(0, (sum, item) => sum + item.subtotal);
  double get total => subtotal - _discount + _tax;

  // Add item to cart
  void addItem(CartItem item) {
    final existingIndex = _items.indexWhere(
      (i) => i.productVariantId == item.productVariantId,
    );

    if (existingIndex != -1) {
      // Update quantity if item exists
      final existing = _items[existingIndex];
      if (existing.quantity < existing.maxStock) {
        _items[existingIndex] = existing.copyWith(
          quantity: existing.quantity + 1,
        );
      }
    } else {
      // Add new item
      _items.add(item);
    }
    notifyListeners();
  }

  // Add item from product variant
  void addFromVariant(
    Product product,
    ProductVariant variant,
    String cabangId,
  ) {
    final price = variant.getPrice(cabangId);
    final stock = variant.getQuantity(cabangId);

    if (stock <= 0) {
      _errorMessage = 'Stok habis';
      notifyListeners();
      return;
    }

    final cartItem = CartItem(
      productVariantId: variant.id,
      productId: product.id,
      productName: product.name,
      variantName: variant.variantName,
      variantValue: variant.variantValue,
      sku: variant.sku,
      price: price,
      quantity: 1,
      maxStock: stock,
    );

    addItem(cartItem);
  }

  // Remove item from cart
  void removeItem(String productVariantId) {
    _items.removeWhere((i) => i.productVariantId == productVariantId);
    notifyListeners();
  }

  // Update item quantity
  void updateQuantity(String productVariantId, int quantity) {
    final index = _items.indexWhere(
      (i) => i.productVariantId == productVariantId,
    );

    if (index != -1) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else if (quantity <= _items[index].maxStock) {
        _items[index] = _items[index].copyWith(quantity: quantity);
      }
      notifyListeners();
    }
  }

  // Increment quantity
  void incrementQuantity(String productVariantId) {
    final index = _items.indexWhere(
      (i) => i.productVariantId == productVariantId,
    );

    if (index != -1) {
      final item = _items[index];
      if (item.quantity < item.maxStock) {
        _items[index] = item.copyWith(quantity: item.quantity + 1);
        notifyListeners();
      }
    }
  }

  // Decrement quantity
  void decrementQuantity(String productVariantId) {
    final index = _items.indexWhere(
      (i) => i.productVariantId == productVariantId,
    );

    if (index != -1) {
      final item = _items[index];
      if (item.quantity > 1) {
        _items[index] = item.copyWith(quantity: item.quantity - 1);
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  // Set discount
  void setDiscount(double value) {
    _discount = value;
    notifyListeners();
  }

  // Set tax
  void setTax(double value) {
    _tax = value;
    notifyListeners();
  }

  // Set customer info
  void setCustomerInfo({String? name, String? phone}) {
    _customerName = name;
    _customerPhone = phone;
    notifyListeners();
  }

  // Set notes
  void setNotes(String? value) {
    _notes = value;
    notifyListeners();
  }

  // Clear cart
  void clearCart() {
    _items = [];
    _discount = 0;
    _tax = 0;
    _customerName = null;
    _customerPhone = null;
    _notes = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Process transaction
  Future<Transaction?> checkout({
    required String cabangId,
    required String paymentMethod,
    String? bankName,
    String? referenceNo,
    String? cardLastDigits,
    bool isSplitPayment = false,
    double? paymentAmount1,
    String? paymentMethod2,
    double? paymentAmount2,
    String? bankName2,
    String? referenceNo2,
  }) async {
    if (_items.isEmpty) {
      _errorMessage = 'Keranjang kosong';
      notifyListeners();
      return null;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final transaction = await _transactionRepository.createTransaction(
        cabangId: cabangId,
        items: _items,
        paymentMethod: paymentMethod,
        customerName: _customerName,
        customerPhone: _customerPhone,
        discount: _discount,
        tax: _tax,
        bankName: bankName,
        referenceNo: referenceNo,
        cardLastDigits: cardLastDigits,
        isSplitPayment: isSplitPayment,
        paymentAmount1: paymentAmount1,
        paymentMethod2: paymentMethod2,
        paymentAmount2: paymentAmount2,
        bankName2: bankName2,
        referenceNo2: referenceNo2,
        notes: _notes,
      );

      _lastTransaction = transaction;
      clearCart();
      return transaction;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
