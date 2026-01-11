import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/models.dart';
import '../../../data/services/print_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/settings_provider.dart';

class ReceiptDialog extends StatelessWidget {
  final Transaction transaction;
  final double? cashReceived;
  // Cart data fallback (in case API doesn't return items)
  final List<CartItem>? cartItems;
  final double? cartSubtotal;
  final double? cartDiscount;
  final double? cartTax;
  final double? cartTotal;
  final String? customerName;
  final String? customerPhone;

  const ReceiptDialog({
    super.key,
    required this.transaction,
    this.cashReceived,
    this.cartItems,
    this.cartSubtotal,
    this.cartDiscount,
    this.cartTax,
    this.cartTotal,
    this.customerName,
    this.customerPhone,
  });

  // Use cart data if transaction items are empty
  List<_DisplayItem> get _displayItems {
    if (transaction.items.isNotEmpty) {
      return transaction.items
          .map(
            (item) => _DisplayItem(
              name: item.productName,
              variantInfo: item.variantInfo,
              quantity: item.quantity,
              price: item.price,
              subtotal: item.subtotal,
            ),
          )
          .toList();
    } else if (cartItems != null && cartItems!.isNotEmpty) {
      return cartItems!
          .map(
            (item) => _DisplayItem(
              name: item.productName,
              variantInfo: item.variantInfo,
              quantity: item.quantity,
              price: item.price,
              subtotal: item.subtotal,
            ),
          )
          .toList();
    }
    return [];
  }

  double get _subtotal =>
      transaction.subtotal > 0 ? transaction.subtotal : (cartSubtotal ?? 0);
  double get _discount =>
      transaction.discount > 0 ? transaction.discount : (cartDiscount ?? 0);
  double get _tax => transaction.tax > 0 ? transaction.tax : (cartTax ?? 0);
  double get _total =>
      transaction.total > 0 ? transaction.total : (cartTotal ?? 0);
  String? get _customerName => transaction.customerName ?? customerName;
  String? get _customerPhone => transaction.customerPhone ?? customerPhone;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy HH:mm', 'id_ID');
    final change = cashReceived != null ? cashReceived! - _total : 0.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 64),
                  const SizedBox(height: 8),
                  const Text(
                    'Transaksi Berhasil!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.transactionNo.isNotEmpty
                        ? transaction.transactionNo
                        : (transaction.id.length > 8
                              ? 'ID: ${transaction.id.substring(0, 8)}'
                              : 'ID: ${transaction.id}'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Receipt content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Date & Time
                    Center(
                      child: Text(
                        dateFormat.format(transaction.createdAt),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Items
                    ..._displayItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    _isDefaultVariant(item.variantInfo)
                                        ? 'x${item.quantity}'
                                        : '${item.variantInfo} x${item.quantity}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatCurrency(item.subtotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Summary
                    _buildSummaryRow('Subtotal', _subtotal),
                    if (_discount > 0)
                      _buildSummaryRow('Diskon', -_discount, isDiscount: true),
                    if (_tax > 0) _buildSummaryRow('Pajak', _tax),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Total', _total, isTotal: true),

                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Payment info
                    _buildInfoRow(
                      'Pembayaran',
                      _getPaymentMethodText(transaction.paymentMethod),
                    ),
                    if (cashReceived != null) ...[
                      _buildInfoRow('Tunai', _formatCurrency(cashReceived!)),
                      _buildInfoRow(
                        'Kembalian',
                        _formatCurrency(change),
                        highlight: true,
                      ),
                    ],
                    if (transaction.bankName != null)
                      _buildInfoRow('Bank', transaction.bankName!),
                    if (transaction.referenceNo != null)
                      _buildInfoRow('Ref', transaction.referenceNo!),

                    // Customer info
                    if (_customerName != null || _customerPhone != null) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      if (_customerName != null)
                        _buildInfoRow('Pelanggan', _customerName!),
                      if (_customerPhone != null)
                        _buildInfoRow('Telepon', _customerPhone!),
                    ],
                  ],
                ),
              ),
            ),
            // Footer buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _printReceipt(context),
                      icon: const Icon(Icons.print),
                      label: const Text('Cetak'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Selesai'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}${_formatCurrency(amount.abs())}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
              color: isDiscount
                  ? AppColors.success
                  : (isTotal ? AppColors.primary : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
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
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              color: highlight ? AppColors.success : null,
              fontSize: highlight ? 16 : 13,
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Tunai';
      case PaymentMethod.debit:
        return 'Kartu Debit';
      case PaymentMethod.transfer:
        return 'Transfer Bank';
      case PaymentMethod.qris:
        return 'QRIS';
    }
  }

  String _formatCurrency(double amount) => CurrencyFormatter.format(amount);

  Future<void> _printReceipt(BuildContext context) async {
    final printService = PrintService();
    final authProvider = context.read<AuthProvider>();

    // Check printer connection
    final isConnected = await printService.isConnected;
    if (!isConnected) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Printer tidak terhubung. Buka Pengaturan Printer untuk menghubungkan.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      // Get store info from settings provider (synced from backend)
      if (!context.mounted) return;
      final settingsProvider = context.read<SettingsProvider>();
      final user = authProvider.user;

      // Force refresh settings before printing to ensure latest data
      final cabangId = authProvider.cabangId;

      if (cabangId != null) {
        await settingsProvider.fetchPrinterSettings(cabangId);
      }

      // Prepare print data - use settings from backend
      final printData = PrintReceiptData(
        storeName: settingsProvider.storeName,
        branchName: settingsProvider.branchName,
        address: settingsProvider.address,
        phone: settingsProvider.phone,
        cashierName: user?.name,
        transactionNo: transaction.transactionNo,
        items: _displayItems
            .map(
              (item) => PrintReceiptItem(
                name: item.name,
                variant:
                    item.variantInfo.isNotEmpty &&
                        !_isDefaultVariant(item.variantInfo)
                    ? item.variantInfo
                    : null,
                qty: item.quantity,
                price: item.price,
                subtotal: item.subtotal,
              ),
            )
            .toList(),
        subtotal: _subtotal,
        discount: _discount,
        tax: _tax,
        total: _total,
        paymentMethod: transaction.paymentMethod.name.toUpperCase(),
        cashReceived: cashReceived,
        change: cashReceived != null && _total > 0
            ? cashReceived! - _total
            : null,
        isSplitPayment: transaction.isSplitPayment,
        paymentAmount1: transaction.paymentAmount1,
        paymentMethod2: transaction.paymentMethod2?.name.toUpperCase(),
        paymentAmount2: transaction.paymentAmount2,
        customerName: _customerName,
        customerPhone: _customerPhone,
        date: transaction.createdAt,
        paperWidth: settingsProvider.paperWidth,
        footerText1: settingsProvider.footerText1 ?? 'Terima Kasih.',
        footerNote: settingsProvider.footerText2,
      );

      await printService.printReceipt(printData);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Struk berhasil dicetak!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mencetak: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  bool _isDefaultVariant(String variantInfo) {
    final lower = variantInfo.toLowerCase();
    return lower.isEmpty ||
        lower == 'default' ||
        lower == 'standard' ||
        lower == 'standar' ||
        lower == 'default: standard' ||
        lower == 'default: standar' ||
        lower == 'default: default' ||
        lower == '-';
  }
}

/// Helper class for displaying items (from transaction or cart)
class _DisplayItem {
  final String name;
  final String variantInfo;
  final int quantity;
  final double price;
  final double subtotal;

  _DisplayItem({
    required this.name,
    required this.variantInfo,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });
}
