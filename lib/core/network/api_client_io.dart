import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

http.Client createDefaultHttpClient() {
  final io = HttpClient();
  io.badCertificateCallback = (cert, host, port) {
    final h = host.toLowerCase();
    return h == 'localhost' ||
        h == '10.0.2.2' ||
        h.startsWith('127.') ||
        h.startsWith('192.168.');
  };
  return IOClient(io);
}
