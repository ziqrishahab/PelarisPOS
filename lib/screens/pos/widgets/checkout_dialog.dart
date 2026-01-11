import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import 'receipt_dialog.dart';

class CheckoutDialog extends StatefulWidget {
  const CheckoutDialog({super.key});

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  String _selectedPaymentMethod = 'CASH';
  final _cashReceivedController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _referenceNoController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();

  double _cashReceived = 0;

  @override
  void initState() {
    super.initState();
    _cashReceivedController.addListener(() {
      final text = _cashReceivedController.text.replaceAll('.', '');
      setState(() {
        _cashReceived = double.tryParse(text) ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _cashReceivedController.dispose();
    _bankNameController.dispose();
    _referenceNoController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CartProvider, AuthProvider>(
      builder: (context, cart, auth, _) {
        final total = cart.total;
        final change = _cashReceived - total;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450, maxHeight: 650),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.payment_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Pembayaran',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Total
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.08),
                                AppColors.primary.withValues(alpha: 0.15),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Total Pembayaran',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatCurrency(total),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Payment methods
                        const Text(
                          'Metode Pembayaran',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        _buildPaymentMethods(),
                        const SizedBox(height: 16),

                        // Payment specific fields
                        if (_selectedPaymentMethod == 'CASH') ...[
                          _buildCashFields(total, change),
                        ] else if (_selectedPaymentMethod == 'DEBIT' ||
                            _selectedPaymentMethod == 'TRANSFER') ...[
                          _buildBankFields(),
                        ] else if (_selectedPaymentMethod == 'QRIS') ...[
                          _buildQRISInfo(),
                        ],

                        const SizedBox(height: 16),
                        // Customer info (optional)
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text(
                            'Info Pelanggan (Opsional)',
                            style: TextStyle(fontSize: 14),
                          ),
                          children: [
                            TextField(
                              controller: _customerNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nama Pelanggan',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _customerPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'No. Telepon',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.3),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _canCheckout(total)
                              ? () => _processCheckout(context, cart, auth)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
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
                              : const Text(
                                  'Proses Pembayaran',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethods() {
    return Row(
      children: [
        _PaymentMethodButton(
          label: 'Cash',
          icon: Icons.money,
          color: AppColors.cash,
          isSelected: _selectedPaymentMethod == 'CASH',
          onTap: () => setState(() => _selectedPaymentMethod = 'CASH'),
        ),
        const SizedBox(width: 8),
        _PaymentMethodButton(
          label: 'Debit',
          icon: Icons.credit_card,
          color: AppColors.debit,
          isSelected: _selectedPaymentMethod == 'DEBIT',
          onTap: () => setState(() => _selectedPaymentMethod = 'DEBIT'),
        ),
        const SizedBox(width: 8),
        _PaymentMethodButton(
          label: 'Transfer',
          icon: Icons.account_balance,
          color: AppColors.transfer,
          isSelected: _selectedPaymentMethod == 'TRANSFER',
          onTap: () => setState(() => _selectedPaymentMethod = 'TRANSFER'),
        ),
        const SizedBox(width: 8),
        _PaymentMethodButton(
          label: 'QRIS',
          icon: Icons.qr_code,
          color: AppColors.qris,
          isSelected: _selectedPaymentMethod == 'QRIS',
          onTap: () => setState(() => _selectedPaymentMethod = 'QRIS'),
        ),
      ],
    );
  }

  Widget _buildCashFields(double total, double change) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _cashReceivedController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Uang Diterima',
            prefixText: 'Rp ',
          ),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Quick amount buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickAmountButton(
              amount: total,
              label: 'Uang Pas',
              onTap: () => _setCashReceived(total),
            ),
            _QuickAmountButton(
              amount: 50000,
              onTap: () => _setCashReceived(50000),
            ),
            _QuickAmountButton(
              amount: 100000,
              onTap: () => _setCashReceived(100000),
            ),
            _QuickAmountButton(
              amount: 200000,
              onTap: () => _setCashReceived(200000),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Change
        if (_cashReceived >= total)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withValues(alpha: 0.08),
                  AppColors.success.withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        size: 18,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Kembalian',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatCurrency(change),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBankFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _bankNameController,
          decoration: const InputDecoration(
            labelText: 'Nama Bank',
            hintText: 'Contoh: BCA, Mandiri, BNI',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _referenceNoController,
          decoration: const InputDecoration(
            labelText: 'No. Referensi / Approval',
            hintText: 'Opsional',
          ),
        ),
      ],
    );
  }

  Widget _buildQRISInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.qris.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.qr_code_2,
            size: 64,
            color: AppColors.qris.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scan QR Code untuk pembayaran',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _referenceNoController,
            decoration: const InputDecoration(
              labelText: 'ID Transaksi QRIS',
              hintText: 'Opsional',
            ),
          ),
        ],
      ),
    );
  }

  void _setCashReceived(double amount) {
    _cashReceivedController.text = amount.toStringAsFixed(0);
  }

  bool _canCheckout(double total) {
    if (_selectedPaymentMethod == 'CASH') {
      return _cashReceived >= total;
    }
    return true;
  }

  Future<void> _processCheckout(
    BuildContext context,
    CartProvider cart,
    AuthProvider auth,
  ) async {
    final cabangId = auth.cabangId;
    if (cabangId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Cabang tidak ditemukan'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Set customer info
    if (_customerNameController.text.isNotEmpty ||
        _customerPhoneController.text.isNotEmpty) {
      cart.setCustomerInfo(
        name: _customerNameController.text.isNotEmpty
            ? _customerNameController.text
            : null,
        phone: _customerPhoneController.text.isNotEmpty
            ? _customerPhoneController.text
            : null,
      );
    }

    // Store references before async gap
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final cashReceived = _selectedPaymentMethod == 'CASH'
        ? _cashReceived
        : null;

    // Store cart data before checkout (will be cleared after checkout)
    final cartItems = List<CartItem>.from(cart.items);
    final cartSubtotal = cart.subtotal;
    final cartDiscount = cart.discount;
    final cartTax = cart.tax;
    final cartTotal = cart.total;
    final customerName = cart.customerName;
    final customerPhone = cart.customerPhone;

    final transaction = await cart.checkout(
      cabangId: cabangId,
      paymentMethod: _selectedPaymentMethod,
      bankName: _bankNameController.text.isNotEmpty
          ? _bankNameController.text
          : null,
      referenceNo: _referenceNoController.text.isNotEmpty
          ? _referenceNoController.text
          : null,
    );

    if (!mounted) return;

    if (transaction != null) {
      navigator.pop(); // Close checkout dialog
      // Show receipt - use navigator.context to get valid BuildContext
      showDialog(
        context: navigator.context,
        builder: (ctx) => ReceiptDialog(
          transaction: transaction,
          cashReceived: cashReceived,
          // Pass cart data as fallback in case API doesn't return items
          cartItems: cartItems,
          cartSubtotal: cartSubtotal,
          cartDiscount: cartDiscount,
          cartTax: cartTax,
          cartTotal: cartTotal,
          customerName: customerName,
          customerPhone: customerPhone,
        ),
      );
    } else if (cart.errorMessage != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(cart.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
      cart.clearError();
    }
  }

  String _formatCurrency(double amount) => CurrencyFormatter.format(amount);
}

class _PaymentMethodButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.1),
                        color.withValues(alpha: 0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? color
                    : AppColors.border.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isSelected ? color : AppColors.textSecondary,
                  size: 24,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? color : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAmountButton extends StatelessWidget {
  final double amount;
  final String? label;
  final VoidCallback onTap;

  const _QuickAmountButton({
    required this.amount,
    this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label ?? 'Rp ${amount ~/ 1000}K',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
