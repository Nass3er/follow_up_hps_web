import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/db_helper.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  final _serviceCtrl = TextEditingController();
  int _pendingCount = 0;
  bool _isTesting = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final cfg = await AuthService.getApiConfig();
    final count = await DBHelper.getPendingSyncCount();
    if (mounted) {
      setState(() {
        _hostCtrl.text = cfg['host'] ?? '';
        _portCtrl.text = cfg['port'] ?? '';
        _serviceCtrl.text = cfg['service'] ?? '';
        _pendingCount = count;
      });
    }
  }

  Future<void> _saveSettings() async {
    await AuthService.saveApiConfig(_hostCtrl.text.trim(), _portCtrl.text.trim(), _serviceCtrl.text.trim());
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح'), backgroundColor: Colors.green));
  }

  Future<void> _testConnection() async {
    setState(() { _isTesting = true; _testResult = null; });
    try {
      final baseUrl = await AuthService.getBaseUrl();
      final response = await http.get(Uri.parse('$baseUrl/company/name')).timeout(const Duration(seconds: 5));
      if (mounted) setState(() { _isTesting = false; _testResult = response.statusCode == 200 ? 'الاتصال ناجح' : 'حالة ${response.statusCode}'; });
    } catch (_) {
      if (mounted) setState(() { _isTesting = false; _testResult = 'فشل الاتصال'; });
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد مسح التخزين', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        content: Text('هل تريد مسح البيانات المخزنة محلياً؟', style: GoogleFonts.tajawal()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء', style: GoogleFonts.tajawal())),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(primary: Colors.red), child: Text('مسح', style: GoogleFonts.tajawal(color: Colors.white))),
        ],
      ),
    );
    if (confirmed == true) {
      await DBHelper.clearLocalCache();
      _loadSettings();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم مسح التخزين المؤقت')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF546E7A),
        title: Text('الإعدادات', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.dns_rounded, color: Color(0xFF546E7A)),
                      const SizedBox(width: 8),
                      Text('إعدادات الاتصال', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16)),
                    ]),
                    const SizedBox(height: 16),
                    TextField(controller: _hostCtrl, decoration: InputDecoration(labelText: 'الهوست', hintText: '192.168.1.100', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 12),
                    TextField(controller: _portCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'البورت', hintText: '80', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 12),
                    TextField(controller: _serviceCtrl, decoration: InputDecoration(labelText: 'الخدمة', hintText: 'hps', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: ElevatedButton.icon(onPressed: _saveSettings, style: ElevatedButton.styleFrom(primary: const Color(0xFF546E7A)), icon: const Icon(Icons.save, color: Colors.white), label: Text('حفظ', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)))),
                      const SizedBox(width: 10),
                      Expanded(child: OutlinedButton.icon(onPressed: _isTesting ? null : _testConnection, icon: _isTesting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.network_check), label: Text('اختبار', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)))),
                    ]),
                    if (_testResult != null) ...[
                      const SizedBox(height: 12),
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: Text(_testResult!, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13))),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.storage_rounded, color: Color(0xFF546E7A)),
                      const SizedBox(width: 8),
                      Text('البيانات المحلية', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16)),
                    ]),
                    const SizedBox(height: 12),
                    ListTile(
                      title: Text('السجلات المعلقة', style: GoogleFonts.tajawal()),
                      trailing: Text('$_pendingCount', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.orange[800])),
                    ),
                    const Divider(),
                    OutlinedButton.icon(
                      onPressed: _clearCache,
                      style: OutlinedButton.styleFrom(primary: Colors.red, side: const BorderSide(color: Colors.red)),
                      icon: const Icon(Icons.delete_forever),
                      label: Text('مسح التخزين المؤقت', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
