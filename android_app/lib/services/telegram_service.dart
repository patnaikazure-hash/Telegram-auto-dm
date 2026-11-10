import 'dart:convert';
import 'package:http/http.dart' as http;

/// TelegramService communicates with a lightweight Python backend
/// (server.py) that wraps Telethon. The Flutter app is the UI;
/// the backend handles the actual Telegram MTProto session.
///
/// For local use: run server.py on your machine, set baseUrl to your IP.
/// For production: deploy server.py to a VPS/cloud and set baseUrl there.

class TelegramService {
  final int apiId;
  final String apiHash;
  final String session;

  // Change this to your backend URL when you deploy server.py
  static const String baseUrl = 'http://127.0.0.1:8000';

  TelegramService({
    required this.apiId,
    required this.apiHash,
    this.session = '',
  });

  Future<Map<String, dynamic>> sendCode(String phone) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/send_code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'api_id': apiId,
          'api_hash': apiHash,
          'phone': phone,
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> signIn({
    required String phone,
    required String phoneCodeHash,
    required String code,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/sign_in'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'api_id': apiId,
          'api_hash': apiHash,
          'phone': phone,
          'phone_code_hash': phoneCodeHash,
          'code': code,
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getDialogs() async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/get_dialogs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'api_id': apiId,
          'api_hash': apiHash,
          'session': session,
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendMessage({
    required dynamic userId,
    required String message,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/send_message'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'api_id': apiId,
          'api_hash': apiHash,
          'session': session,
          'user_id': userId,
          'message': message,
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }
}
