import 'dart:async';
import 'dart:convert';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WSHub {
  final _clients = <WebSocketChannel>{};

  Handler handler() => webSocketHandler((WebSocketChannel webSocket) {
    _clients.add(webSocket);
    webSocket.stream.listen((message) {
      // ignore incoming messages for now
    }, onDone: () {
      _clients.remove(webSocket);
    });
  });

  void broadcast(String type, Map<String, dynamic> payload) {
    final msg = jsonEncode({'type': type, 'payload': payload});
    for (final c in _clients) {
      try {
        c.sink.add(msg);
      } catch (e) {
        // ignore
      }
    }
  }
}
