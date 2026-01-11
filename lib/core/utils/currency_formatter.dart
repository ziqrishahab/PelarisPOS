/// Currency formatting utilities for Indonesian Rupiah
class CurrencyFormatter {
  /// Format a double value to Indonesian Rupiah format
  /// Example: 150000.0 -> "Rp 150.000"
  static String format(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }

  /// Format without "Rp" prefix
  /// Example: 150000.0 -> "150.000"
  static String formatCompact(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  /// Parse formatted currency back to double
  /// Example: "Rp 150.000" -> 150000.0
  static double parse(String formatted) {
    final cleaned = formatted
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(' ', '')
        .trim();
    return double.tryParse(cleaned) ?? 0;
  }
}
