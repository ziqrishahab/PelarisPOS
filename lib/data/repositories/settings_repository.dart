import '../api/api_client.dart';
import '../models/printer_settings_model.dart';

class SettingsRepository {
  final ApiClient _apiClient;

  SettingsRepository(this._apiClient);

  /// Fetch printer settings from API
  Future<PrinterSettings> getPrinterSettings(String cabangId) async {
    try {
      final response = await _apiClient.get(
        '/settings/printer',
        queryParameters: {'cabangId': cabangId},
      );
      return PrinterSettings.fromJson(response.data);
    } catch (e) {
      // Return default settings if API fails
      return PrinterSettings.defaultSettings();
    }
  }

  /// Update printer settings on API
  Future<PrinterSettings> updatePrinterSettings(
    PrinterSettings settings,
  ) async {
    final response = await _apiClient.put(
      '/settings/printer',
      data: settings.toJson(),
    );
    return PrinterSettings.fromJson(response.data);
  }
}
