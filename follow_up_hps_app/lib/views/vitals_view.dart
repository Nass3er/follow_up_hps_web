import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../models/patient.dart';
import '../models/vital_sign.dart';
import '../services/api_service.dart';
import '../services/db_helper.dart';

class VitalsView extends StatefulWidget {
  final Patient? activePatient;

  const VitalsView({super.key, this.activePatient});

  @override
  State<VitalsView> createState() => _VitalsViewState();
}

class _VitalsViewState extends State<VitalsView> {
  final _docNoCtrl = TextEditingController();
  final _sysBpCtrl = TextEditingController();
  final _diaBpCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _respCtrl = TextEditingController();
  final _o2SatCtrl = TextEditingController();
  final _painCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  List<VitalSign> _vitalsHistory = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.activePatient != null) {
      _docNoCtrl.text = widget.activePatient!.docNo.toString();
      _loadVitals();
    }
  }

  Future<void> _loadVitals() async {
    final docNo = int.tryParse(_docNoCtrl.text.trim());
    if (docNo == null) return;

    setState(() => _isLoading = true);

    try {
      final online = await ApiService.getVitalsHistory(docNo);
      final offline = await DBHelper.getVitalsForPatient(docNo);
      
      final Map<int, VitalSign> merged = {};
      for (var v in offline) {
        if (v.id != null) merged[v.id!] = v;
      }
      for (var v in online) {
        merged[v.id ?? v.hashCode] = v;
      }

      if (mounted) {
        setState(() => _vitalsHistory = merged.values.toList());
      }
    } catch (_) {
      final offline = await DBHelper.getVitalsForPatient(docNo);
      if (mounted) {
        setState(() => _vitalsHistory = offline);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveVitalSign() async {
    final docNo = int.tryParse(_docNoCtrl.text.trim());
    if (docNo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رقم الدخول صحيحاً')),
      );
      return;
    }

    final now = DateTime.now();
    final timeStr = intl.DateFormat('HH:mm').format(now);
    final dateStr = intl.DateFormat('yyyy-MM-dd').format(now);

    final vital = VitalSign(
      docNo: docNo,
      time: timeStr,
      date: dateStr,
      sysBp: double.tryParse(_sysBpCtrl.text),
      diaBp: double.tryParse(_diaBpCtrl.text),
      pulse: double.tryParse(_pulseCtrl.text),
      temp: double.tryParse(_tempCtrl.text),
      resp: double.tryParse(_respCtrl.text),
      o2Sat: double.tryParse(_o2SatCtrl.text),
      painScore: int.tryParse(_painCtrl.text),
      position: _positionCtrl.text.trim(),
      remarks: _remarksCtrl.text.trim(),
      isSynced: false,
    );

    setState(() => _isSaving = true);

    bool synced = false;
    try {
      synced = await ApiService.postVitalSign(vital);
    } catch (_) {
      synced = false;
    }

    final toSave = VitalSign(
      docNo: vital.docNo,
      time: vital.time,
      date: vital.date,
      sysBp: vital.sysBp,
      diaBp: vital.diaBp,
      pulse: vital.pulse,
      temp: vital.temp,
      resp: vital.resp,
      o2Sat: vital.o2Sat,
      painScore: vital.painScore,
      position: vital.position,
      remarks: vital.remarks,
      isSynced: synced,
    );

    await DBHelper.insertVital(toSave);

    if (mounted) {
      setState(() => _isSaving = false);
      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(synced ? 'تم حفظ ومزامنة العلامات بنجاح ✅' : 'تم حفظ العلامات محلياً (أوفلاين) 📱'),
          backgroundColor: synced ? Colors.green : Colors.orange[800],
        ),
      );
      _loadVitals();
    }
  }

  void _clearForm() {
    _sysBpCtrl.clear();
    _diaBpCtrl.clear();
    _pulseCtrl.clear();
    _tempCtrl.clear();
    _respCtrl.clear();
    _o2SatCtrl.clear();
    _painCtrl.clear();
    _positionCtrl.clear();
    _remarksCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF009688),
        title: Text('تسجيل العلامات الحيوية', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DocNo input
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _docNoCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'رقم الدخول للمريض (Doc No)',
                          prefixIcon: const Icon(Icons.numbers),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _loadVitals,
                      style: ElevatedButton.styleFrom(
                        primary: const Color(0xFF009688),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      child: Text('جلب', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Vitals Input Form
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('إدخال قراءات جديدة:', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF009688))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberInput(_sysBpCtrl, 'الضغط العالي (Sys)', '120', Icons.compress),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumberInput(_diaBpCtrl, 'الضغط المنخفض (Dia)', '80', Icons.expand),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberInput(_pulseCtrl, 'النبض (Pulse)', '75', Icons.monitor_heart),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumberInput(_tempCtrl, 'الحرارة (°C)', '37.0', Icons.thermostat),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberInput(_respCtrl, 'التنفس (Resp)', '18', Icons.air),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumberInput(_o2SatCtrl, 'الأكسجين (O2%)', '98', Icons.water_drop),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberInput(_painCtrl, 'مستوى الألم (0-10)', '0', Icons.sentiment_very_dissatisfied),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _positionCtrl,
                            decoration: InputDecoration(
                              labelText: 'الوضعية (Position)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _remarksCtrl,
                      decoration: InputDecoration(
                        labelText: 'ملاحظات إضافية',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveVitalSign,
                        style: ElevatedButton.styleFrom(
                          primary: const Color(0xFF009688),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          'حفظ العلامات الحيوية',
                          style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // History List
            Text('سجل العلامات الحيوية:', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_vitalsHistory.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('لا توجد سجلات سابقة للمريض', style: GoogleFonts.tajawal(color: Colors.grey)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _vitalsHistory.length,
                itemBuilder: (ctx, idx) {
                  final item = _vitalsHistory[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: item.isSynced ? Colors.green[100] : Colors.orange[100],
                        child: Icon(
                          item.isSynced ? Icons.check_circle : Icons.cloud_off,
                          color: item.isSynced ? Colors.green[800] : Colors.orange[800],
                        ),
                      ),
                      title: Text(
                        'الضغط: ${item.sysBp?.toInt() ?? '-'}/${item.diaBp?.toInt() ?? '-'} | النبض: ${item.pulse?.toInt() ?? '-'} | الحرارة: ${item.temp ?? '-'}°C',
                        style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text(
                        'الوقت: ${item.time ?? '-'} | الأكسجين: ${item.o2Sat?.toInt() ?? '-'}% | ${item.isSynced ? "مستلمة بالسيرفر" : "محفوظة محلياً"}',
                        style: GoogleFonts.tajawal(fontSize: 11),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInput(TextEditingController controller, String label, String hint, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
    );
  }
}
