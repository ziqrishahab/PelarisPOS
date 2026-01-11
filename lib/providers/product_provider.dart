import 'package:flutter/material.dart';
import '../core/services/socket_service.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/services/auth_service.dart';
import '../data/api/api_client.dart';

class ProductProvider extends ChangeNotifier {
  final AuthService _authService;
  late final ProductRepository _productRepository;
  final SocketService _socketService = SocketService();

  List<Category> _categories = [];
  List<Product> _products = [];
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;

  ProductProvider(this._authService) {
    final apiClient = ApiClient.getInstance(_authService);
    _productRepository = ProductRepository(apiClient);
    _initSocketListeners();
  }

  // Getters
  List<Category> get categories => _categories;
  List<Product> get products => _products;
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;

  // Filtered products with variant-level filtering
  List<Product> get filteredProducts {
    var filtered = _products.where((p) => p.isActive).toList();

    if (_selectedCategoryId != null) {
      filtered = filtered
          .where((p) => p.categoryId == _selectedCategoryId)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      // Split search into words for AND matching
      // "Baju SD 9" → ["baju", "sd", "9"] → match products/variants containing ALL words
      final searchWords = _searchQuery
          .toLowerCase()
          .trim()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();

      filtered = filtered
          .map((p) {
            // Build product-level searchable text (name + category only)
            final productText = [
              p.name,
              p.category?.name ?? '',
            ].join(' ').toLowerCase();

            // Filter variants that match ALL search words
            final filteredVariants = p.variants.where((v) {
              final variantText = [
                productText,
                v.sku,
                v.variantValue,
                v.variantName,
              ].join(' ').toLowerCase();

              return searchWords.every((word) => variantText.contains(word));
            }).toList();

            // Only include product if it has matching variants
            if (filteredVariants.isNotEmpty) {
              return p.copyWith(variants: filteredVariants);
            }
            return null;
          })
          .whereType<Product>()
          .toList();
    }

    return filtered;
  }

  // Load categories
  Future<void> loadCategories() async {
    try {
      _categories = await _productRepository.getCategories();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Load products
  Future<void> loadProducts({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    // Only set loading for initial load, not refresh
    if (!refresh && !_isRefreshing) {
      _isLoading = true;
      notifyListeners();
    }
    _errorMessage = null;

    try {
      _products = await _productRepository.getProducts(isActive: true);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      if (!_isRefreshing) notifyListeners();
    }
  }

  // Set category filter
  void setCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _selectedCategoryId = null;
    _searchQuery = '';
    notifyListeners();
  }

  // Search by SKU/barcode
  Future<Product?> searchBySku(String sku) async {
    try {
      return await _productRepository.searchBySku(sku);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Refresh all (pull-to-refresh)
  Future<void> refresh() async {
    _isRefreshing = true;
    // Don't notify - let RefreshIndicator handle the UI
    await Future.wait([loadCategories(), loadProducts(refresh: true)]);
    _isRefreshing = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Initialize socket listeners for real-time updates
  void _initSocketListeners() {
    // Listen to stock updates
    _socketService.onStockUpdate((data) {
      debugPrint('[Socket] Stock updated: $data');
      // Refresh products to get latest stock
      loadProducts(refresh: true);
    });

    // Listen to product created
    _socketService.onProductCreated((data) {
      debugPrint('[Socket] Product created: $data');
      loadProducts(refresh: true);
    });

    // Listen to product updated
    _socketService.onProductUpdated((data) {
      debugPrint('[Socket] Product updated: $data');
      loadProducts(refresh: true);
    });

    // Listen to product deleted
    _socketService.onProductDeleted((data) {
      debugPrint('[Socket] Product deleted: $data');
      loadProducts(refresh: true);
    });

    // Listen to category updated
    _socketService.onCategoryUpdated((data) {
      debugPrint('[Socket] Category updated: $data');
      loadCategories();
    });

    // Listen to sync trigger
    _socketService.onSyncTrigger((data) {
      debugPrint('[Socket] Sync trigger: $data');
      refresh();
    });
  }

  @override
  void dispose() {
    // Clean up socket listeners
    _socketService.off('stock:updated');
    _socketService.off('product:created');
    _socketService.off('product:updated');
    _socketService.off('product:deleted');
    _socketService.off('category:updated');
    _socketService.off('sync:trigger');
    super.dispose();
  }
}
