import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProductProvider, AuthProvider>(
      builder: (context, productProvider, authProvider, _) {
        if (productProvider.isLoading) {
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
                  textAlign: TextAlign.center,
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

        // Show message if OWNER/MANAGER hasn't selected a cabang yet
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
                    fontWeight: FontWeight.w500,
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

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getCrossAxisCount(context),
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _ProductCard(product: product, cabangId: cabangId ?? '');
          },
        );
      },
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 5;
    if (width > 900) return 4;
    if (width > 600) return 3;
    return 2;
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final String cabangId;

  const _ProductCard({required this.product, required this.cabangId});

  @override
  Widget build(BuildContext context) {
    final variants = product.variants;
    final hasMultipleVariants = variants.length > 1;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTap(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product icon/image
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.08),
                          AppColors.primary.withValues(alpha: 0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        _getCategoryIcon(product.category?.name),
                        size: 42,
                        color: AppColors.primary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Product name
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (product.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textLight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.category!.name,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const Spacer(),
                      // Price & Stock
                      if (variants.isNotEmpty) ...[
                        _buildPriceAndStock(variants.first),
                      ],
                    ],
                  ),
                ),
                // Variant indicator
                if (hasMultipleVariants) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.style,
                          size: 12,
                          color: AppColors.accent.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${variants.length} varian',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.accent.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceAndStock(ProductVariant variant) {
    final stock = variant.getQuantity(cabangId);
    final price = variant.getPrice(cabangId);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            _formatCurrency(price),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.primary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: stock > 0
                ? AppColors.success.withValues(alpha: 0.12)
                : AppColors.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            stock > 0 ? '$stock' : 'Habis',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: stock > 0 ? AppColors.success : AppColors.error,
            ),
          ),
        ),
      ],
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
      // Langsung tambah ke keranjang
      _addToCart(context, variants.first);
    } else {
      // Tampilkan pilihan varian
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
    // No success snackbar - cart badge updates automatically
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
              // Handle
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
              // Title
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
              // Variant list
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
                            _formatCurrency(price),
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
    if (name.contains('seragam') || name.contains('baju')) {
      return Icons.checkroom;
    }
    if (name.contains('celana')) return Icons.emoji_people;
    if (name.contains('sepatu')) return Icons.ice_skating;
    if (name.contains('tas')) return Icons.backpack;
    if (name.contains('aksesoris')) return Icons.watch;
    return Icons.inventory_2;
  }

  String _formatCurrency(double amount) => CurrencyFormatter.format(amount);
}
