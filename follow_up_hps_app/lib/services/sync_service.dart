import 'api_service.dart';
import 'db_helper.dart';

class SyncService {
  static Future<Map<String, dynamic>> syncAllPendingRecords() async {
    int syncedVitals = 0;
    int syncedIO = 0;
    int syncedOrders = 0;
    int failedCount = 0;

    try {
      // 1. Sync Vitals
      final unsyncedVitals = await DBHelper.getUnsyncedVitals();
      for (var vital in unsyncedVitals) {
        final success = await ApiService.postVitalSign(vital);
        if (success) {
          if (vital.id != null) {
            await DBHelper.markVitalSynced(vital.id!);
          }
          syncedVitals++;
        } else {
          failedCount++;
        }
      }

      // 2. Sync Intake & Output
      final unsyncedIO = await DBHelper.getUnsyncedIO();
      for (var io in unsyncedIO) {
        final success = await ApiService.postIORecord(io);
        if (success) {
          if (io.id != null) {
            await DBHelper.markIOSynced(io.id!);
          }
          syncedIO++;
        } else {
          failedCount++;
        }
      }

      // 3. Sync Executed Doctor Orders
      final unsyncedOrders = await DBHelper.getUnsyncedDoctorOrders();
      for (var order in unsyncedOrders) {
        final success = await ApiService.markDoctorOrderExecuted(order.id, order.executionNotes ?? '');
        if (success) {
          await DBHelper.markDoctorOrderSynced(order.id);
          syncedOrders++;
        } else {
          failedCount++;
        }
      }

      final totalSynced = syncedVitals + syncedIO + syncedOrders;
      return {
        'success': true,
        'totalSynced': totalSynced,
        'syncedVitals': syncedVitals,
        'syncedIO': syncedIO,
        'syncedOrders': syncedOrders,
        'failedCount': failedCount,
        'message': totalSynced > 0
            ? 'تمت مزامنة $totalSynced سجل بنجاح.'
            : 'لا توجد سجلات معلقة بحاجة للمزامنة.'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ أثناء المزامنة: ${e.toString()}'
      };
    }
  }
}
