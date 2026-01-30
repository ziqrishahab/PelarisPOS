import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../api/api_client.dart';
import '../models/models.dart';

class ProductRepository {
  final ApiClient _apiClient;

  ProductRepository(this._apiClient);

  // Get all categories
  Future<List<Category>> getCategories() async {
    try {
      final response = await _apiClient.get(ApiConstants.categories);
      // backend may return either a direct array or a paginated object { data: [...], pagination: {...} }
      final dynamic raw = response.data;
      final List<dynamic> data = raw is List ? raw : (raw['data'] ?? []);
      return data.map((json) => Category.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // Get all products with filters
  Future<List<Product>> getProducts({
    String? categoryId,
    String? search,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (isActive != null) queryParams['isActive'] = isActive.toString();

      final response = await _apiClient.get(
        ApiConstants.products,
        queryParameters: queryParams,
      );
      final dynamic raw = response.data;
      final List<dynamic> data = raw is List ? raw : (raw['data'] ?? []);
      return data.map((json) => Product.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // Get product by ID
  Future<Product> getProductById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConstants.products}/$id');
      return Product.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // Search products by SKU/barcode
  Future<Product?> searchBySku(String sku) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.products,
        queryParameters: {'search': sku},
      );
      final dynamic raw = response.data;
      final List<dynamic> data = raw is List ? raw : (raw['data'] ?? []);
      if (data.isEmpty) return null;

      // Find exact SKU match
      for (var productJson in data) {
        final product = Product.fromJson(productJson);
        for (var variant in product.variants) {
          if (variant.sku.toLowerCase() == sku.toLowerCase()) {
            return product;
          }
        }
      }
      return data.isNotEmpty ? Product.fromJson(data.first) : null;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
