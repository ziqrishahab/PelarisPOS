import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/providers.dart';
import 'widgets/product_list.dart';
import 'widgets/cart_panel.dart';
import 'widgets/category_tabs.dart';
import 'widgets/qr_scanner_screen.dart';
import '../main/tabs/transactions_tab.dart';
import '../main/tabs/settings_tab.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final productProvider = context.read<ProductProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    // Fetch cabang list for OWNER/MANAGER
    await authProvider.fetchCabangList();
    await productProvider.refresh();

    // Fetch printer settings from backend (use user's cabang)
    final cabangId = authProvider.cabangId;
    if (cabangId != null) {
      await settingsProvider.fetchPrinterSettings(cabangId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    // For wide screens, no bottom nav - just POS layout
    if (isWide) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: _buildWideLayout(),
      );
    }

    // For narrow screens, show bottom navigation
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildPosTab(),
          const TransactionsTab(),
          const SettingsTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      resizeToAvoidBottomInset: false,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.point_of_sale, size: 24),
          const SizedBox(width: 8),
          const Text('Pelaris.id'),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                0,
                Icons.inventory_2_outlined,
                Icons.inventory_2,
                'Produk',
              ),
              _buildNavItem(
                1,
                Icons.receipt_long_outlined,
                Icons.receipt_long,
                'Transaksi',
              ),
              _buildNavItem(
                2,
                Icons.settings_outlined,
                Icons.settings,
                'Pengaturan',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // POS Tab (main product view)
  Widget _buildPosTab() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildNarrowLayout(),
      resizeToAvoidBottomInset: false,
    );
  }

  // Layout untuk layar lebar (tablet/desktop)
  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildSearchBar(),
              const CategoryTabs(),
              const Expanded(child: ProductList()),
            ],
          ),
        ),
        Container(
          width: 380,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(left: BorderSide(color: AppColors.border)),
          ),
          child: const CartPanel(),
        ),
      ],
    );
  }

  // Layout untuk layar sempit (phone)
  Widget _buildNarrowLayout() {
    return Column(
      children: [
        _buildSearchBar(),
        const CategoryTabs(),
        Expanded(
          child: Stack(
            children: [
              const ProductList(),
              // Cart FAB
              Positioned(
                right: 16,
                bottom: 16,
                child: Consumer<CartProvider>(
                  builder: (context, cart, _) {
                    if (cart.isEmpty) return const SizedBox.shrink();
                    return FloatingActionButton.extended(
                      onPressed: () => _showCartBottomSheet(context),
                      backgroundColor: AppColors.primary,
                      icon: Badge(
                        label: Text('${cart.itemCount}'),
                        isLabelVisible: cart.itemCount > 0,
                        child: const Icon(Icons.shopping_cart),
                      ),
                      label: Text(_formatCurrency(cart.total)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: AppColors.surface,
      child: Consumer<ProductProvider>(
        builder: (context, productProvider, _) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: productProvider.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Cari produk atau scan QR Code...',
                hintStyle: TextStyle(
                  color: AppColors.textLight.withValues(alpha: 0.7),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textLight.withValues(alpha: 0.6),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        color: AppColors.textLight,
                        onPressed: () {
                          _searchController.clear();
                          productProvider.setSearchQuery('');
                        },
                      )
                    : _buildScannerButton(),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScannerButton() {
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openQRScanner,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openQRScanner() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerScreen()),
    );

    if (scannedCode == null || !mounted) return;

    // Search product by SKU
    final productProvider = context.read<ProductProvider>();
    final cartProvider = context.read<CartProvider>();
    final authProvider = context.read<AuthProvider>();

    final cabangId = authProvider.cabangId;
    if (cabangId == null) {
      _showSnackBar('Error: Cabang tidak ditemukan', isError: true);
      return;
    }

    // Find product variant by SKU in loaded products
    for (final product in productProvider.products) {
      for (final variant in product.variants) {
        if (variant.sku.toLowerCase() == scannedCode.toLowerCase()) {
          // Found the product, add to cart
          cartProvider.addFromVariant(product, variant, cabangId);
          _showSnackBar(
            '${product.name} - ${variant.variantValue} ditambahkan ke keranjang',
          );
          return;
        }
      }
    }

    // Try to search via API if not found locally
    final product = await productProvider.searchBySku(scannedCode);
    if (product != null && product.variants.isNotEmpty) {
      final variant = product.variants.first;
      cartProvider.addFromVariant(product, variant, cabangId);
      _showSnackBar(
        '${product.name} - ${variant.variantValue} ditambahkan ke keranjang',
      );
    } else {
      _showSnackBar(
        'Produk dengan SKU "$scannedCode" tidak ditemukan',
        isError: true,
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showCartBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const CartPanel(isBottomSheet: true),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) => CurrencyFormatter.format(amount);
}
