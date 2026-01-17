import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;
  String? _authToken;

  // Socket.io server URL - configurable via --dart-define=SOCKET_URL=...
  // Production: https://api-pelaris.ziqrishahab.com
  // Dev: http://localhost:5100
  static const String _serverUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'https://api-pelaris.ziqrishahab.com',
  );

  bool get isConnected => _isConnected;

  /// Set authentication token (call this after login)
  void setAuthToken(String? token) {
    _authToken = token;
    // If already connected, reconnect with new token
    if (_socket != null && token != null) {
      print('[Socket] Auth token updated, reconnecting...');
      disconnect();
      connect();
    }
  }

  /// Initialize and connect to socket with authentication
  void connect() {
    if (_socket != null && _socket!.connected) {
      print('[Socket] Already connected');
      return;
    }

    // Require auth token for connection
    if (_authToken == null || _authToken!.isEmpty) {
      print('[Socket] No auth token available, skipping socket connection');
      return;
    }

    _socket = io.io(_serverUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 5000,
      'timeout': 10000,
      // Send authentication token
      'auth': {'token': _authToken},
    });

    _socket!.onConnect((_) {
      _isConnected = true;
      print('[Socket] Connected to server (authenticated)');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      print('[Socket] Disconnected from server');
    });

    _socket!.onConnectError((error) {
      final errorMsg = error.toString();
      print('[Socket] Connection error: $errorMsg');

      // Check if authentication error
      if (errorMsg.contains('Authentication required') ||
          errorMsg.contains('Invalid or expired token')) {
        print('[Socket] Authentication failed, disconnecting...');
        disconnect();
      }
    });

    _socket!.onError((error) {
      print('[Socket] Socket error: $error');
    });
  }

  // Subscribe to stock updates
  void onStockUpdate(Function(dynamic) callback) {
    _socket?.on('stock:updated', callback);
  }

  // Subscribe to product created
  void onProductCreated(Function(dynamic) callback) {
    _socket?.on('product:created', callback);
  }

  // Subscribe to product updated
  void onProductUpdated(Function(dynamic) callback) {
    _socket?.on('product:updated', callback);
  }

  // Subscribe to product deleted
  void onProductDeleted(Function(dynamic) callback) {
    _socket?.on('product:deleted', callback);
  }

  // Subscribe to category updated
  void onCategoryUpdated(Function(dynamic) callback) {
    _socket?.on('category:updated', callback);
  }

  // Subscribe to sync trigger
  void onSyncTrigger(Function(dynamic) callback) {
    _socket?.on('sync:trigger', callback);
  }

  // Unsubscribe from event
  void off(String event) {
    _socket?.off(event);
  }

  // Disconnect socket
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      print('[Socket] Disconnected and cleaned up');
    }
  }

  // Dispose (untuk cleanup saat app close)
  void dispose() {
    _authToken = null;
    disconnect();
  }
}
