import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;

  // Socket.io server URL
  static const String _serverUrl = 'https://api-pelaris.ziqrishahab.com';

  bool get isConnected => _isConnected;

  // Initialize and connect to socket
  void connect() {
    if (_socket != null && _socket!.connected) {
      print('[Socket] Already connected');
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
    });

    _socket!.onConnect((_) {
      _isConnected = true;
      print('[Socket] Connected to server');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      print('[Socket] Disconnected from server');
    });

    _socket!.onConnectError((error) {
      print('[Socket] Connection error: $error');
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
      _socket = null;
      _isConnected = false;
      print('[Socket] Disconnected and cleaned up');
    }
  }

  // Dispose (untuk cleanup saat app close)
  void dispose() {
    disconnect();
  }
}
