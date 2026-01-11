import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../api/api_client.dart';
import '../models/models.dart';

class TransactionRepository {
  final ApiClient _apiClient;

  TransactionRepository(this._apiClient);

  // Create new transaction (POS)
  Future<Transaction> createTransaction({
    required String cabangId,
    required List<CartItem> items,
    required String paymentMethod,
    String? customerName,
    String? customerPhone,
    double discount = 0,
    double tax = 0,
    String? bankName,
    String? referenceNo,
    String? cardLastDigits,
    bool isSplitPayment = false,
    double? paymentAmount1,
    String? paymentMethod2,
    double? paymentAmount2,
    String? bankName2,
    String? referenceNo2,
    String? notes,
    String? deviceSource,
  }) async {
    try {
      print('[TransactionRepo] createTransaction started');
      print('[TransactionRepo] Items count: ${items.length}');
      print('[TransactionRepo] Payment: $paymentMethod');

      final data = {
        'cabangId': cabangId,
        'items': items.map((item) => item.toTransactionItem()).toList(),
        'paymentMethod': paymentMethod,
        'discount': discount,
        'tax': tax,
      };

      if (customerName != null) data['customerName'] = customerName;
      if (customerPhone != null) data['customerPhone'] = customerPhone;
      if (bankName != null) data['bankName'] = bankName;
      if (referenceNo != null) data['referenceNo'] = referenceNo;
      if (cardLastDigits != null) data['cardLastDigits'] = cardLastDigits;
      if (notes != null) data['notes'] = notes;

      // Device source - auto detect platform
      data['deviceSource'] = deviceSource ?? _getDeviceSource();

      // Split payment
      if (isSplitPayment) {
        data['isSplitPayment'] = true;
        if (paymentAmount1 != null) data['paymentAmount1'] = paymentAmount1;
        if (paymentMethod2 != null) data['paymentMethod2'] = paymentMethod2;
        if (paymentAmount2 != null) data['paymentAmount2'] = paymentAmount2;
        if (bankName2 != null) data['bankName2'] = bankName2;
        if (referenceNo2 != null) data['referenceNo2'] = referenceNo2;
      }

      print('[TransactionRepo] Sending POST to ${ApiConstants.transactions}');
      print('[TransactionRepo] Payload: $data');

      final response = await _apiClient.post(
        ApiConstants.transactions,
        data: data,
      );

      print('[TransactionRepo] Response status: ${response.statusCode}');
      print(
        '[TransactionRepo] Response data type: ${response.data.runtimeType}',
      );

      // Backend returns { message, transaction }, extract transaction
      final transactionData = response.data['transaction'] ?? response.data;
      print('[TransactionRepo] Transaction created: ${transactionData['id']}');
      return Transaction.fromJson(transactionData);
    } on DioException catch (e) {
      print('[TransactionRepo] DioException: ${e.type}');
      print('[TransactionRepo] Message: ${e.message}');
      print('[TransactionRepo] Response: ${e.response?.data}');
      throw ApiException.fromDioError(e);
    } catch (e) {
      print('[TransactionRepo] Unexpected error: $e');
      rethrow;
    }
  }

  // Get transactions list
  Future<Map<String, dynamic>> getTransactions({
    String? cabangId,
    String? status,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (cabangId != null) queryParams['cabangId'] = cabangId;
      if (status != null) queryParams['status'] = status;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      print('[TransactionRepo] getTransactions - params: $queryParams');
      print('[TransactionRepo] URL: ${ApiConstants.transactions}');

      final response = await _apiClient.get(
        ApiConstants.transactions,
        queryParameters: queryParams,
      );

      print('[TransactionRepo] Response status: ${response.statusCode}');
      print('[TransactionRepo] Response type: ${response.data.runtimeType}');

      final data = response.data;

      // API returns array directly, not wrapped in {data: [...]}
      final List<dynamic> transactionsJson = data is List
          ? data
          : (data['data'] ?? []);

      print('[TransactionRepo] Parsed ${transactionsJson.length} transactions');

      return {
        'transactions': transactionsJson
            .map((json) => Transaction.fromJson(json))
            .toList(),
        'pagination': data is Map ? data['pagination'] : null,
      };
    } on DioException catch (e) {
      print('[TransactionRepo] DioException: ${e.type}');
      print('[TransactionRepo] Message: ${e.message}');
      print('[TransactionRepo] Response: ${e.response?.data}');
      throw ApiException.fromDioError(e);
    }
  }

  // Get transaction by ID
  Future<Transaction> getTransactionById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConstants.transactions}/$id');
      return Transaction.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // Get today's transactions
  Future<List<Transaction>> getTodayTransactions(String cabangId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await getTransactions(
      cabangId: cabangId,
      startDate: startOfDay.toIso8601String(),
      endDate: endOfDay.toIso8601String(),
      limit: 100,
    );

    return result['transactions'] as List<Transaction>;
  }

  // Helper to get device source based on platform
  String _getDeviceSource() {
    if (Platform.isAndroid) return 'ANDROID';
    if (Platform.isIOS) return 'IOS';
    if (Platform.isWindows) return 'WINDOWS';
    if (Platform.isMacOS) return 'MACOS';
    if (Platform.isLinux) return 'LINUX';
    return 'UNKNOWN';
  }
}
