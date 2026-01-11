import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';

/// Simple Product List View with pull-to-refresh
class ProductList extends StatelessWidget {
  const ProductList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProductProvider, AuthProvider>(
      builder: (context, productProvider, authProvider, _) {
        // Only show loading spinner on initial load, not refresh
        if (productProvider.isLoading &&
            !productProvider.isRefreshing &&
            productProvider.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (productProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  productProvider.errorMessage!,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: productProvider.refresh,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        final products = productProvider.filteredProducts;
        final cabangId = authProvider.cabangId;

        // Show message if OWNER/MANAGER hasn't selected a cabang
        if (authProvider.canSelectCabang && cabangId == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.store_outlined,
                  size: 64,
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pilih cabang terlebih dahulu',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap nama cabang di atas untuk memilih',
                  style: TextStyle(color: AppColors.textLight),
                ),
              ],
            ),
          );
        }

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: AppColors.textLight.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tidak ada produk',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => productProvider.refresh(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _ProductListItem(
                product: product,
                cabangId: cabangId ?? '',
              );
            },
          ),
        );
      },
    );
  }
}

class _ProductListItem extends StatelessWidget {
  final Product product;
  final String cabangId;

  const _ProductListItem({required this.product, required this.cabangId});

  @override
  Widget build(BuildContext context) {
    final variants = product.variants;
    final hasMultipleVariants = variants.length > 1;

    // Get first variant for price display
    final firstVariant = variants.isNotEmpty ? variants.first : null;
    final price = firstVariant?.getPrice(cabangId) ?? 0;

    // Calculate total stock across all variants
    final totalStock = variants.fold<int>(
      0,
      (sum, v) => sum + v.getQuantity(cabangId),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTap(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Product icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      _getCategoryIcon(product.category?.name),
                      size: 24,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(price),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Stock badge or variant indicator
                if (hasMultipleVariants)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.all_inclusive,
                      size: 20,
                      color: AppColors.primary.withValues(alpha: 0.8),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: totalStock > 0
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      totalStock > 0 ? '$totalStock' : 'Habis',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: totalStock > 0
                            ? AppColors.primary
                            : AppColors.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    final variants = product.variants;

    if (variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk tidak memiliki varian')),
      );
      return;
    }

    if (variants.length == 1) {
      _addToCart(context, variants.first);
    } else {
      _showVariantPicker(context);
    }
  }

  void _addToCart(BuildContext context, ProductVariant variant) {
    final cartProvider = context.read<CartProvider>();
    cartProvider.addFromVariant(product, variant, cabangId);

    if (cartProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cartProvider.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
      cartProvider.clearError();
    }
  }

  void _showVariantPicker(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pilih varian:',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: product.variants.length,
                  itemBuilder: (context, index) {
                    final variant = product.variants[index];
                    final stock = variant.getQuantity(cabangId);
                    final price = variant.getPrice(cabangId);
                    final isAvailable = stock > 0;

                    return ListTile(
                      onTap: isAvailable
                          ? () {
                              Navigator.pop(sheetContext);
                              _addToCart(parentContext, variant);
                            }
                          : null,
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.textLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            variant.variantValue.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isAvailable
                                  ? AppColors.primary
                                  : AppColors.textLight,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        variant.variantValue,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isAvailable
                              ? AppColors.textPrimary
                              : AppColors.textLight,
                        ),
                      ),
                      subtitle: Text(
                        'SKU: ${variant.sku}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(price),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isAvailable
                                  ? AppColors.primary
                                  : AppColors.textLight,
                            ),
                          ),
                          Text(
                            isAvailable ? 'Stok: $stock' : 'Habis',
                            style: TextStyle(
                              fontSize: 11,
                              color: isAvailable
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? categoryName) {
    if (categoryName == null) return Icons.inventory_2;
    final name = categoryName.toLowerCase();
    if (name.contains('minuman')) return Icons.local_drink;
    if (name.contains('laundry') || name.contains('cuci')) {
      return Icons.local_laundry_service;
    }
    if (name.contains('equipment') || name.contains('peralatan')) {
      return Icons.handyman;
    }
    if (name.contains('seragam') || name.contains('baju')) {
      return Icons.checkroom;
    }
    if (name.contains('celana')) return Icons.emoji_people;
    if (name.contains('sepatu')) return Icons.ice_skating;
    if (name.contains('tas')) return Icons.backpack;
    if (name.contains('aksesoris')) return Icons.watch;
    return Icons.inventory_2;
  }
}
