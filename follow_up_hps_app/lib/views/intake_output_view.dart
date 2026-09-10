import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../models/patient.dart';
import '../models/intake_output.dart';
import '../services/api_service.dart';
import '../services/db_helper.dart';

class IntakeOutputView extends StatefulWidget {
  final Patient? activePatient;

  const IntakeOutputView({super.key, this.activePatient});

  @override
  State<IntakeOutputView> createState() => _IntakeOutputViewState();
}

class _IntakeOutputViewState extends State<IntakeOutputView> {
  final _docNoCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _category = 'intake';
  String _typeName = 'مغدي وريدي (IV Fluid)';

  final List<String> _intakeTypes = [
    'مغدي وريدي (IV Fluid)',
    'سوائل فموية (Oral Fluid)',
    'مشتقات دم (Blood Product)',
    'أنبوب تغذية (Tube Feeding)',
    'أخرى (Other Intake)'
  ];

  final List<String> _outputTypes = [
    'بول (Urine)',
    'مفرزات نزح (Drain)',
    'قيء (Vomit)',
    'براز (Stool)',
    'أنبوب معدي (NG Tube Output)',
    'أخرى (Other Output)'
  ];

  List<IntakeOutputRecord> _ioList = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.activePatient != null) {
      _docNoCtrl.text = widget.activePatient!.docNo.toString();
      _loadIORecords();
    }
  }

  Future<void> _loadIORecords() async {
    final docNo = int.tryParse(_docNoCtrl.text.trim());
    if (docNo == null) return;

    setState(() => _isLoading = true);

    try {
      final online = await ApiService.getIOHistory(docNo);
      final offline = await DBHelper.getIOForPatient(docNo);

      final Map<int, IntakeOutputRecord> merged = {};
      for (var r in offline) {
        if (r.id != null) merged[r.id!] = r;
      }
      for (var r in online) {
        merged[r.id ?? r.hashCode] = r;
      }

      if (mounted) {
        setState(() => _ioList = merged.values.toList());
      }
    } catch (_) {
      final offline = await DBHelper.getIOForPatient(docNo);
      if (mounted) {
        setState(() => _ioList = offline);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRecord() async {
    final docNo = int.tryParse(_docNoCtrl.text.trim());
    final amount = double.tryParse(_amountCtrl.text.trim());

    if (docNo == null || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رقم الدخول وكمية السوائل بصورة صحيحة')),
      );
      return;
    }

    final now = DateTime.now();
    final timeStr = intl.DateFormat('HH:mm').format(now);
    final dateStr = intl.DateFormat('yyyy-MM-dd').format(now);

    final record = IntakeOutputRecord(
      docNo: docNo,
      category: _category,
      typeName: _typeName,
      amount: amount,
      time: timeStr,
      date: dateStr,
      notes: _notesCtrl.text.trim(),
      isSynced: false,
    );

    setState(() => _isSaving = true);

    bool synced = false;
    try {
      synced = await ApiService.postIORecord(record);
    } catch (_) {
      synced = false;
    }

    final toSave = IntakeOutputRecord(
      docNo: record.docNo,
      category: record.category,
      typeName: record.typeName,
      amount: record.amount,
      time: record.time,
      date: record.date,
      notes: record.notes,
      isSynced: synced,
    );

    await DBHelper.insertIntakeOutput(toSave);

    if (mounted) {
      setState(() => _isSaving = false);
      _amountCtrl.clear();
      _notesCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(synced ? 'تم تسجيل وتزامن السائل بنجاح ✅' : 'تم تسجيل السائل أوفلاين 📱'),
          backgroundColor: synced ? Colors.green : Colors.orange[800],
        ),
      );
      _loadIORecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalIntake = _ioList.where((e) => e.category == 'intake').fold<double>(0.0, (s, e) => s + e.amount);
    final totalOutput = _ioList.where((e) => e.category == 'output').fold<double>(0.0, (s, e) => s + e.amount);
    final balance = totalIntake - totalOutput;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00ACC1),
        title: Text('متابعة السوائل (Intake & Output)', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white)),
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
                      onPressed: _loadIORecords,
                      style: ElevatedButton.styleFrom(
                        primary: const Color(0xFF00ACC1),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      child: Text('جلب', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Fluid Balance Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.cyan[200]!),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBalanceItem('إجمالي الداخل (Intake)', '$totalIntake ml', Colors.blue[800]!),
                  _buildBalanceItem('إجمالي الخارج (Output)', '$totalOutput ml', Colors.orange[800]!),
                  _buildBalanceItem('الميزانية (Balance)', '$balance ml', balance >= 0 ? Colors.green[800]! : Colors.red[800]!),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Fluid Form Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تسجيل كمية سوائل جديدة:', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF00ACC1))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text('داخل (Intake)', style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold)),
                            value: 'intake',
                            groupValue: _category,
                            onChanged: (val) {
                              setState(() {
                                _category = val!;
                                _typeName = _intakeTypes.first;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text('خارج (Output)', style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold)),
                            value: 'output',
                            groupValue: _category,
                            onChanged: (val) {
                              setState(() {
                                _category = val!;
                                _typeName = _outputTypes.first;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _typeName,
                      decoration: InputDecoration(
                        labelText: 'نوع السائل / المفرزات',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: (_category == 'intake' ? _intakeTypes : _outputTypes).map((t) {
                        return DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.tajawal(fontSize: 14)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _typeName = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'الكمية بالمليلتر (ml)',
                        prefixIcon: const Icon(Icons.water_drop),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesCtrl,
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
                        onPressed: _isSaving ? null : _saveRecord,
                        style: ElevatedButton.styleFrom(
                          primary: const Color(0xFF00ACC1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          'حفظ كمية السائل',
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
            Text('سجل السوائل المسجلة:', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_ioList.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('لا توجد سجلات سوائل سابقة للمريض', style: GoogleFonts.tajawal(color: Colors.grey)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ioList.length,
                itemBuilder: (ctx, idx) {
                  final item = _ioList[idx];
                  final isIntake = item.category == 'intake';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isIntake ? Colors.blue[100] : Colors.orange[100],
                        child: Icon(
                          isIntake ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isIntake ? Colors.blue[900] : Colors.orange[900],
                        ),
                      ),
                      title: Text(
                        '${item.typeName} (${item.amount} ml)',
                        style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        'الوقت: ${item.time ?? '-'} | النوع: ${isIntake ? "داخل" : "خارج"} | ${item.isSynced ? "مستلمة بالسيرفر" : "محفوظة محلياً"}',
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

  Widget _buildBalanceItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[700])),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
