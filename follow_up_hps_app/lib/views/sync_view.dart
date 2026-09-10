import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/db_helper.dart';
import '../services/sync_service.dart';

class SyncView extends StatefulWidget {
  const SyncView({super.key});

  @override
  State<SyncView> createState() => _SyncViewState();
}

class _SyncViewState extends State<SyncView> {
  int _unsyncedVitalsCount = 0;
  int _unsyncedIOCount = 0;
  int _unsyncedOrdersCount = 0;
  bool _isSyncing = false;
  String? _resultMessage;

  @override
  void initState() {
    super.initState();
    _loadUnsyncedCounts();
  }

  Future<void> _loadUnsyncedCounts() async {
    final v = await DBHelper.getUnsyncedVitals();
    final io = await DBHelper.getUnsyncedIO();
    final ord = await DBHelper.getUnsyncedDoctorOrders();

    if (mounted) {
      setState(() {
        _unsyncedVitalsCount = v.length;
        _unsyncedIOCount = io.length;
        _unsyncedOrdersCount = ord.length;
      });
    }
  }

  Future<void> _handleSync() async {
    setState(() {
      _isSyncing = true;
      _resultMessage = null;
    });

    final res = await SyncService.syncAllPendingRecords();

    if (mounted) {
      setState(() {
        _isSyncing = false;
        _resultMessage = res['message'];
      });
      _loadUnsyncedCounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _unsyncedVitalsCount + _unsyncedIOCount + _unsyncedOrdersCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFB8C00),
        title: Text('مركز المزامنة أوفلاين', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Icon(
                    total > 0 ? Icons.sync_problem_rounded : Icons.cloud_done_rounded,
                    size: 70,
                    color: total > 0 ? const Color(0xFFFB8C00) : Colors.green,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    total > 0 ? 'لديك $total سجلات محلياً تحتاج للمزامنة' : 'جميع السجلات متزامنة مع السيرفر ✅',
                    style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Breakdown
            _buildCountTile('العلامات الحيوية المعلقة', _unsyncedVitalsCount, Icons.monitor_heart),
            _buildCountTile('سجلات السوائل (I & O) المعلقة', _unsyncedIOCount, Icons.water_drop),
            _buildCountTile('تنفيذات أوامر الأطباء المعلقة', _unsyncedOrdersCount, Icons.assignment),

            const SizedBox(height: 30),

            if (_resultMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(_resultMessage!, style: GoogleFonts.tajawal(color: Colors.blue[900], fontWeight: FontWeight.bold)),
              ),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSyncing || total == 0 ? null : _handleSync,
                style: ElevatedButton.styleFrom(
                  primary: const Color(0xFFFB8C00),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isSyncing
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                label: Text(
                  _isSyncing ? 'جاري المزامنة الآن...' : 'مزامنة السجلات الآن 🔄',
                  style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountTile(String label, int count, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFFB8C00)),
        title: Text(label, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: count > 0 ? Colors.orange[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.tajawal(
              fontWeight: FontWeight.bold,
              color: count > 0 ? Colors.orange[900] : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}
