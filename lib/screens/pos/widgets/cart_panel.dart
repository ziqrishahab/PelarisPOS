import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import 'checkout_dialog.dart';
import 'discount_dialog.dart';

/// Compact Cart Panel with expandable item list
class CartPanel extends StatefulWidget {
  final bool isBottomSheet;

  const CartPanel({super.key, this.isBottomSheet = false});

  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> {
  bool _isExpanded = true;
  int _previousItemCount = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        // Auto-collapse when cart is cleared (after checkout)
        if (cart.isEmpty && _previousItemCount > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _isExpanded = false);
            }
          });
        }
        // Auto-expand when first item is added
        else if (!cart.isEmpty && _previousItemCount == 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _isExpanded = true);
            }
          });
        }
        _previousItemCount = cart.itemCount;

        if (cart.isEmpty) {
          return _buildEmptyCart();
        }

        return Column(
          children: [
            // Expandable header with item count
            _buildCompactHeader(context, cart),

            // Expandable item list
            if (_isExpanded)
              Expanded(child: _buildItemList(cart))
            else
              const Spacer(),

            // Summary & Checkout (always visible)
            _buildSummarySection(context, cart),
          ],
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 40,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Keranjang kosong',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap produk untuk menambahkan',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader(BuildContext context, CartProvider cart) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          children: [
            // Cart icon with badge
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Badge(
                label: Text('${cart.itemCount}'),
                backgroundColor: AppColors.primary,
                child: const Icon(
                  Icons.shopping_cart,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Title & item count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${cart.totalQuantity} item',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '${cart.itemCount} produk berbeda',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Expand/collapse icon
            Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
            ),

            const SizedBox(width: 8),

            // Clear button
            IconButton(
              onPressed: () => _showClearCartDialog(context, cart),
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.error,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.error.withValues(alpha: 0.08),
              ),
              tooltip: 'Hapus Semua',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList(CartProvider cart) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: cart.items.length,
      itemBuilder: (context, index) {
        final item = cart.items[index];
        return _CompactCartItem(item: item);
      },
    );
  }

  Widget _buildSummarySection(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Subtotal row
          _buildRow('Subtotal', cart.subtotal),

          // Discount button/row
          if (cart.discount > 0)
            _buildRow('Diskon', -cart.discount, isDiscount: true)
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _showDiscountDialog(context, cart),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Tambah Diskon'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),

          // Tax row (if any)
          if (cart.tax > 0) _buildRow('Pajak', cart.tax),

          const Divider(height: 16),

          // Total row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                CurrencyFormatter.format(cart.total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Checkout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: cart.isProcessing
                  ? null
                  : () => _showCheckoutDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: cart.isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.payment, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Bayar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          CurrencyFormatter.format(cart.total),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}${CurrencyFormatter.format(amount.abs())}',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: isDiscount ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => DiscountDialog(
        subtotal: cart.subtotal,
        currentDiscount: cart.discount,
      ),
    ).then((result) {
      if (result != null && result is DiscountResult) {
        cart.setDiscount(result.calculatedAmount);
      }
    });
  }

  void _showClearCartDialog(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Keranjang'),
        content: const Text('Yakin ingin menghapus semua item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              cart.clearCart();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showCheckoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CheckoutDialog(),
    );
  }
}

/// Ultra-compact cart item row
class _CompactCartItem extends StatelessWidget {
  final CartItem item;

  const _CompactCartItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.read<CartProvider>();

    return Dismissible(
      key: Key(item.productVariantId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => cartProvider.removeItem(item.productVariantId),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Product name & variant (hide if default)
            Expanded(
              flex: 3,
              child: Text(
                _isDefaultVariant(item.variantValue)
                    ? item.productName
                    : '${item.productName} (${item.variantValue})',
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Quantity stepper
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MiniButton(
                  icon: Icons.remove,
                  onTap: () =>
                      cartProvider.decrementQuantity(item.productVariantId),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 28),
                  alignment: Alignment.center,
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                _MiniButton(
                  icon: Icons.add,
                  onTap: item.quantity < item.maxStock
                      ? () => cartProvider.incrementQuantity(
                          item.productVariantId,
                        )
                      : null,
                ),
              ],
            ),

            const SizedBox(width: 8),

            // Subtotal
            SizedBox(
              width: 70,
              child: Text(
                CurrencyFormatter.format(item.subtotal),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isDefaultVariant(String variantValue) {
    final lower = variantValue.toLowerCase();
    return lower.isEmpty ||
        lower == 'default' ||
        lower == 'standard' ||
        lower == 'standar' ||
        lower == '-';
  }
}

/// Mini stepper button
class _MiniButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _MiniButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isEnabled ? AppColors.primary : AppColors.textLight,
        ),
      ),
    );
  }
}
