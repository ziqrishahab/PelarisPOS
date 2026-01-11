import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../api/api_client.dart';

class ReturnRepository {
  final ApiClient _apiClient;

  ReturnRepository(this._apiClient);

  /// Create a return request
  Future<Map<String, dynamic>> createReturn({
    required String transactionId,
    required String reason,
    required List<ReturnItem> items,
    String? notes,
    String? refundMethod,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.returns,
        data: {
          'transactionId': transactionId,
          'reason': reason,
          'notes': notes,
          'refundMethod': refundMethod,
          'items': items.map((item) => item.toJson()).toList(),
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
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
