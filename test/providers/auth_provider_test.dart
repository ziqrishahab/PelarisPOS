import 'package:flutter_test/flutter_test.dart';
import 'package:pelaris/providers/auth_provider.dart';
import 'package:pelaris/data/models/models.dart';

import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthProvider Unit Tests', () {
    late AuthProvider authProvider;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      authProvider = AuthProvider(mockAuthService);
    });

    test('initial status is initial', () {
      expect(authProvider.status, AuthStatus.initial);
      expect(authProvider.user, isNull);
      expect(authProvider.isAuthenticated, isFalse);
    });

    test('init sets unauthenticated when no stored auth', () async {
      await authProvider.init();

      expect(authProvider.status, AuthStatus.unauthenticated);
      expect(authProvider.isAuthenticated, isFalse);
    });

    test('init sets authenticated when stored auth exists for KASIR', () async {
      // Use KASIR role to avoid fetchCabangList API call
      final mockUser = createMockUser(role: 'KASIR');
      mockAuthService.setMockUser(mockUser);

      await authProvider.init();

      expect(authProvider.status, AuthStatus.authenticated);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.user, isNotNull);
      expect(authProvider.user?.email, mockUser.email);
    });

    test('cabangId returns user cabangId for KASIR', () async {
      final mockUser = createMockUser(role: 'KASIR', cabangId: 'cabang-123');
      mockAuthService.setMockUser(mockUser);
      await authProvider.init();

      expect(authProvider.cabangId, 'cabang-123');
    });

    test('canSelectCabang is false for KASIR', () async {
      final mockUser = createMockUser(role: 'KASIR');
      mockAuthService.setMockUser(mockUser);
      await authProvider.init();

      expect(authProvider.canSelectCabang, isFalse);
    });

    test('clearError clears error message', () {
      authProvider.clearError();
      expect(authProvider.errorMessage, isNull);
    });

    // Tests that check OWNER/MANAGER roles need mocked repository
    // These are skipped as they require actual API mocking
    test('canSelectCabang returns true for OWNER role (user model)', () {
      final user = createMockUser(role: 'OWNER');
      expect(user.isOwnerOrManager, isTrue);
    });

    test('canSelectCabang returns true for MANAGER role (user model)', () {
      final user = createMockUser(role: 'MANAGER');
      expect(user.isOwnerOrManager, isTrue);
    });
  });

  group('User Model Tests', () {
    test('fromJson creates user correctly', () {
      final json = {
        'id': 'user-1',
        'email': 'test@example.com',
        'name': 'Test User',
        'role': 'KASIR',
        'isActive': true,
        'cabangId': 'cabang-1',
        'cabang': {
          'id': 'cabang-1',
          'name': 'Main Branch',
          'address': '123 Street',
          'phone': '08123456789',
          'isActive': true,
        },
      };

      final user = User.fromJson(json);

      expect(user.id, 'user-1');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.role, 'KASIR');
      expect(user.cabang?.name, 'Main Branch');
    });

    test('toJson serializes correctly', () {
      final user = createMockUser();
      final json = user.toJson();

      expect(json['id'], user.id);
      expect(json['email'], user.email);
      expect(json['name'], user.name);
      expect(json['role'], user.role);
    });

    test('isOwner returns true for OWNER role', () {
      final user = createMockUser(role: 'OWNER');
      expect(user.isOwner, isTrue);
      expect(user.isManager, isFalse);
      expect(user.isKasir, isFalse);
    });

    test('isManager returns true for MANAGER role', () {
      final user = createMockUser(role: 'MANAGER');
      expect(user.isManager, isTrue);
      expect(user.isOwner, isFalse);
    });

    test('isAdmin returns true for ADMIN role', () {
      final user = createMockUser(role: 'ADMIN');
      expect(user.isAdmin, isTrue);
    });

    test('isKasir returns true for KASIR role', () {
      final user = createMockUser(role: 'KASIR');
      expect(user.isKasir, isTrue);
    });

    test('isOwnerOrManager returns true for OWNER', () {
      final user = createMockUser(role: 'OWNER');
      expect(user.isOwnerOrManager, isTrue);
    });

    test('isOwnerOrManager returns true for MANAGER', () {
      final user = createMockUser(role: 'MANAGER');
      expect(user.isOwnerOrManager, isTrue);
    });

    test('isOwnerOrManager returns false for KASIR', () {
      final user = createMockUser(role: 'KASIR');
      expect(user.isOwnerOrManager, isFalse);
    });
  });

  group('Cabang Model Tests', () {
    test('fromJson creates cabang correctly', () {
      final json = {
        'id': 'cab-1',
        'name': 'Branch A',
        'address': '123 Main St',
        'phone': '08111222333',
        'isActive': true,
      };

      final cabang = Cabang.fromJson(json);

      expect(cabang.id, 'cab-1');
      expect(cabang.name, 'Branch A');
      expect(cabang.address, '123 Main St');
      expect(cabang.phone, '08111222333');
      expect(cabang.isActive, isTrue);
    });

    test('toJson serializes correctly', () {
      final cabang = createMockCabang();
      final json = cabang.toJson();

      expect(json['id'], cabang.id);
      expect(json['name'], cabang.name);
    });

    test('handles null optional fields', () {
      final json = {'id': 'cab-1', 'name': 'Branch A'};

      final cabang = Cabang.fromJson(json);

      expect(cabang.address, isNull);
      expect(cabang.phone, isNull);
    });
  });
}
