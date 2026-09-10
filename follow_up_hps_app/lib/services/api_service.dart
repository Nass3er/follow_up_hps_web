import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/patient.dart';
import '../models/vital_sign.dart';
import '../models/intake_output.dart';
import '../models/doctor_order.dart';

class ApiService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> login({
    required int userId,
    required String password,
    required int branchNo,
    required int financialYear,
    required int activityNo,
    required String deviceId,
  }) async {
    final baseUrl = await AuthService.getBaseUrl();
    final url = Uri.parse('$baseUrl/auth/login');

    final dto = {
      'userId': userId,
      'password': password,
      'branchNo': branchNo,
      'financialYear': financialYear,
      'activityNo': activityNo,
      'deviceId': deviceId,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dto),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await AuthService.saveToken(data['token']);
        }
        return {'success': true, 'data': data, 'statusCode': 200};
      } else if (response.statusCode == 401) {
        String msg = '⚠️ بيانات الدخول غير صحيحة! تأكد من رقم المستخدم وكلمة المرور.';
        try {
          final errData = jsonDecode(response.body);
          if (errData != null && errData['message'] != null) {
            msg = '⚠️ ${errData['message']}';
          }
        } catch (_) {}
        return {'success': false, 'message': msg, 'statusCode': 401};
      } else if (response.statusCode == 402) {
        String msg = 'الترخيص منتهي!';
        try {
          final errData = jsonDecode(response.body);
          if (errData != null && errData['message'] != null) msg = errData['message'];
        } catch (_) {}
        return {'success': false, 'message': '⚠️ $msg', 'statusCode': 402};
      } else if (response.statusCode == 403) {
        String msg = 'جهاز غير مصرح له';
        try {
          final errData = jsonDecode(response.body);
          if (errData != null && errData['message'] != null) msg = errData['message'];
        } catch (_) {}
        return {'success': false, 'message': msg, 'statusCode': 403};
      } else {
        return {'success': false, 'message': '❌ حدث خطأ في السيرفر أو تعذر الاتصال! (رمز: ${response.statusCode})', 'statusCode': response.statusCode};
      }
    } catch (e) {
      return {'success': false, 'message': 'OFFLINE_ERROR', 'statusCode': 0};
    }
  }

  static Future<Map<String, dynamic>> saveAndTestSettings(String host, String port, String service) async {
    await AuthService.saveApiConfig(host, port, service);
    final baseUrl = await AuthService.getBaseUrl();
    final testUrl = Uri.parse('$baseUrl/auth/login');

    try {
      final response = await http.post(
        testUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 500) {
        return {'success': false, 'message': '❌ تم الاتصال بالسيرفر ولكن يوجد خطأ داخلي (500) في السيرفر أو قواعد البيانات!'};
      } else {
        return {'success': true, 'message': '✅ تم الحفظ. الاتصال بالسيرفر جاهز!'};
      }
    } catch (e) {
      return {'success': false, 'message': '❌ تم الحفظ، لكن فشل الاتصال بالسيرفر. يرجى التأكد من البيانات أو تشغيل السيرفر.'};
    }
  }

  static Future<String?> fetchCompanyName() async {
    try {
      final baseUrl = await AuthService.getBaseUrl();
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/company/name'), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['companyName'] != null) {
          await AuthService.saveCompanyName(data['companyName']);
          return data['companyName'];
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<List<Patient>> searchPatients(String query) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/patients/search?q=${Uri.encodeComponent(query)}');
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Patient.fromJson(json)).toList();
    }
    return [];
  }

  static Future<Patient?> getPatientDetails(int docNo) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/patients/$docNo');
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return Patient.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  // --- Vitals API ---
  static Future<List<VitalSign>> getVitalsHistory(int docNo) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/vitals/history/$docNo');
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => VitalSign.fromJson(json)).toList();
    }
    return [];
  }

  static Future<bool> postVitalSign(VitalSign vital) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/vitals');
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(vital.toApiDto()),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // --- Intake & Output API ---
  static Future<List<IntakeOutputRecord>> getIOHistory(int docNo) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/intakeoutput/history/$docNo');
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => IntakeOutputRecord.fromJson(json)).toList();
    }
    return [];
  }

  static Future<bool> postIORecord(IntakeOutputRecord record) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/intakeoutput');
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(record.toApiDto()),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // --- Doctor Orders API ---
  static Future<List<DoctorOrder>> getDoctorOrders(int docNo) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/doctororders/patient/$docNo');
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => DoctorOrder.fromJson(json)).toList();
    }
    return [];
  }

  static Future<bool> markDoctorOrderExecuted(int orderId, String notes) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/doctororders/$orderId/execute');
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'notes': notes}),
    );
    return response.statusCode == 200;
  }
}
