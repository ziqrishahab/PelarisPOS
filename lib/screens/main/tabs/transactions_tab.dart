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

/// Return reason enum - matches backend ReturnReason
enum ReturnReasonType {
  // Return (Refund)
  customerRequest,
  other,
  // Exchange
  wrongSize,
  wrongItem,
  defective,
  expired,
}

/// Return bottom sheet widget with full features
class _ReturnBottomSheet extends StatefulWidget {
  final Transaction transaction;

  const _ReturnBottomSheet({required this.transaction});

  @override
  State<_ReturnBottomSheet> createState() => _ReturnBottomSheetState();
}

class _ReturnBottomSheetState extends State<_ReturnBottomSheet> {
  // Data
  final Map<String, int> _returnQuantities = {};
  Map<String, ReturnableItem> _returnableItems = {};
  ReturnSettings? _settings;

  // Form state
  ReturnReasonType _selectedReason = ReturnReasonType.customerRequest;
  final _notesController = TextEditingController();
  final _reasonDetailController = TextEditingController();
  bool _managerOverride = false;

  // Exchange state
  final Map<String, String> _exchangeVariants =
      {}; // original variantId -> new variantId

  // UI state
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isOverdue = false;

  late ReturnRepository _returnRepo;

  @override
  void initState() {
    super.initState();
    _initRepository();
    _loadData();
  }

  void _initRepository() {
    final authService = AuthService();
    final apiClient = ApiClient.getInstance(authService);
    _returnRepo = ReturnRepository(apiClient);
  }

