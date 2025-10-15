import 'dart:convert';
import 'package:web_socket_channel/html.dart';

class SocketService {
  final String url;
  late HtmlWebSocketChannel _channel;
  void Function(Map<String,dynamic>)? onMessage;

  SocketService(this.url);

  void connect() {
    _channel = HtmlWebSocketChannel.connect(url);
    _channel.stream.listen((message) {
      final m = jsonDecode(message as String) as Map<String,dynamic>;
      if (onMessage != null) onMessage!(m);
    }, onDone: () {}, onError: (e) {});
  }

  void dispose() {
    _channel.sink.close();
  }
}
