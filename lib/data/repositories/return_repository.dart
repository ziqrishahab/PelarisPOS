import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../api/api_client.dart';

class ReturnRepository {
  final ApiClient _apiClient;

  ReturnRepository(this._apiClient);

  /// Get returnable quantities for a transaction
  /// Returns items with original qty, returned qty, and remaining returnable qty
  Future<ReturnableResponse> getReturnableQuantities(
    String transactionId,
  ) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.returns}/transaction/$transactionId/returnable',
      );
      return ReturnableResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get app settings for return/exchange
  Future<ReturnSettings> getReturnSettings() async {
    try {
      final response = await _apiClient.get(ApiConstants.settingsApp);
      return ReturnSettings.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Create a return request
  Future<Map<String, dynamic>> createReturn({
    required String transactionId,
    required String cabangId,
    required String reason,
    required List<ReturnItem> items,
    String? reasonDetail,
    String? notes,
    String? conditionNote,
    String? refundMethod,
    List<String>? photoUrls,
    bool? managerOverride,
    List<ExchangeItem>? exchangeItems,
  }) async {
    try {
      final data = {
        'transactionId': transactionId,
        'cabangId': cabangId,
        'reason': reason,
        'items': items.map((item) => item.toJson()).toList(),
      };

      // Optional fields
      if (reasonDetail != null && reasonDetail.isNotEmpty) {
        data['reasonDetail'] = reasonDetail;
      }
      if (notes != null && notes.isNotEmpty) {
        data['notes'] = notes;
      }
      if (conditionNote != null && conditionNote.isNotEmpty) {
        data['conditionNote'] = conditionNote;
      }
      if (refundMethod != null) {
        data['refundMethod'] = refundMethod;
      }
      if (photoUrls != null && photoUrls.isNotEmpty) {
        data['photoUrls'] = photoUrls;
      }
      if (managerOverride == true) {
        data['managerOverride'] = true;
      }
      if (exchangeItems != null && exchangeItems.isNotEmpty) {
        data['exchangeItems'] = exchangeItems.map((e) => e.toJson()).toList();
      }

      final response = await _apiClient.post(ApiConstants.returns, data: data);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Search products for exchange
  Future<List<dynamic>> searchProducts(String query) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.products,
        queryParameters: {'search': query, 'isActive': true},
      );
      return response.data is List
          ? response.data
          : (response.data['products'] ?? []);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get product variants for exchange
  Future<Map<String, dynamic>> getProductVariants(String productId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.products}/$productId',
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

// ================== MODELS ==================

/// Returnable response from API
class ReturnableResponse {
  final String transactionId;
  final List<ReturnableItem> items;
  final bool hasFullyReturned;

  ReturnableResponse({
    required this.transactionId,
    required this.items,
    required this.hasFullyReturned,
  });

  factory ReturnableResponse.fromJson(Map<String, dynamic> json) {
    return ReturnableResponse(
      transactionId: json['transactionId'] ?? '',
      items:
          (json['items'] as List?)
              ?.map((e) => ReturnableItem.fromJson(e))
              .toList() ??
          [],
      hasFullyReturned: json['hasFullyReturned'] ?? false,
    );
  }
}

/// Returnable item with qty info
class ReturnableItem {
  final String productVariantId;
  final String productName;
  final String variantInfo;
  final int originalQty;
  final int returnedQty;
  final int returnableQty;
  final double price;

  ReturnableItem({
    required this.productVariantId,
    required this.productName,
    required this.variantInfo,
    required this.originalQty,
    required this.returnedQty,
    required this.returnableQty,
    required this.price,
  });

  factory ReturnableItem.fromJson(Map<String, dynamic> json) {
    return ReturnableItem(
      productVariantId: json['productVariantId'] ?? '',
      productName: json['productName'] ?? '',
      variantInfo: json['variantInfo'] ?? '',
      originalQty: json['originalQty'] ?? 0,
      returnedQty: json['returnedQty'] ?? 0,
      returnableQty: json['returnableQty'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}

/// Return settings from app settings
class ReturnSettings {
  final bool returnEnabled;
  final int returnDeadlineDays;
  final bool returnRequiresApproval;
  final bool exchangeEnabled;

  ReturnSettings({
    this.returnEnabled = false,
    this.returnDeadlineDays = 7,
    this.returnRequiresApproval = true,
    this.exchangeEnabled = false,
  });

  factory ReturnSettings.fromJson(Map<String, dynamic> json) {
    return ReturnSettings(
      returnEnabled: json['returnEnabled'] ?? false,
      returnDeadlineDays: json['returnDeadlineDays'] ?? 7,
      returnRequiresApproval: json['returnRequiresApproval'] ?? true,
      exchangeEnabled: json['exchangeEnabled'] ?? false,
    );
  }
}

/// Return item model for request
class ReturnItem {
  final String productVariantId;
  final int quantity;
  final double price;

  ReturnItem({
    required this.productVariantId,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'productVariantId': productVariantId,
    'quantity': quantity,
    'price': price,
  };
}

/// Exchange item model for request
class ExchangeItem {
  final String productVariantId;
  final int quantity;

  ExchangeItem({required this.productVariantId, required this.quantity});

  Map<String, dynamic> toJson() => {
    'productVariantId': productVariantId,
    'quantity': quantity,
  };
}
