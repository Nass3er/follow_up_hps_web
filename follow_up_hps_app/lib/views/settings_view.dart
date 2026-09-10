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
    await AuthService.saveApiConfig(
      _hostCtrl.text.trim(),
      _portCtrl.text.trim(),
      _serviceCtrl.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ إعدادات السيرفر بنجاح ✅'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final baseUrl = await AuthService.getBaseUrl();
      final response = await http.get(Uri.parse('$baseUrl/company/name')).timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testResult = response.statusCode == 200 ? 'الاتصال بالسيرفر ناجح 🟢' : 'السيرفر استجيب ولكن بحالة ${response.statusCode} 🟡';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testResult = 'فشل الاتصال بالسيرفر: تحقق من العنوان 🔴';
        });
      }
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد مسح التخزين المؤقت', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        content: Text('هل أنت تأكد من مسح البيانات المخزنة محلياً؟ لن يتم مسح السجلات المتزامنة مع السيرفر.', style: GoogleFonts.tajawal()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء', style: GoogleFonts.tajawal())),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(primary: Colors.red),
            child: Text('مسح البيانات', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DBHelper.clearLocalCache();
      await _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تفريغ الذاكرة المحلية بنجاح ✅')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF546E7A),
        title: Text('الإعدادات وصيانة البيانات', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Server Config Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.dns_rounded, color: Color(0xFF546E7A)),
                        const SizedBox(width: 8),
                        Text('إعدادات رابط الاتصال (API Server)', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _hostCtrl,
                      decoration: InputDecoration(
                        labelText: 'عنوان IP أو النطاق (Host)',
                        hintText: 'مثال: 192.168.1.100 أو domain.com',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _portCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'المنفذ (Port)',
                        hintText: '80 أو 5000',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _serviceCtrl,
                      decoration: InputDecoration(
                        labelText: 'مسار الخدمة (Service Path)',
                        hintText: 'hps',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveSettings,
                            style: ElevatedButton.styleFrom(
                              primary: const Color(0xFF546E7A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.save, color: Colors.white),
                            label: Text('حفظ', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isTesting ? null : _testConnection,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: _isTesting
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.network_check),
                            label: Text('اختبار الاتصال', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    if (_testResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                        child: Text(_testResult!, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ]
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Local DB Stats & Maintenance Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.storage_rounded, color: Color(0xFF546E7A)),
                        const SizedBox(width: 8),
                        Text('قاعدة البيانات المحلية أوفلاين', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text('السجلات المحلية المعلقة للمزامنة', style: GoogleFonts.tajawal()),
                      trailing: Text('$_pendingCount سجل', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.orange[800])),
                    ),
                    const Divider(),
                    OutlinedButton.icon(
                      onPressed: _clearCache,
                      style: OutlinedButton.styleFrom(
                        primary: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.delete_forever),
                      label: Text('تفريغ الذاكرة والتخزين المؤقت المحلي', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
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
