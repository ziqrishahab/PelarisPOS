import 'package:flutter_test/flutter_test.dart';
import 'package:pelaris/providers/settings_provider.dart';
import 'package:pelaris/data/models/printer_settings_model.dart';
import 'package:pelaris/data/repositories/settings_repository.dart';

class MockSettingsRepository implements SettingsRepository {
  bool shouldFail = false;
  PrinterSettings? mockSettings;

  @override
  Future<PrinterSettings> getPrinterSettings(String cabangId) async {
    await Future.delayed(const Duration(milliseconds: 10));

    if (shouldFail) {
      throw Exception('Failed to fetch printer settings');
    }

    return mockSettings ??
        PrinterSettings(
          id: '1',
          cabangId: cabangId,
          storeName: 'Test Store',
          branchName: 'Test Branch',
          address: 'Test Address',
          phone: '081234567890',
          paperWidth: 80,
          autoPrintEnabled: true,
          footerText1: 'Thank you',
          footerText2: 'Come again',
        );
  }

  @override
  Future<PrinterSettings> updatePrinterSettings(
    PrinterSettings settings,
  ) async {
    await Future.delayed(const Duration(milliseconds: 10));

    if (shouldFail) {
      throw Exception('Failed to update printer settings');
    }

    return settings;
  }
}

void main() {
  group('SettingsProvider Tests', () {
    late SettingsProvider provider;
    late MockSettingsRepository mockRepository;

    setUp(() {
      mockRepository = MockSettingsRepository();
      provider = SettingsProvider(mockRepository);
    });

    test('initial state is correct', () {
      expect(provider.printerSettings, isA<PrinterSettings>());
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.storeName, 'Pelaris.id');
      expect(provider.paperWidth, 80);
      expect(provider.autoPrintEnabled, true);
    });

    test('fetchPrinterSettings success updates state correctly', () async {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      final future = provider.fetchPrinterSettings('test-cabang-id');

      expect(provider.isLoading, true);
      expect(notifyCount, 1);

      await future;

      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.storeName, 'Test Store');
      expect(provider.branchName, 'Test Branch');
      expect(provider.address, 'Test Address');
      expect(provider.phone, '081234567890');
      expect(provider.footerText1, 'Thank you');
      expect(provider.footerText2, 'Come again');
      expect(notifyCount, 2);
    });

    test('fetchPrinterSettings failure keeps default settings', () async {
      mockRepository.shouldFail = true;
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.fetchPrinterSettings('test-cabang-id');

      expect(provider.isLoading, false);
      expect(provider.error, isNotNull);
      expect(provider.error, contains('Failed to fetch'));
      expect(provider.storeName, 'Pelaris.id');
      expect(notifyCount, 2);
    });

    test('refresh calls fetchPrinterSettings', () async {
      mockRepository.mockSettings = PrinterSettings(
        id: '2',
        cabangId: 'refresh-test',
        storeName: 'Refreshed Store',
        paperWidth: 58,
        autoPrintEnabled: false,
      );

      await provider.refresh('refresh-test');

      expect(provider.storeName, 'Refreshed Store');
      expect(provider.paperWidth, 58);
      expect(provider.autoPrintEnabled, false);
    });

    test('convenience getters return correct values', () async {
      mockRepository.mockSettings = PrinterSettings(
        id: '3',
        cabangId: 'getter-test',
        storeName: 'Getter Store',
        branchName: 'Branch A',
        address: '123 Street',
        phone: '08999999999',
        footerText1: 'Footer 1',
        footerText2: 'Footer 2',
        paperWidth: 58,
        autoPrintEnabled: false,
      );

      await provider.fetchPrinterSettings('getter-test');

      expect(provider.storeName, 'Getter Store');
      expect(provider.branchName, 'Branch A');
      expect(provider.address, '123 Street');
      expect(provider.phone, '08999999999');
      expect(provider.footerText1, 'Footer 1');
      expect(provider.footerText2, 'Footer 2');
      expect(provider.paperWidth, 58);
      expect(provider.autoPrintEnabled, false);
    });

    test('multiple fetches handle state correctly', () async {
      await provider.fetchPrinterSettings('first');
      expect(provider.storeName, 'Test Store');

      mockRepository.mockSettings = PrinterSettings(
        id: '4',
        storeName: 'Second Store',
      );

      await provider.fetchPrinterSettings('second');
      expect(provider.storeName, 'Second Store');
    });

    test('listeners are notified on state change', () async {
      var listenerCallCount = 0;
      provider.addListener(() => listenerCallCount++);

      await provider.fetchPrinterSettings('listener-test');

      expect(listenerCallCount, greaterThanOrEqualTo(2));
    });
  });
}
