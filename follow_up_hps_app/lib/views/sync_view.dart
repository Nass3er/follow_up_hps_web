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
  int _pendingCount = 0;
  List<Map<String, dynamic>> _unsyncedRecords = [];
  bool _isSyncing = false;
  String? _resultMessage;
  bool _selectAll = false;
  Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final count = await DBHelper.getPendingSyncCount();
    final records = await DBHelper.getUnsyncedRecords();
    final unsyncedVitals = await DBHelper.getUnsyncedVitals();
    final unsyncedIO = await DBHelper.getUnsyncedIO();

    if (mounted) {
      setState(() {
        _pendingCount = count;
        _unsyncedRecords = records;
        _selectedIds.clear();
        _selectAll = false;
      });
    }
  }

  Future<void> _handleSync() async {
    setState(() { _isSyncing = true; _resultMessage = null; });
    final res = await SyncService.syncAllPendingRecords();
    if (mounted) {
      setState(() { _isSyncing = false; _resultMessage = res['message']; });
      _loadData();
    }
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        _selectedIds = _unsyncedRecords.map((r) => r['id'] as int).toSet();
      } else {
        _selectedIds.clear();
      }
    });
  }

  void _toggleItem(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      _selectAll = _selectedIds.length == _unsyncedRecords.length;
    });
  }

  Future<void> _deleteSelected() async {
    for (var id in _selectedIds) {
      await DBHelper.deleteUnsyncedRecord(id);
    }
    _loadData();
  }

  String _recordTypeLabel(String? type) {
    switch (type) {
      case 'vitals': return 'علامات حيوية';
      case 'io': return 'سوائل';
      case 'order': return 'أمر طبي';
      default: return 'سجل';
    }
  }

  Color _recordTypeColor(String? type) {
    switch (type) {
      case 'vitals': return const Color(0xFF1565C0);
      case 'io': return const Color(0xFFF39C12);
      case 'order': return const Color(0xFF43A047);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFB8C00),
        title: Text('مركز المزامنة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          if (_unsyncedRecords.isNotEmpty)
            IconButton(
              icon: Icon(_selectAll ? Icons.deselect : Icons.select_all, color: Colors.white),
              onPressed: _toggleSelectAll,
            ),
          if (_selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteSelected,
            ),
        ],
      ),
      body: Column(
        children: [
          // Summary
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                Icon(
                  _pendingCount > 0 ? Icons.sync_problem_rounded : Icons.cloud_done_rounded,
                  size: 60,
                  color: _pendingCount > 0 ? const Color(0xFFFB8C00) : Colors.green,
                ),
                const SizedBox(height: 12),
                Text(
                  _pendingCount > 0 ? '$_pendingCount سجلات تحتاج للمزامنة' : 'جميع السجلات متزامنة',
                  style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          if (_resultMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
              child: Text(_resultMessage!, style: GoogleFonts.tajawal(color: Colors.blue[900], fontWeight: FontWeight.bold)),
            ),

          // Records List
          Expanded(
            child: _unsyncedRecords.isEmpty
                ? Center(child: Text('لا توجد سجلات معلقة', style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 16)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _unsyncedRecords.length,
                    itemBuilder: (_, idx) {
                      final rec = _unsyncedRecords[idx];
                      final id = rec['id'] as int;
                      final type = rec['recordType'] as String?;
                      final isSelected = _selectedIds.contains(id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleItem(id),
                            activeColor: const Color(0xFFFB8C00),
                          ),
                          title: Text(_recordTypeLabel(type), style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('المسار: ${rec['apiUrl'] ?? '-'}', style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[600])),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: _recordTypeColor(type).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(_recordTypeLabel(type), style: GoogleFonts.tajawal(fontSize: 10, color: _recordTypeColor(type), fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Sync Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSyncing || _pendingCount == 0 ? null : _handleSync,
                style: ElevatedButton.styleFrom(primary: const Color(0xFFFB8C00), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                icon: _isSyncing
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                label: Text(_isSyncing ? 'جاري المزامنة...' : 'مزامنة الكل', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
