import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../services/auth_service.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final AuthService _authService;

  ApiClient._internal(this._authService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Request interceptor - add auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _authService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log disabled for production
          return handler.next(response);
        },
        onError: (error, handler) {
          // Handle 401 Unauthorized - logout
          if (error.response?.statusCode == 401) {
            _authService.logout();
          }

          return handler.next(error);
        },
      ),
    );
  }

  static ApiClient getInstance(AuthService authService) {
    _instance ??= ApiClient._internal(authService);
    return _instance!;
  }

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

// API Exception handling
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({required this.message, this.statusCode, this.data});

  factory ApiException.fromDioError(DioException error) {
    String message;
    int? statusCode = error.response?.statusCode;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Koneksi timeout. Periksa koneksi internet Anda.';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Timeout saat mengirim data.';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Timeout saat menerima data.';
        break;
      case DioExceptionType.badResponse:
        message = _handleBadResponse(error.response);
        break;
      case DioExceptionType.cancel:
        message = 'Request dibatalkan.';
        break;
      case DioExceptionType.connectionError:
        message = 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
        break;
      default:
        message = 'Terjadi kesalahan. Silakan coba lagi.';
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      data: error.response?.data,
    );
  }

  static String _handleBadResponse(Response? response) {
    if (response == null) return 'Terjadi kesalahan pada server.';

    final data = response.data;
    if (data is Map && data.containsKey('error')) {
      return data['error'].toString();
    }
    if (data is Map && data.containsKey('message')) {
      return data['message'].toString();
    }

    switch (response.statusCode) {
      case 400:
        return 'Request tidak valid.';
      case 401:
        return 'Sesi telah berakhir. Silakan login kembali.';
      case 403:
        return 'Anda tidak memiliki akses.';
      case 404:
        return 'Data tidak ditemukan.';
      case 500:
        return 'Terjadi kesalahan pada server.';
      default:
        return 'Terjadi kesalahan. Kode: ${response.statusCode}';
    }
  }

  @override
  String toString() => message;
}
