import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/services/auth_service.dart';
import '../data/api/api_client.dart';
import '../core/services/sentry_service.dart';
import '../core/services/socket_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  late final AuthRepository _authRepository;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  // For OWNER/MANAGER - selected cabang for POS operations
  Cabang? _selectedCabang;
  List<Cabang> _cabangList = [];

  AuthProvider(this._authService) {
    final apiClient = ApiClient.getInstance(_authService);
    _authRepository = AuthRepository(apiClient);
  }

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // Get cabangId - for OWNER/MANAGER use selected cabang, otherwise use user's cabang
  String? get cabangId {
    if (_user?.isOwnerOrManager == true) {
      return _selectedCabang?.id;
    }
    return _user?.cabang?.id;
  }

  // Get current cabang (for display)
  Cabang? get currentCabang {
    if (_user?.isOwnerOrManager == true) {
      return _selectedCabang;
    }
    return _user?.cabang;
  }

  List<Cabang> get cabangList => _cabangList;
  bool get canSelectCabang => _user?.isOwnerOrManager == true;

  // Initialize - check stored auth
  Future<void> init() async {
    await _authService.init();

    if (_authService.isLoggedIn) {
      _user = _authService.currentUser;
      _status = AuthStatus.authenticated;

      // Initialize socket with stored token
      final token = await _authService.getToken();
      if (token != null) {
        SocketService().setAuthToken(token);
        SocketService().connect();
      }

      // Fetch cabang list for OWNER/MANAGER on init
      if (_user?.isOwnerOrManager == true) {
        await fetchCabangList();

        // Restore previously selected cabang
        final savedCabangId = _authService.selectedCabangId;
        if (savedCabangId != null && _cabangList.isNotEmpty) {
          final savedCabang = _cabangList
              .where((c) => c.id == savedCabangId)
              .firstOrNull;
          if (savedCabang != null) {
            _selectedCabang = savedCabang;
            debugPrint('[AUTH] Restored selected cabang: ${savedCabang.name}');
          }
        }
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // Login
  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authRepository.login(email, password);

      // Check if user has cabang assigned (required for POS)
      if (response.user.cabang == null &&
          response.user.role != 'OWNER' &&
          response.user.role != 'ADMIN') {
        _status = AuthStatus.error;
        _errorMessage = 'Akun Anda belum ditugaskan ke cabang. Hubungi admin.';
        notifyListeners();
        return false;
      }

      await _authService.saveAuth(response.token, response.user);
      _user = response.user;
      _status = AuthStatus.authenticated;

      // Initialize socket connection with auth token
      SocketService().setAuthToken(response.token);
      SocketService().connect();

      // Set Sentry user context
      SentryService.setUser(
        id: response.user.id,
        email: response.user.email,
        name: response.user.name,
        role: response.user.role,
        cabangId: response.user.cabangId,
      );
      SentryService.addBreadcrumb(
        message: 'User logged in',
        category: 'auth',
        data: {'email': response.user.email, 'role': response.user.role},
      );

      // Fetch cabang list for OWNER/MANAGER after login
      if (_user?.isOwnerOrManager == true) {
        debugPrint('[AUTH] Fetching cabang list for Owner/Manager...');
        await fetchCabangList();
        debugPrint('[AUTH] Cabang list fetched: ${_cabangList.length} items');
      }

      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      SentryService.captureException(e, context: 'auth_login');
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } finally {
      // Disconnect socket on logout
      SocketService().setAuthToken(null);
      SocketService().disconnect();

      await _authService.logout();
      _user = null;
      _selectedCabang = null;
      _cabangList = [];
      _status = AuthStatus.unauthenticated;
      SentryService.clearUser();
      SentryService.addBreadcrumb(message: 'User logged out', category: 'auth');
      notifyListeners();
    }
  }

  // Refresh user data
  Future<void> refreshUser() async {
    try {
      final user = await _authRepository.getCurrentUser();
      await _authService.updateUser(user);
      _user = user;
      notifyListeners();
    } catch (e) {
      // Ignore errors
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Fetch cabang list for OWNER/MANAGER
  Future<void> fetchCabangList() async {
    if (!(_user?.isOwnerOrManager == true)) {
      debugPrint('[AUTH] fetchCabangList: User is not Owner/Manager, skipping');
      return;
    }

    try {
      debugPrint('[AUTH] fetchCabangList: Fetching from API...');
      final list = await _authRepository.getCabangList();
      _cabangList = list;
      debugPrint('[AUTH] fetchCabangList: Success, got ${list.length} cabangs');
      // Don't auto-select - let user choose via modal
      notifyListeners();
    } catch (e) {
      debugPrint('[AUTH] fetchCabangList: Error - $e');
      SentryService.captureException(e, context: 'fetch_cabang_list');
      // Re-throw so caller knows it failed
      rethrow;
    }
  }

  // Select cabang for POS operations (OWNER/MANAGER only)
  void selectCabang(Cabang cabang) {
    if (_user?.isOwnerOrManager == true) {
      _selectedCabang = cabang;
      // Persist the selection
      _authService.saveSelectedCabangId(cabang.id);
      debugPrint('[AUTH] Selected and saved cabang: ${cabang.name}');
      notifyListeners();
    }
  }
}
