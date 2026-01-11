import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/models.dart';

/// Print Service untuk Thermal Printer (Bluetooth only)
/// Layout mengikuti template dari Pelaris.id project
class PrintService {
  static final PrintService _instance = PrintService._internal();
  factory PrintService() => _instance;
  PrintService._internal();

  BluetoothInfo? _connectedDevice;
  static const String _prefsKey = 'saved_bluetooth_printer';

  /// Get connected device
  BluetoothInfo? get connectedDevice => _connectedDevice;

  /// Get connection status text
  String get connectionStatusText {
    if (_connectedDevice != null) {
      return _connectedDevice!.name;
    }
    return 'Tidak terhubung';
  }

  /// Check if bluetooth is available
  Future<bool> isBluetoothAvailable() async {
    return await PrintBluetoothThermal.bluetoothEnabled;
  }

  /// Get paired devices
  Future<List<BluetoothInfo>> getPairedDevices() async {
    return await PrintBluetoothThermal.pairedBluetooths;
  }

  /// Connect to printer
  Future<bool> connect(BluetoothInfo device) async {
    await disconnect();
    final result = await PrintBluetoothThermal.connect(
      macPrinterAddress: device.macAdress,
    );
    if (result) {
      _connectedDevice = device;
      await _savePrinter(device);
    }
    return result;
  }

  /// Disconnect from printer
  Future<void> disconnect() async {
    await PrintBluetoothThermal.disconnect;
    _connectedDevice = null;
  }

  /// Check connection status
  Future<bool> get isConnected async {
    return await PrintBluetoothThermal.connectionStatus;
  }

