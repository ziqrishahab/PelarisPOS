import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/return_repository.dart';
import '../../../data/api/api_client.dart';
import '../../../data/services/auth_service.dart';
import '../../../providers/providers.dart';
import '../../pos/widgets/receipt_dialog.dart';

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final transactionProvider = context.read<TransactionProvider>();
      transactionProvider.setCabangId(authProvider.cabangId);
      transactionProvider.fetchTransactions();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<TransactionProvider>().fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transaksi', style: TextStyle(fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, _) {
          if (transactionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (transactionProvider.errorMessage != null) {
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
                    transactionProvider.errorMessage!,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _onRefresh,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final transactions = transactionProvider.transactions;

          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: AppColors.textLight.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada transaksi',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Transaksi akan muncul di sini',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return _TransactionCard(transaction: transaction);
              },
            ),
          );
        },
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Filter Transaksi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.today),
                title: const Text('Hari Ini'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<TransactionProvider>().filterByDate(
                    DateTime.now(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text('7 Hari Terakhir'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<TransactionProvider>().filterByDateRange(
                    DateTime.now().subtract(const Duration(days: 7)),
                    DateTime.now(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Bulan Ini'),
                onTap: () {
                  Navigator.pop(ctx);
                  final now = DateTime.now();
                  context.read<TransactionProvider>().filterByDateRange(
                    DateTime(now.year, now.month, 1),
                    DateTime.now(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text('Semua'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<TransactionProvider>().clearFilter();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final transactionNo = transaction.transactionNo;
    final total = transaction.total;
    final createdAt = transaction.createdAt;
    final itemCount = transaction.items.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTransactionDetail(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transactionNo,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                // Footer row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$itemCount item',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(total),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    String label;

    // Prioritize return status if exists
    if (transaction.hasReturn && transaction.returnStatus != null) {
      switch (transaction.returnStatus!) {
        case ReturnStatus.pending:
          bgColor = Colors.orange.withValues(alpha: 0.15);
          textColor = Colors.orange;
          label = 'Return Pending';
          break;
        case ReturnStatus.completed:
          bgColor = Colors.blue.withValues(alpha: 0.15);
          textColor = Colors.blue;
          label = 'Returned';
          break;
        case ReturnStatus.rejected:
          bgColor = AppColors.error.withValues(alpha: 0.15);
          textColor = AppColors.error;
          label = 'Return Ditolak';
          break;
      }
    } else {
      // Normal payment status
      switch (transaction.paymentStatus) {
        case PaymentStatus.completed:
          bgColor = AppColors.success.withValues(alpha: 0.15);
          textColor = AppColors.success;
          label = 'Selesai';
          break;
        case PaymentStatus.pending:
          bgColor = AppColors.warning.withValues(alpha: 0.15);
          textColor = AppColors.warning;
          label = 'Pending';
          break;
        case PaymentStatus.cancelled:
          bgColor = AppColors.error.withValues(alpha: 0.15);
          textColor = AppColors.error;
          label = 'Batal';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Hari ini ${_formatTime(date)}';
    } else if (transactionDate == today.subtract(const Duration(days: 1))) {
      return 'Kemarin ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year} ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showTransactionDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detail Transaksi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                transaction.transactionNo,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),

              // Payment & Customer Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      'Metode Pembayaran',
                      _getPaymentMethodLabel(transaction.paymentMethod),
                    ),
                    if (transaction.customerName != null &&
                        transaction.customerName!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow('Pelanggan', transaction.customerName!),
                    ],
                    if (transaction.bankName != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow('Bank', transaction.bankName!),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Items',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              // Items list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: transaction.items.length,
                  itemBuilder: (context, index) {
                    final item = transaction.items[index];
                    final showVariant = !_isDefaultVariant(item.variantInfo);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${item.quantity}x',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (showVariant)
                                  Text(
                                    item.variantInfo,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(item.subtotal),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Subtotal, discount, tax section
              if (transaction.discount > 0 || transaction.tax > 0) ...[
                const Divider(),
                if (transaction.discount > 0)
                  _buildTotalRow(
                    'Diskon',
                    '-${CurrencyFormatter.format(transaction.discount)}',
                    isNegative: true,
                  ),
                if (transaction.tax > 0)
                  _buildTotalRow(
                    'Pajak',
                    CurrencyFormatter.format(transaction.tax),
                  ),
              ],

              const Divider(),
              const SizedBox(height: 8),
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    CurrencyFormatter.format(transaction.total),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  // Only show Return button if no pending/completed return
                  // Allow re-request if return was rejected
                  if (!transaction.hasReturn ||
                      transaction.returnStatus == ReturnStatus.rejected)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showReturnDialog(context);
                        },
                        icon: const Icon(Icons.assignment_return, size: 18),
                        label: const Text('Return'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(color: AppColors.warning),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (!transaction.hasReturn ||
                      transaction.returnStatus == ReturnStatus.rejected)
                    const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showReceiptDialog(context);
                      },
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Cetak'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReceiptDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => ReceiptDialog(transaction: transaction),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(color: isNegative ? AppColors.error : null),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
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

  bool _isDefaultVariant(String variantInfo) {
    final lower = variantInfo.toLowerCase();
    return lower.isEmpty ||
        lower == 'default' ||
        lower == 'standard' ||
        lower == 'standar' ||
        lower == 'default: standard' ||
        lower == 'default: standar' ||
        lower == 'default: default';
  }

  void _showReturnDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ReturnBottomSheet(transaction: transaction),
    );
  }
}

/// Return reason enum
enum ReturnReason { damaged, wrongItem, notAsDescribed, customerRequest, other }

/// Return bottom sheet widget
class _ReturnBottomSheet extends StatefulWidget {
  final Transaction transaction;

  const _ReturnBottomSheet({required this.transaction});

  @override
  State<_ReturnBottomSheet> createState() => _ReturnBottomSheetState();
}

class _ReturnBottomSheetState extends State<_ReturnBottomSheet> {
  final Map<String, int> _returnQuantities = {};
  ReturnReason _selectedReason = ReturnReason.damaged;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize all quantities to 0
    for (final item in widget.transaction.items) {
      _returnQuantities[item.productVariantId] = 0;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _totalRefund {
    double total = 0;
    for (final item in widget.transaction.items) {
      final qty = _returnQuantities[item.productVariantId] ?? 0;
      total += item.price * qty;
    }
    return total;
  }

  bool get _hasItemsSelected {
    return _returnQuantities.values.any((qty) => qty > 0);
  }

  String _getReasonLabel(ReturnReason reason) {
    switch (reason) {
      case ReturnReason.damaged:
        return 'Barang Rusak';
      case ReturnReason.wrongItem:
        return 'Salah Kirim';
      case ReturnReason.notAsDescribed:
        return 'Tidak Sesuai Deskripsi';
      case ReturnReason.customerRequest:
        return 'Permintaan Pelanggan';
      case ReturnReason.other:
        return 'Lainnya';
    }
  }

  String _getReasonValue(ReturnReason reason) {
    switch (reason) {
      case ReturnReason.damaged:
        return 'DAMAGED';
      case ReturnReason.wrongItem:
        return 'WRONG_ITEM';
      case ReturnReason.notAsDescribed:
        return 'NOT_AS_DESCRIBED';
      case ReturnReason.customerRequest:
        return 'CUSTOMER_REQUEST';
      case ReturnReason.other:
        return 'OTHER';
    }
  }

  Future<void> _submitReturn() async {
    if (!_hasItemsSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 item untuk diretur')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authService = AuthService();
      final apiClient = ApiClient.getInstance(authService);
      final returnRepo = ReturnRepository(apiClient);

      final items = widget.transaction.items
          .where((item) => (_returnQuantities[item.productVariantId] ?? 0) > 0)
          .map(
            (item) => ReturnItem(
              productVariantId: item.productVariantId,
              quantity: _returnQuantities[item.productVariantId]!,
              price: item.price,
            ),
          )
          .toList();

      await returnRepo.createReturn(
        transactionId: widget.transaction.id,
        reason: _getReasonValue(_selectedReason),
        items: items,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        refundMethod: widget.transaction.paymentMethod.name.toUpperCase(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request return berhasil dikirim!'),
            backgroundColor: AppColors.success,
          ),
        );
        // Refresh transactions
        context.read<TransactionProvider>().fetchTransactions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const Text(
              'Request Return',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.transaction.transactionNo,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Items to return
            const Text(
              'Pilih Item & Jumlah',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.transaction.items.length,
                itemBuilder: (context, index) {
                  final item = widget.transaction.items[index];
                  final qty = _returnQuantities[item.productVariantId] ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: qty > 0
                          ? Border.all(color: AppColors.primary)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Max: ${item.quantity} • ${CurrencyFormatter.format(item.price)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                size: 24,
                              ),
                              onPressed: qty > 0
                                  ? () => setState(
                                      () =>
                                          _returnQuantities[item
                                                  .productVariantId] =
                                              qty - 1,
                                    )
                                  : null,
                              color: AppColors.primary,
                            ),
                            Text(
                              '$qty',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 24,
                              ),
                              onPressed: qty < item.quantity
                                  ? () => setState(
                                      () =>
                                          _returnQuantities[item
                                                  .productVariantId] =
                                              qty + 1,
                                    )
                                  : null,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Reason dropdown
            const Text(
              'Alasan Return',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ReturnReason>(
                  value: _selectedReason,
                  isExpanded: true,
                  items: ReturnReason.values.map((reason) {
                    return DropdownMenuItem(
                      value: reason,
                      child: Text(_getReasonLabel(reason)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedReason = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Catatan tambahan (opsional)',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Total refund
            if (_hasItemsSelected)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Refund',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      CurrencyFormatter.format(_totalRefund),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReturn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Kirim Request Return'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
