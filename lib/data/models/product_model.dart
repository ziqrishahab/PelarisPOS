// Category model
class Category {
  final String id;
  final String name;
  final String? description;
  final int productCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.productCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      productCount: json['_count']?['products'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'description': description};
  }
}

// Product model
class Product {
  final String id;
  final String name;
  final String? description;
  final String categoryId;
  final Category? category;
  final String productType;
  final bool isActive;
  final List<ProductVariant> variants;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.categoryId,
    this.category,
    this.productType = 'VARIANT',
    this.isActive = true,
    this.variants = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      categoryId: json['categoryId'] ?? '',
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
      productType: json['productType'] ?? 'VARIANT',
      isActive: json['isActive'] ?? true,
      variants: json['variants'] != null
          ? (json['variants'] as List)
                .map((v) => ProductVariant.fromJson(v))
                .toList()
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'productType': productType,
      'isActive': isActive,
    };
  }

  // Copy with filtered variants for search
  Product copyWith({List<ProductVariant>? variants}) {
    return Product(
      id: id,
      name: name,
      description: description,
      categoryId: categoryId,
      category: category,
      productType: productType,
      isActive: isActive,
      variants: variants ?? this.variants,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// Product Variant model
class ProductVariant {
  final String id;
  final String productId;
  final String variantName;
  final String variantValue;
  final String sku;
  final int? weight;
  final int? length;
  final int? width;
  final int? height;
  final String? imageUrl;
  final List<Stock> stocks;
  final Product? product;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductVariant({
    required this.id,
    required this.productId,
    required this.variantName,
    required this.variantValue,
    required this.sku,
    this.weight,
    this.length,
    this.width,
    this.height,
    this.imageUrl,
    this.stocks = const [],
    this.product,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      variantName: json['variantName'] ?? '',
      variantValue: json['variantValue'] ?? '',
      sku: json['sku'] ?? '',
      weight: json['weight'],
      length: json['length'],
      width: json['width'],
      height: json['height'],
      imageUrl: json['imageUrl'],
      stocks: json['stocks'] != null
          ? (json['stocks'] as List).map((s) => Stock.fromJson(s)).toList()
          : [],
      product: json['product'] != null
          ? Product.fromJson(json['product'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'variantName': variantName,
      'variantValue': variantValue,
      'sku': sku,
      'weight': weight,
      'length': length,
      'width': width,
      'height': height,
      'imageUrl': imageUrl,
    };
  }

  // Helper methods
  String get displayName =>
      product != null ? '${product!.name} - $variantValue' : variantValue;

  double getPrice(String cabangId) {
    final stock = stocks.where((s) => s.cabangId == cabangId).firstOrNull;
    return stock?.price ?? 0;
  }

  int getQuantity(String cabangId) {
    final stock = stocks.where((s) => s.cabangId == cabangId).firstOrNull;
    return stock?.quantity ?? 0;
  }
}

// Stock model
class Stock {
  final String id;
  final String productVariantId;
  final String cabangId;
  final int quantity;
  final double price;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Stock({
    required this.id,
    required this.productVariantId,
    required this.cabangId,
    this.quantity = 0,
    this.price = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      id: json['id'] ?? '',
      productVariantId: json['productVariantId'] ?? '',
      cabangId: json['cabangId'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productVariantId': productVariantId,
      'cabangId': cabangId,
      'quantity': quantity,
      'price': price,
    };
  }
}