  /// Save printer to preferences
  Future<void> _savePrinter(BluetoothInfo device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({'name': device.name, 'mac': device.macAdress}),
    );
  }

  /// Reconnect to saved printer
  Future<bool> reconnectSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == null) return false;

    try {
      final json = jsonDecode(saved);
      final devices = await getPairedDevices();

      for (final device in devices) {
        if (device.macAdress == json['mac']) {
          return await connect(device);
        }
      }
    } catch (e) {
      // Ignore
    }
    return false;
  }

  /// Print receipt
  Future<bool> printReceipt(PrintReceiptData data) async {
    if (!await isConnected) {
      throw Exception('Printer tidak terhubung');
    }

    final int charWidth = data.paperWidth == 58 ? 32 : 48;

    // Helper: Left-right alignment
    String leftRight(String left, String right) {
      final spaces = (charWidth - left.length - right.length).clamp(
        1,
        charWidth,
      );
      return left + ' ' * spaces + right;
    }

    // Helper: Line separator
    String line([String char = '-']) => char * charWidth;

    // Helper: Wrap text for long strings
    List<String> wrapText(String text, int maxWidth) {
      if (text.length <= maxWidth) return [text];

      final List<String> lines = [];
      int start = 0;

      while (start < text.length) {
        int end = start + maxWidth;
        if (end >= text.length) {
          lines.add(text.substring(start));
          break;
        }

        // Try to break at space
        int lastSpace = text.lastIndexOf(' ', end);
        if (lastSpace > start) {
          end = lastSpace;
        }

        lines.add(text.substring(start, end));
        start = end + (lastSpace > start ? 1 : 0);
      }

      return lines;
    }

    // Helper: Format currency
    String formatCurrency(double amount) {
      return 'Rp ${NumberFormat('#,###', 'id_ID').format(amount.toInt())}';
    }

    // Helper: Format date
    String formatDate(DateTime d) {
      return DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(d);
    }

    List<int> bytes = [];

    // Initialize printer
    bytes += [0x1B, 0x40];

    // ============ HEADER ============
    bytes += [0x1B, 0x61, 0x01]; // Center

    // Store name - Double size bold
    bytes += [0x1B, 0x21, 0x30];
    bytes += _textToBytes('${data.storeName}\n');
    bytes += [0x1B, 0x21, 0x00];

    if (data.branchName != null && data.branchName!.isNotEmpty) {
      bytes += _textToBytes('${data.branchName}\n');
    }

    if (data.address != null && data.address!.isNotEmpty) {
      final addressLines = wrapText(data.address!, charWidth);
      for (final ln in addressLines) {
        bytes += _textToBytes('$ln\n');
      }
    }

    if (data.phone != null && data.phone!.isNotEmpty) {
      bytes += _textToBytes('Telp: ${data.phone}\n');
    }

    bytes += _textToBytes('${line('=')}\n'); // === separator after header
    bytes += [0x1B, 0x61, 0x00]; // Left

    // ============ TRANSACTION INFO ============
    bytes += _textToBytes('Nomor   : ${data.transactionNo}\n');
    bytes += _textToBytes('Tanggal : ${formatDate(data.date)}\n');

    if (data.cashierName != null && data.cashierName!.isNotEmpty) {
      bytes += _textToBytes('Kasir   : ${data.cashierName}\n');
    }

    if (data.customerName != null && data.customerName!.isNotEmpty) {
      bytes += _textToBytes('Pelanggan: ${data.customerName}\n');
    }

    bytes += _textToBytes('${line()}\n'); // --- separator

    // ============ ITEMS ============
    for (final item in data.items) {
      // Item name (without variant)
      final wrappedNames = wrapText(item.name, charWidth);
      for (final ln in wrappedNames) {
        bytes += _textToBytes('$ln\n');
      }

      // Variant info on separate line (indented)
      if (item.variant != null && item.variant!.isNotEmpty) {
        final variantText = '  ${item.variant}'; // Indented with 2 spaces
        final wrappedVariant = wrapText(variantText, charWidth);
        for (final ln in wrappedVariant) {
          bytes += _textToBytes('$ln\n');
        }
      }

      // Qty x Price = Subtotal (dengan format yang sama seperti Pelaris.id)
      bytes += _textToBytes(
        '${leftRight('${item.qty} x ${formatCurrency(item.price)}', formatCurrency(item.subtotal))}\n',
      );
    }

    bytes += _textToBytes('${line()}\n'); // --- separator

    // ============ SUBTOTAL ============
    bytes += _textToBytes(
      '${leftRight('Subtotal', formatCurrency(data.subtotal))}\n',
    );

    if (data.discount > 0) {
      String discountLabel = 'Diskon';
      if (data.discountType == 'PERCENTAGE' && data.discountValue != null) {
        discountLabel += ' (${data.discountValue!.toInt()}%)';
      }
      bytes += _textToBytes(
        '${leftRight(discountLabel, '-${formatCurrency(data.discount)}')}\n',
      );
    }

    if (data.tax > 0) {
      bytes += _textToBytes(
        '${leftRight('Pajak', formatCurrency(data.tax))}\n',
      );
    }

    bytes += _textToBytes('${line()}\n'); // --- separator

    // ============ GRAND TOTAL ============
    bytes += [0x1B, 0x21, 0x08]; // Bold
    bytes += _textToBytes(
      '${leftRight('GRAND TOTAL', formatCurrency(data.total))}\n',
    );
    bytes += [0x1B, 0x21, 0x00]; // Normal

    // Payment method (langsung setelah grand total, tanpa separator)
    String paymentLabel = data.paymentMethod;
    if (data.isSplitPayment && data.paymentMethod2 != null) {
      bytes += _textToBytes(
        '${leftRight('Bayar 1 ($paymentLabel)', formatCurrency(data.paymentAmount1 ?? data.total))}\n',
      );
      bytes += _textToBytes(
        '${leftRight('Bayar 2 (${data.paymentMethod2})', formatCurrency(data.paymentAmount2 ?? 0))}\n',
      );
    } else {
      bytes += _textToBytes(
        '${leftRight('Bayar ($paymentLabel)', formatCurrency(data.cashReceived ?? data.total))}\n',
      );
    }

    // Change for cash payment
    if ((data.paymentMethod.toUpperCase() == 'CASH' ||
            data.paymentMethod.toUpperCase() == 'TUNAI') &&
        data.change != null &&
        data.change! > 0) {
      bytes += _textToBytes(
        '${leftRight('Kembali', formatCurrency(data.change!))}\n',
      );
    }

    bytes += _textToBytes('${line('=')}\n'); // === separator before footer

    // ============ FOOTER ============
    bytes += [0x1B, 0x61, 0x01]; // Center align
    bytes += _textToBytes('\n');

    if (data.footerText1 != null && data.footerText1!.isNotEmpty) {
      bytes += _textToBytes('${data.footerText1}\n');
    }

    // Footer note - wrap text untuk pesan panjang
    if (data.footerNote != null && data.footerNote!.isNotEmpty) {
      bytes += _textToBytes('\n');
      final noteLines = wrapText(data.footerNote!, charWidth);
      for (final ln in noteLines) {
        bytes += _textToBytes('$ln\n');
      }
    }

    bytes += [0x1B, 0x61, 0x00]; // Left align
    bytes += _textToBytes('\n\n\n');
    bytes += [0x1D, 0x56, 0x00]; // Cut paper

    return await PrintBluetoothThermal.writeBytes(bytes);
  }

  List<int> _textToBytes(String text) => text.codeUnits;

  /// Print test page
  Future<bool> printTestPage() async {
    if (!await isConnected) {
      throw Exception('Printer tidak terhubung');
    }

    List<int> bytes = [];
    bytes += [0x1B, 0x40];
    bytes += [0x1B, 0x61, 0x01];
    bytes += [0x1B, 0x21, 0x30];
    bytes += _textToBytes('TEST PRINT\n');
    bytes += [0x1B, 0x21, 0x00];
    bytes += _textToBytes('--------------------------------\n');
    bytes += _textToBytes('Pelaris.id\n');
    bytes += _textToBytes('Printer OK!\n');
    bytes += _textToBytes('Device: ${_connectedDevice?.name ?? "-"}\n');
    bytes += _textToBytes('--------------------------------\n');
    bytes += _textToBytes(
      '${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}\n',
    );
    bytes += _textToBytes('\n\n\n');

    return await PrintBluetoothThermal.writeBytes(bytes);
  }

  /// Open cash drawer
  Future<bool> openCashDrawer() async {
    if (!await isConnected) {
      throw Exception('Printer tidak terhubung');
    }
    return await PrintBluetoothThermal.writeBytes([
      0x1B,
      0x70,
      0x00,
      0x19,
      0xFA,
    ]);
  }
}

