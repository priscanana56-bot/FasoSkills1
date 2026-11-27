import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';

/// Real-time channel. It is opened once the user is authenticated (the server
/// identifies the user from the access token) and closed on logout.
/// Dropped connections are re-opened automatically with a growing delay.
class WebSocketClient {
  final SecureStorageService _storage;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  final Set<String> _rooms = {};
  bool _isConnected = false;
  bool _wanted = false;
  Timer? _retryTimer;
  int _retries = 0;

  WebSocketClient({SecureStorageService? storage})
      : _storage = storage ?? SecureStorageService();

  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;
  bool get isConnected => _isConnected;

  /// Events of one type only, e.g. `on('message:received')`.
  Stream<Map<String, dynamic>> on(String event) =>
      eventStream.where((e) => e['event'] == event);

  Future<void> connect() async {
    _wanted = true;
    _retryTimer?.cancel();
    await _close();

    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      final uri = Uri.parse(
          '${AppConfig.wsUrl}?token=${Uri.encodeQueryComponent(token)}');
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      await channel.ready;
      _isConnected = true;
      _retries = 0;
      for (final room in _rooms) {
        _send({'action': 'join_room', 'room': room});
      }
      _subscription = channel.stream.listen(
        (data) {
          try {
            final parsed = jsonDecode(data.toString());
            if (parsed is Map<String, dynamic>) _eventController.add(parsed);
          } catch (_) {}
        },
        onError: (_) => _onDropped(),
        onDone: _onDropped,
        cancelOnError: true,
      );
    } catch (_) {
      _onDropped();
    }
  }

  void _onDropped() {
    _isConnected = false;
    if (!_wanted) return;
    _retryTimer?.cancel();
    final seconds = (2 << _retries.clamp(0, 4)); // 2s, 4s, 8s, 16s, 32s
    _retries++;
    _retryTimer = Timer(Duration(seconds: seconds), connect);
  }

  void _send(Map<String, dynamic> payload) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(payload));
    }
  }

  void joinRoom(String room) {
    _rooms.add(room);
    _send({'action': 'join_room', 'room': room});
  }

  void leaveRoom(String room) {
    _rooms.remove(room);
    _send({'action': 'leave_room', 'room': room});
  }

  Future<void> _close() async {
    _isConnected = false;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  Future<void> disconnect() async {
    _wanted = false;
    _retryTimer?.cancel();
    _rooms.clear();
    await _close();
  }
}
