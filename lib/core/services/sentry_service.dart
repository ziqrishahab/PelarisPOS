import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Sentry Error Monitoring Service untuk Pelaris.id
class SentryService {
  static bool _initialized = false;
  static const String _dsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  /// Initialize Sentry - panggil di main() sebelum runApp
  static Future<void> init() async {
    if (_initialized) return;
    if (_dsn.isEmpty) {
      debugPrint(
        '[Sentry] SENTRY_DSN not configured, error monitoring disabled',
      );
      return;
    }

    await SentryFlutter.init((options) {
      options.dsn = _dsn;

      // Environment
      options.environment = kDebugMode ? 'development' : 'production';

      // Sample rates
      options.tracesSampleRate = kDebugMode ? 1.0 : 0.2;
      options.profilesSampleRate = kDebugMode ? 1.0 : 0.1;

      // Auto session tracking
      options.autoSessionTrackingInterval = const Duration(milliseconds: 30000);

      // Attach screenshots for errors (optional)
      options.attachScreenshot = true;

      // Debug mode
      options.debug = kDebugMode;

      // Filter sensitive data
      options.beforeSend = (event, hint) {
        // Filter out network errors yang expected
        if (event.throwable != null) {
          final message = event.throwable.toString().toLowerCase();
          if (message.contains('socketexception') ||
              message.contains('connection refused') ||
              message.contains('host lookup')) {
            // Tetap kirim tapi dengan level warning
            return event.copyWith(level: SentryLevel.warning);
          }
        }
        return event;
      };
    });

    _initialized = true;
    debugPrint('[Sentry] Initialized successfully');
  }

  /// Capture exception dengan context
  static Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    String? context,
    Map<String, dynamic>? extras,
  }) async {
    if (!_initialized) {
      debugPrint('[Sentry] Not initialized, skipping: $exception');
      return;
    }

    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (context != null) {
          scope.setTag('context', context);
        }
        if (extras != null) {
          scope.setContexts('extras', extras);
        }
      },
    );
  }

  /// Capture message/breadcrumb
  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extras,
  }) async {
    if (!_initialized) return;

    await Sentry.captureMessage(
      message,
      level: level,
      withScope: (scope) {
        if (extras != null) {
          scope.setContexts('extras', extras);
        }
      },
    );
  }

  /// Set user context (setelah login)
  static void setUser({
    required String id,
    required String email,
    String? name,
    String? role,
    String? cabangId,
  }) {
    if (!_initialized) return;

    Sentry.configureScope((scope) {
      scope.setUser(
        SentryUser(
          id: id,
          email: email,
          name: name,
          data: {
            if (role != null) 'role': role,
            if (cabangId != null) 'cabangId': cabangId,
          },
        ),
      );
    });
  }

  /// Clear user context (setelah logout)
  static void clearUser() {
    if (!_initialized) return;

    Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  /// Add breadcrumb untuk tracking user journey
  static void addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
    SentryLevel level = SentryLevel.info,
  }) {
    if (!_initialized) return;

    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        data: data,
        level: level,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Start transaction untuk performance monitoring
  static ISentrySpan? startTransaction({
    required String name,
    required String operation,
  }) {
    if (!_initialized) return null;

    return Sentry.startTransaction(name, operation, bindToScope: true);
  }

  /// Wrap async function dengan error capturing
  static Future<T> wrapAsync<T>({
    required Future<T> Function() operation,
    required String context,
    Map<String, dynamic>? extras,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      await captureException(
        e,
        stackTrace: stackTrace,
        context: context,
        extras: extras,
      );
      rethrow;
    }
  }

  /// Check if Sentry is initialized
  static bool get isInitialized => _initialized;
}
