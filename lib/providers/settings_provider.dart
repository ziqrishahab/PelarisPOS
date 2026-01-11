import 'package:flutter/foundation.dart';
import '../data/models/printer_settings_model.dart';
import '../data/repositories/settings_repository.dart';

class SettingsProvider with ChangeNotifier {
  final SettingsRepository _repository;

  PrinterSettings _printerSettings = PrinterSettings.defaultSettings();
  bool _isLoading = false;
  String? _error;

  SettingsProvider(this._repository);

  PrinterSettings get printerSettings => _printerSettings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Convenience getters for receipt
  String get storeName => _printerSettings.storeName;
  String? get branchName => _printerSettings.branchName;
  String? get address => _printerSettings.address;
  String? get phone => _printerSettings.phone;
  String? get footerText1 => _printerSettings.footerText1;
  String? get footerText2 => _printerSettings.footerText2;
  bool get autoPrintEnabled => _printerSettings.autoPrintEnabled;
  int get paperWidth => _printerSettings.paperWidth;

  /// Fetch printer settings from API
  Future<void> fetchPrinterSettings(String cabangId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _printerSettings = await _repository.getPrinterSettings(cabangId);
    } catch (e) {
      _error = e.toString();
      // Keep default settings on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh settings (call after login or when needed)
  Future<void> refresh(String cabangId) async {
    await fetchPrinterSettings(cabangId);
  }
}
