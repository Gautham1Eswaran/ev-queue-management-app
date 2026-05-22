import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../utils/token_manager.dart';

class ApiService {
  static const String baseUrl = 'https://queue-management-geva.onrender.com';

  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (e) {
      if (response.statusCode == 404) {
        throw Exception('Server Error: Route not found (404)');
      }
      throw Exception('Server Error: ${response.body}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Something went wrong');
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    return await post('/login', {'username': username, 'password': password});
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    return await post('/register', userData);
  }

  Future<ChargingSession?> getActiveSession() async {
    try {
      final data = await get('/api/sessions/active');
      if (data == null || data['session'] == null) return null;
      return ChargingSession.fromJson(data['session']);
    } catch (e) {
      return null;
    }
  }

  Future<List<QueueEntry>> getQueueStatus() async {
    try {
      final data = await get('/api/queue/status');
      return (data['queue'] as List).map((e) => QueueEntry.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> startCharging() async {
    await post('/api/sessions/start', {});
  }

  Future<void> joinQueue() async {
    await post('/api/queue/join', {});
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await post('/api/user/update', data);
  }
}