/// Data model for print receipt
class PrintReceiptData {
  final String storeName;
  final String? branchName;
  final String? address;
  final String? phone;
  final String? cashierName;
  final String transactionNo;
  final List<PrintReceiptItem> items;
  final double subtotal;
  final double discount;
  final String? discountType;
  final double? discountValue;
  final double tax;
  final double total;
  final String paymentMethod;
  final double? cashReceived;
  final double? change;
  final bool isSplitPayment;
  final double? paymentAmount1;
  final String? paymentMethod2;
  final double? paymentAmount2;
  final String? customerName;
  final String? customerPhone;
  final DateTime date;
  final int paperWidth;
  final String? footerText1;
  final String? footerNote;

  PrintReceiptData({
    required this.storeName,
    this.branchName,
    this.address,
    this.phone,
    this.cashierName,
    required this.transactionNo,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    this.discountType,
    this.discountValue,
    this.tax = 0,
    required this.total,
    required this.paymentMethod,
    this.cashReceived,
    this.change,
    this.isSplitPayment = false,
    this.paymentAmount1,
    this.paymentMethod2,
    this.paymentAmount2,
    this.customerName,
    this.customerPhone,
    required this.date,
    this.paperWidth = 58,
    this.footerText1 = 'Terima Kasih.',
    this.footerNote =
        'Simpan struk baik-baik untuk penukaran barang. Jika struk hilang, barang dicuci, atau label dicoret, garansi tukar tidak berlaku.',
  });

  factory PrintReceiptData.fromTransaction({
    required Transaction transaction,
    required String storeName,
    String? branchName,
    String? address,
    String? phone,
    String? cashierName,
    double? cashReceived,
    int paperWidth = 58,
    String? footerText1,
    String? footerNote,
  }) {
    return PrintReceiptData(
      storeName: storeName,
      branchName: branchName,
      address: address,
      phone: phone,
      cashierName: cashierName,
      transactionNo: transaction.transactionNo,
      items: transaction.items
          .map(
            (item) => PrintReceiptItem(
              name: item.productName,
              variant: item.variantInfo,
              qty: item.quantity,
              price: item.price,
              subtotal: item.subtotal,
            ),
          )
          .toList(),
      subtotal: transaction.subtotal,
      discount: transaction.discount,
      tax: transaction.tax,
      total: transaction.total,
      paymentMethod: transaction.paymentMethod.name.toUpperCase(),
      cashReceived: cashReceived,
      change: cashReceived != null ? cashReceived - transaction.total : null,
      isSplitPayment: transaction.isSplitPayment,
      paymentAmount1: transaction.paymentAmount1,
      paymentMethod2: transaction.paymentMethod2?.name.toUpperCase(),
      paymentAmount2: transaction.paymentAmount2,
      customerName: transaction.customerName,
      customerPhone: transaction.customerPhone,
      date: transaction.createdAt,
      paperWidth: paperWidth,
      footerText1: footerText1 ?? 'Terima Kasih.',
      footerNote:
          footerNote ??
          'Simpan struk baik-baik untuk penukaran barang. Jika struk hilang, barang dicuci, atau label dicoret, garansi tukar tidak berlaku.',
    );
  }
}

class PrintReceiptItem {
  final String name;
  final String? variant;
  final int qty;
  final double price;
  final double subtotal;

  PrintReceiptItem({
    required this.name,
    this.variant,
    required this.qty,
    required this.price,
    required this.subtotal,
  });
}
