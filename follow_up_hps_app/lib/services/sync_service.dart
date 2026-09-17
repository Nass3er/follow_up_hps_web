import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'auth_service.dart';
import 'db_helper.dart';

class SyncService {
  static Future<Map<String, dynamic>> syncAllPendingRecords() async {
    int synced = 0;
    int failed = 0;

    try {
      final unsyncedVitals = await DBHelper.getUnsyncedVitals();
      for (var vital in unsyncedVitals) {
        final result = await ApiService.saveVitalSign(vital);
        if (result['success'] == true) {
          if (vital.localId != null) await DBHelper.markVitalSynced(vital.localId!);
          synced++;
        } else {
          failed++;
        }
      }

      final unsyncedIO = await DBHelper.getUnsyncedIO();
      for (var io in unsyncedIO) {
        final result = await ApiService.saveIORecord(io);
        if (result['success'] == true) {
          if (io.localId != null) await DBHelper.markIOSynced(io.localId!);
          synced++;
        } else {
          failed++;
        }
      }

      final unsyncedRecords = await DBHelper.getUnsyncedRecords();
      for (var rec in unsyncedRecords) {
        try {
          final baseUrl = await AuthService.getBaseUrl();
          final token = await AuthService.getToken();
          final url = Uri.parse('$baseUrl${rec['apiUrl']}');
          final headers = {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          };
          final body = rec['dto'] ?? '{}';
          final method = rec['httpMethod'] ?? 'POST';

          http.Response response;
          if (method == 'DELETE') {
            response = await http.delete(url, headers: headers);
          } else {
            response = await http.post(url, headers: headers, body: body);
          }

          if (response.statusCode == 200) {
            await DBHelper.deleteUnsyncedRecord(rec['id'] as int);
            synced++;
          } else {
            failed++;
          }
        } catch (_) {
          failed++;
        }
      }

      return {
        'success': true,
        'totalSynced': synced,
        'failedCount': failed,
        'message': synced > 0
            ? 'تمت مزامنة $synced سجل بنجاح.'
            : 'لا توجد سجلات معلقة.',
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ أثناء المزامنة: $e'};
    }
  }
}
