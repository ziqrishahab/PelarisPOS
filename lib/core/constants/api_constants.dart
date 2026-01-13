class ApiConstants {
  // Base URL - Production API (VPS)
  static const String baseUrl = 'https://api-pelaris.ziqrishahab.com/api';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';
  static const String users = '/auth/users';

  // Products endpoints
  static const String products = '/products';
  static const String categories = '/products/categories';

  // Cabang endpoints
  static const String cabang = '/cabang';

  // Transactions endpoints
  static const String transactions = '/transactions';
  static const String transactionStats = '/transactions/stats';
  static const String dailySales = '/transactions/daily-sales';

  // Stock endpoints
  static const String stock = '/stock';
  static const String stockAdjustment = '/stock/adjustment';
  static const String stockAlerts = '/stock/alerts';

  // Returns endpoints
  static const String returns = '/returns';

  // Settings endpoints
  static const String settings = '/settings';
  static const String printerSettings = '/settings/printer';

  // Channels endpoints
  static const String channels = '/channels';

  // Sync endpoints
  static const String sync = '/sync';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
