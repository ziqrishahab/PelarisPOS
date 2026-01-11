// Transaction model untuk POS
enum PaymentMethod { cash, debit, transfer, qris }

enum PaymentStatus { pending, completed, cancelled }

enum ReturnStatus { pending, completed, rejected }

class Transaction {
  final String id;
  final String transactionNo;
  final String cabangId;
  final String? kasirId;
  final String? customerName;
  final String? customerPhone;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final String? bankName;
  final String? referenceNo;
  final String? cardLastDigits;
  final bool isSplitPayment;
  final double? paymentAmount1;
  final PaymentMethod? paymentMethod2;
  final double? paymentAmount2;
  final String? bankName2;
  final String? referenceNo2;
  final String? notes;
  final List<TransactionItem> items;
  final DateTime createdAt;
  // Return info
  final ReturnStatus? returnStatus;
  final bool hasReturn;

  Transaction({
    required this.id,
    required this.transactionNo,
    required this.cabangId,
    this.kasirId,
    this.customerName,
    this.customerPhone,
    required this.subtotal,
    this.discount = 0,
    this.tax = 0,
    required this.total,
    required this.paymentMethod,
    this.paymentStatus = PaymentStatus.completed,
    this.bankName,
    this.referenceNo,
    this.cardLastDigits,
    this.isSplitPayment = false,
    this.paymentAmount1,
    this.paymentMethod2,
    this.paymentAmount2,
    this.bankName2,
    this.referenceNo2,
    this.notes,
    this.items = const [],
    required this.createdAt,
    this.returnStatus,
    this.hasReturn = false,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      transactionNo: json['transactionNo'] ?? '',
      cabangId: json['cabangId'] ?? '',
      kasirId: json['kasirId'],
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      paymentMethod: _parsePaymentMethod(json['paymentMethod']),
      paymentStatus: _parsePaymentStatus(json['paymentStatus']),
      bankName: json['bankName'],
      referenceNo: json['referenceNo'],
      cardLastDigits: json['cardLastDigits'],
      isSplitPayment: json['isSplitPayment'] ?? false,
      paymentAmount1: json['paymentAmount1']?.toDouble(),
      paymentMethod2: json['paymentMethod2'] != null
          ? _parsePaymentMethod(json['paymentMethod2'])
          : null,
      paymentAmount2: json['paymentAmount2']?.toDouble(),
      bankName2: json['bankName2'],
      referenceNo2: json['referenceNo2'],
      notes: json['notes'],
      items: json['items'] != null
          ? (json['items'] as List)
                .map((i) => TransactionItem.fromJson(i))
                .toList()
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt']).toLocal()
          : DateTime.now(),
      returnStatus: _parseReturnStatus(json['returnStatus']),
      hasReturn: json['hasReturn'] ?? false,
    );
  }

  static PaymentMethod _parsePaymentMethod(String? method) {
    switch (method) {
      case 'CASH':
        return PaymentMethod.cash;
      case 'DEBIT':
        return PaymentMethod.debit;
      case 'TRANSFER':
        return PaymentMethod.transfer;
      case 'QRIS':
        return PaymentMethod.qris;
      default:
        return PaymentMethod.cash;
    }
  }

  static PaymentStatus _parsePaymentStatus(String? status) {
    switch (status) {
      case 'PENDING':
        return PaymentStatus.pending;
      case 'COMPLETED':
        return PaymentStatus.completed;
      case 'CANCELLED':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.completed;
    }
  }

  static ReturnStatus? _parseReturnStatus(String? status) {
    switch (status) {
      case 'PENDING':
        return ReturnStatus.pending;
      case 'COMPLETED':
        return ReturnStatus.completed;
      case 'REJECTED':
        return ReturnStatus.rejected;
      default:
        return null;
    }
  }
}

// Transaction Item model
class TransactionItem {
  final String id;
  final String transactionId;
  final String productVariantId;
  final String productName;
  final String variantInfo;
  final String? sku;
  final int quantity;
  final double price;
  final double subtotal;

  TransactionItem({
    required this.id,
    required this.transactionId,
    required this.productVariantId,
    required this.productName,
    required this.variantInfo,
    this.sku,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] ?? '',
      transactionId: json['transactionId'] ?? '',
      productVariantId: json['productVariantId'] ?? '',
      productName: json['productName'] ?? '',
      variantInfo: json['variantInfo'] ?? '',
      sku: json['sku'],
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productVariantId': productVariantId,
      'quantity': quantity,
      'price': price,
    };
  }
}

// Cart Item - untuk keranjang belanja di POS
class CartItem {
  final String productVariantId;
  final String productId;
  final String productName;
  final String variantName;
  final String variantValue;
  final String? sku;
  final double price;
  int quantity;
  final int maxStock;

  CartItem({
    required this.productVariantId,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.variantValue,
    this.sku,
    required this.price,
    this.quantity = 1,
    required this.maxStock,
  });

  double get subtotal => price * quantity;

  String get displayName => '$productName - $variantValue';

  String get variantInfo => '$variantName: $variantValue';

  Map<String, dynamic> toTransactionItem() {
    return {
      'productVariantId': productVariantId,
      'quantity': quantity,
      'price': price,
    };
  }

  CartItem copyWith({
    String? productVariantId,
    String? productId,
    String? productName,
    String? variantName,
    String? variantValue,
    String? sku,
    double? price,
    int? quantity,
    int? maxStock,
  }) {
    return CartItem(
      productVariantId: productVariantId ?? this.productVariantId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      variantName: variantName ?? this.variantName,
      variantValue: variantValue ?? this.variantValue,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      maxStock: maxStock ?? this.maxStock,
    );
  }
}