  Future<void> _loadData() async {
    try {
      print('[Return] Loading data for transaction: ${widget.transaction.id}');

      // Load settings first
      ReturnSettings settings;
      try {
        settings = await _returnRepo.getReturnSettings();
        print(
          '[Return] Settings loaded: returnEnabled=${settings.returnEnabled}',
        );
      } catch (e) {
        print('[Return] Failed to load settings: $e');
        // Default settings if failed
        settings = ReturnSettings(
          returnEnabled: true,
          returnDeadlineDays: 7,
          returnRequiresApproval: true,
          exchangeEnabled: false,
        );
      }

      // Load returnable quantities
      ReturnableResponse returnable;
      try {
        returnable = await _returnRepo.getReturnableQuantities(
          widget.transaction.id,
        );
        print('[Return] Returnable loaded: ${returnable.items.length} items');
      } catch (e) {
        print('[Return] Failed to load returnable: $e');
        // Build from transaction items if API fails
        returnable = ReturnableResponse(
          transactionId: widget.transaction.id,
          items: widget.transaction.items
              .map(
                (item) => ReturnableItem(
                  productVariantId: item.productVariantId,
                  productName: item.productName,
                  variantInfo: item.variantInfo,
                  originalQty: item.quantity,
                  returnedQty: 0,
                  returnableQty: item.quantity,
                  price: item.price,
                ),
              )
              .toList(),
          hasFullyReturned: false,
        );
      }

      // Check if return is enabled
      if (!settings.returnEnabled) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Fitur return tidak diaktifkan';
        });
        return;
      }

      // Check if all items already returned
      if (returnable.hasFullyReturned) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Semua item sudah diretur';
        });
        return;
      }

      // Check overdue
      final transactionDate = widget.transaction.createdAt;
      final deadline = transactionDate.add(
        Duration(days: settings.returnDeadlineDays),
      );
      final isOverdue = DateTime.now().isAfter(deadline);

      // Build returnable items map
      final returnableMap = <String, ReturnableItem>{};
      for (final item in returnable.items) {
        returnableMap[item.productVariantId] = item;
        _returnQuantities[item.productVariantId] = 0;
      }

      setState(() {
        _settings = settings;
        _returnableItems = returnableMap;
        _isOverdue = isOverdue;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat data: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _reasonDetailController.dispose();
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

  bool get _isExchangeReason {
    return [
      ReturnReasonType.wrongSize,
      ReturnReasonType.wrongItem,
      ReturnReasonType.defective,
      ReturnReasonType.expired,
    ].contains(_selectedReason);
  }

  String _getReasonLabel(ReturnReasonType reason) {
    switch (reason) {
      case ReturnReasonType.customerRequest:
        return 'Permintaan Customer';
      case ReturnReasonType.other:
        return 'Lainnya';
      case ReturnReasonType.wrongSize:
        return 'Salah Ukuran (Tukar Varian)';
      case ReturnReasonType.wrongItem:
        return 'Salah Barang (Tukar Produk)';
      case ReturnReasonType.defective:
        return 'Barang Rusak/Cacat (Ganti Baru)';
      case ReturnReasonType.expired:
        return 'Kadaluarsa (Ganti Baru)';
    }
  }

  String _getReasonValue(ReturnReasonType reason) {
    switch (reason) {
      case ReturnReasonType.customerRequest:
        return 'CUSTOMER_REQUEST';
      case ReturnReasonType.other:
        return 'OTHER';
      case ReturnReasonType.wrongSize:
        return 'WRONG_SIZE';
      case ReturnReasonType.wrongItem:
        return 'WRONG_ITEM';
      case ReturnReasonType.defective:
        return 'DEFECTIVE';
      case ReturnReasonType.expired:
        return 'EXPIRED';
    }
  }

  List<ReturnReasonType> get _availableReasons {
    final reasons = <ReturnReasonType>[
      ReturnReasonType.customerRequest,
      ReturnReasonType.other,
    ];

    if (_settings?.exchangeEnabled == true) {
      reasons.addAll([
        ReturnReasonType.wrongSize,
        ReturnReasonType.wrongItem,
        ReturnReasonType.defective,
        ReturnReasonType.expired,
      ]);
    }

    return reasons;
  }

  Future<void> _submitReturn() async {
    if (!_hasItemsSelected) {
      _showError('Pilih minimal 1 item untuk diretur');
      return;
    }

    // Check overdue with manager override
    if (_isOverdue && !_managerOverride) {
      _showError(
        'Return sudah melewati batas waktu. Aktifkan override manager untuk melanjutkan.',
      );
      return;
    }

    // For exchange, validate exchange items are selected
    if (_isExchangeReason && _selectedReason == ReturnReasonType.wrongSize) {
      final selectedItems = widget.transaction.items.where(
        (item) => (_returnQuantities[item.productVariantId] ?? 0) > 0,
      );

      for (final item in selectedItems) {
        if (_exchangeVariants[item.productVariantId] == null) {
          _showError('Pilih varian pengganti untuk semua item');
          return;
        }
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final cabangId = authProvider.cabangId;

      if (cabangId == null || cabangId.isEmpty) {
        throw Exception('Cabang tidak ditemukan');
      }

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

      // Build exchange items for WRONG_SIZE or DEFECTIVE/EXPIRED
      List<ExchangeItem>? exchangeItems;
      if (_isExchangeReason) {
        if (_selectedReason == ReturnReasonType.wrongSize) {
          exchangeItems = items.map((item) {
            final newVariantId = _exchangeVariants[item.productVariantId];
            return ExchangeItem(
              productVariantId: newVariantId ?? item.productVariantId,
              quantity: item.quantity,
            );
          }).toList();
        } else if (_selectedReason == ReturnReasonType.defective ||
            _selectedReason == ReturnReasonType.expired) {
          // For defective/expired, exchange with same product (new unit)
          exchangeItems = items.map((item) {
            return ExchangeItem(
              productVariantId: item.productVariantId,
              quantity: item.quantity,
            );
          }).toList();
        }
      }

      await _returnRepo.createReturn(
        transactionId: widget.transaction.id,
        cabangId: cabangId,
        reason: _getReasonValue(_selectedReason),
        items: items,
        reasonDetail: _reasonDetailController.text.isNotEmpty
            ? _reasonDetailController.text
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        refundMethod: widget.transaction.paymentMethod.name.toUpperCase(),
        managerOverride: _isOverdue ? _managerOverride : null,
        exchangeItems: exchangeItems,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isExchangeReason
                  ? 'Request tukar barang berhasil dikirim!'
                  : 'Request return berhasil dikirim!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        // Refresh transactions
        context.read<TransactionProvider>().fetchTransactions();
      }
    } catch (e) {
      _showError('Gagal: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
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
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          : _errorMessage != null
          ? _buildErrorView()
          : _buildForm(),
    );
  }

  Widget _buildErrorView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 32),
        Icon(
          Icons.error_outline,
          size: 64,
          color: AppColors.error.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 16),
        Text(
          _errorMessage!,
          style: const TextStyle(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Return / Tukar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'OVERDUE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          Text(
            widget.transaction.transactionNo,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          // Overdue warning with manager override
          if (_isOverdue) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: AppColors.error,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Return sudah melewati batas waktu',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _managerOverride,
                        onChanged: (val) =>
                            setState(() => _managerOverride = val ?? false),
                        activeColor: AppColors.error,
                      ),
                      const Expanded(
                        child: Text(
                          'Override Manager (lanjutkan return)',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Items to return
          const Text(
            'Pilih Item & Jumlah',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.transaction.items.length,
              itemBuilder: (context, index) {
                final item = widget.transaction.items[index];
                final returnableInfo = _returnableItems[item.productVariantId];
                final maxQty = returnableInfo?.returnableQty ?? item.quantity;
                final returnedQty = returnableInfo?.returnedQty ?? 0;
                final isFullyReturned = maxQty <= 0;
                final qty = _returnQuantities[item.productVariantId] ?? 0;

                return Opacity(
                  opacity: isFullyReturned ? 0.5 : 1.0,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isFullyReturned
                          ? AppColors.background.withValues(alpha: 0.5)
                          : AppColors.background,
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
                                'Max: $maxQty • ${CurrencyFormatter.format(item.price)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (returnedQty > 0)
                                Text(
                                  'Sudah diretur: $returnedQty',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.warning.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                              if (isFullyReturned)
                                const Text(
                                  '✓ Sudah diretur semua',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (!isFullyReturned)
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
                                onPressed: qty < maxQty
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
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Reason dropdown
          const Text('Alasan', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ReturnReasonType>(
                value: _selectedReason,
                isExpanded: true,
                items: _availableReasons.map((reason) {
                  final isExchange = [
                    ReturnReasonType.wrongSize,
                    ReturnReasonType.wrongItem,
                    ReturnReasonType.defective,
                    ReturnReasonType.expired,
                  ].contains(reason);

                  return DropdownMenuItem(
                    value: reason,
                    child: Row(
                      children: [
                        if (isExchange)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'TUKAR',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        Expanded(child: Text(_getReasonLabel(reason))),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedReason = value);
                },
              ),
            ),
          ),

          // Exchange info
          if (_isExchangeReason) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, color: AppColors.info, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedReason == ReturnReasonType.wrongSize
                          ? 'Tukar dengan varian lain dari produk yang sama'
                          : _selectedReason == ReturnReasonType.wrongItem
                          ? 'Tukar dengan produk lain'
                          : 'Barang lama akan di-write off, diganti unit baru',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Reason detail (for OTHER)
          if (_selectedReason == ReturnReasonType.other) ...[
            TextField(
              controller: _reasonDetailController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Jelaskan alasan return...',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

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
                color: _isExchangeReason
                    ? AppColors.info.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isExchangeReason ? 'Nilai Tukar' : 'Total Refund',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    CurrencyFormatter.format(_totalRefund),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _isExchangeReason
                          ? AppColors.info
                          : AppColors.warning,
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
                backgroundColor: _isExchangeReason
                    ? AppColors.info
                    : AppColors.warning,
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
                  : Text(
                      _isExchangeReason
                          ? 'Kirim Request Tukar'
                          : 'Kirim Request Return',
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
