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
        String msg = 'بيانات الدخول غير صحيحة!';
        try {
          final errData = jsonDecode(response.body);
          if (errData != null && errData['message'] != null) msg = errData['message'];
        } catch (_) {}
        return {'success': false, 'message': msg, 'statusCode': 401};
      } else if (response.statusCode == 402) {
        String msg = 'الترخيص منتهي!';
        try {
          final errData = jsonDecode(response.body);
          if (errData != null && errData['message'] != null) msg = errData['message'];
        } catch (_) {}
        return {'success': false, 'message': msg, 'statusCode': 402};
      } else if (response.statusCode == 403) {
        String msg = 'جهاز غير مصرح له';
        try {
          final errData = jsonDecode(response.body);
          if (errData != null && errData['message'] != null) msg = errData['message'];
        } catch (_) {}
        return {'success': false, 'message': msg, 'statusCode': 403};
      } else {
        return {'success': false, 'message': 'خطأ في السيرفر (${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'OFFLINE_ERROR', 'statusCode': 0};
    }
  }

  static Future<Map<String, dynamic>> saveAndTestSettings(String host, String port, String service) async {
    await AuthService.saveApiConfig(host, port, service);
    final baseUrl = await AuthService.getBaseUrl();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 500) {
        return {'success': false, 'message': 'تم الاتصال بالسيرفر ولكن يوجد خطأ داخلي!'};
      }
      return {'success': true, 'message': 'تم الحفظ. الاتصال بالسيرفر جاهز!'};
    } catch (e) {
      return {'success': false, 'message': 'تم الحفظ، لكن فشل الاتصال بالسيرفر.'};
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

  static Future<List<Admission>> getAdmissions() async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/VitalSigns/admissions'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Admission.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Patient?> getAdmissionDetails(dynamic docNo, int docSrl) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/VitalSigns/admissions/details?docNo=$docNo&docSrl=$docSrl'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Patient.fromJson({...data, 'docNo': docNo, 'docSrl': docSrl});
      }
    } catch (_) {}
    return null;
  }

  static Future<List<VitalSign>> getVitalsHistory(String patientNo, String date) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/VitalSigns/history?patientNo=$patientNo&date=$date'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => VitalSign.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> saveVitalSign(VitalSign vital) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/VitalSigns'),
        headers: headers,
        body: jsonEncode(vital.toSaveDto()),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'تم الحفظ بنجاح'};
      }
      return {'success': false, 'message': 'فشل الحفظ (${response.statusCode})'};
    } catch (e) {
      return {'success': false, 'message': 'OFFLINE', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateVitalSign(VitalSign vital) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/VitalSigns/update/${vital.docSrl}'),
        headers: headers,
        body: jsonEncode(vital.toSaveDto()),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'OFFLINE'};
    }
  }

  static Future<Map<String, dynamic>> deleteVitalSign(int docSrl) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/VitalSigns/delete/$docSrl'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'OFFLINE'};
    }
  }

  static Future<List<IntakeOutputRecord>> getIOHistory(int docSrl, String date) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/IntakeOutput/$docSrl?docDate=$date'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => IntakeOutputRecord.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> saveIORecord(IntakeOutputRecord record) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/IntakeOutput/add'),
        headers: headers,
        body: jsonEncode(record.toSaveDto()),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'OFFLINE'};
    }
  }

  static Future<Map<String, dynamic>> updateIORecord(IntakeOutputRecord record) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/IntakeOutput/update'),
        headers: headers,
        body: jsonEncode(record.toSaveDto()),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return {'success': true};
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'OFFLINE'};
    }
  }

  static Future<Map<String, dynamic>> deleteIORecord(int docSrl) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/IntakeOutput/$docSrl'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return {'success': true};
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'OFFLINE'};
    }
  }

  static Future<List<ProcedureType>> getProcedureTypes() async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/DoctorOrder/procedure-types'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((j) => ProcedureType.fromJson(j)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<UsageMethod>> getUsageMethods() async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/DoctorOrder/usage-methods'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((j) => UsageMethod.fromJson(j)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<OrderItem>> getItems(int procedureType) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/DoctorOrder/items?procedureType=$procedureType'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((j) => OrderItem.fromJson(j)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<DoctorOrder>> getDoctorOrderHistory(int docSrlAdmission) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/DoctorOrder/history?docSrlAdmission=$docSrlAdmission'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((j) => DoctorOrder.fromJson(j)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<DoctorOrder?> getDoctorOrderDetails(int docSrl) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/DoctorOrder/details/$docSrl'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final master = data['master'] ?? {};
        final details = data['details'] ?? [];
        return DoctorOrder.fromJson({...master, 'details': details});
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>> saveDoctorOrder(DoctorOrder order, {
    required int branchNo,
    required dynamic admissionDocNo,
    required int admissionDocSrl,
    required String patientNo,
    required int roomSer,
    required int roomNo,
    required int deptNo,
    required int buildNo,
    required int bedNo,
    required int gender,
    required String age,
    required int ageType,
    required String doctorNo,
  }) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/DoctorOrder'),
        headers: headers,
        body: jsonEncode(order.toSaveDto(
          branchNo: branchNo, admissionDocNo: admissionDocNo,
          admissionDocSrl: admissionDocSrl, patientNo: patientNo,
          roomSer: roomSer, roomNo: roomNo, deptNo: deptNo,
          buildNo: buildNo, bedNo: bedNo, gender: gender,
          age: age, ageType: ageType, doctorNo: doctorNo,
        )),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      return {'success': response.statusCode == 200, 'message': data['message'] ?? ''};
    } catch (e) {
      return {'success': false, 'message': 'OFFLINE'};
    }
  }

  static Future<Map<String, dynamic>> updateDoctorOrder(DoctorOrder order, {
    required int branchNo,
    required dynamic admissionDocNo,
    required int admissionDocSrl,
    required String patientNo,
    required int roomSer,
    required int roomNo,
    required int deptNo,
    required int buildNo,
    required int bedNo,
    required int gender,
    required String age,
    required int ageType,
    required String doctorNo,
  }) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/DoctorOrder/update/${order.docSrl}'),
        headers: headers,
        body: jsonEncode(order.toSaveDto(
          branchNo: branchNo, admissionDocNo: admissionDocNo,
          admissionDocSrl: admissionDocSrl, patientNo: patientNo,
          roomSer: roomSer, roomNo: roomNo, deptNo: deptNo,
          buildNo: buildNo, bedNo: bedNo, gender: gender,
          age: age, ageType: ageType, doctorNo: doctorNo,
        )),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      return {'success': response.statusCode == 200, 'message': data['message'] ?? ''};
    } catch (e) {
      return {'success': false, 'message': 'OFFLINE'};
    }
  }

  static Future<Map<String, dynamic>> deleteDoctorOrder(int docSrl) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/DoctorOrder/$docSrl'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      return {'success': response.statusCode == 200, 'message': data['message'] ?? ''};
    } catch (e) {
      return {'success': false, 'message': 'OFFLINE'};
    }
  }

  static Future<List<LabResult>> getLabResults(int admissionDocSrl) async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/LabResult/by-admission?admissionDocSrl=$admissionDocSrl'),
        headers: headers,
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((j) => LabResult.fromJson(j)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Nurse>> getNurses() async {
    final baseUrl = await AuthService.getBaseUrl();
    final headers = await _getHeaders();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/staff/nurses'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((j) => Nurse.fromJson(j)).toList();
      }
    } catch (_) {}
    return [];
  }
}
