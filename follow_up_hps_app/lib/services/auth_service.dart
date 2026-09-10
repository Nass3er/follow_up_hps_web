import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String _keyHost = 'api_host';
  static const String _keyPort = 'api_port';
  static const String _keyService = 'api_service';
  static const String _keyToken = 'auth_token';
  static const String _keyOfflineToken = 'offline_token';
  static const String _keyCompanyName = 'cached_company_name';
  static const String _keyDeviceSerial = 'device_serial';

  static const String _keyLastUserId = 'last_u_id';
  static const String _keyLastBranchNo = 'last_u_brn';
  static const String _keyLastYear = 'last_u_year';
  static const String _keyLastAct = 'last_u_act';

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString(_keyHost) ?? 'localhost';
    final port = prefs.getString(_keyPort) ?? '80';
    final service = prefs.getString(_keyService) ?? 'hps';
    final portStr = port.isNotEmpty ? ':$port' : '';
    return 'http://$host$portStr/$service/api';
  }

  static Future<void> saveApiConfig(String host, String port, String service) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHost, host);
    await prefs.setString(_keyPort, port);
    await prefs.setString(_keyService, service);
  }

  static Future<Map<String, String>> getApiConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'host': prefs.getString(_keyHost) ?? 'localhost',
      'port': prefs.getString(_keyPort) ?? '80',
      'service': prefs.getString(_keyService) ?? 'hps',
    };
  }

  static Future<String> getDeviceSerial() async {
    final prefs = await SharedPreferences.getInstance();
    String? serial = prefs.getString(_keyDeviceSerial);
    if (serial == null || serial.isEmpty) {
      final randomStr = Random().nextInt(899999 + 100000).toString();
      serial = 'HPS-8C16G-FLUT-$randomStr';
      await prefs.setString(_keyDeviceSerial, serial);
    }
    return serial;
  }

  static Future<void> saveLastCredentials({
    required String userId,
    required String branchNo,
    required String year,
    required String activityNo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastUserId, userId);
    await prefs.setString(_keyLastBranchNo, branchNo);
    await prefs.setString(_keyLastYear, year);
    await prefs.setString(_keyLastAct, activityNo);
  }

  static Future<Map<String, String>> getLastCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString(_keyLastUserId) ?? '',
      'branchNo': prefs.getString(_keyLastBranchNo) ?? '',
      'year': prefs.getString(_keyLastYear) ?? '',
      'activityNo': prefs.getString(_keyLastAct) ?? '',
    };
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyOfflineToken, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken) ?? prefs.getString(_keyOfflineToken);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
  }

  static Future<User?> getCurrentUser() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> json = jsonDecode(decoded);
      return User.fromJson(json, token);
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveCompanyName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCompanyName, name);
  }

  static Future<String> getCompanyName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCompanyName) ?? '🏥 نظام متابعة المرضى (HPS)';
  }
}
