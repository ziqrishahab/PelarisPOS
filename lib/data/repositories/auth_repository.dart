import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../api/api_client.dart';
import '../models/models.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  // Login
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // Get current user
  Future<User> getCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiConstants.me);
      return User.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConstants.logout);
    } on DioException {
      // Ignore errors on logout
    }
  }

  // Get cabang list (for OWNER/MANAGER)
  Future<List<Cabang>> getCabangList() async {
    try {
      final response = await _apiClient.get(ApiConstants.cabang);
      // API returns array directly, not {data: [...]}
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);
      return data.map((json) => Cabang.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
