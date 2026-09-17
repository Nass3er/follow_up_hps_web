import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../models/patient.dart';
import '../models/intake_output.dart';
import '../models/doctor_order.dart';
import '../services/api_service.dart';
import '../services/db_helper.dart';

class IntakeOutputView extends StatefulWidget {
  final Patient? activePatient;
  const IntakeOutputView({super.key, this.activePatient});

  @override
  State<IntakeOutputView> createState() => _IntakeOutputViewState();
}

class _IntakeOutputViewState extends State<IntakeOutputView> {
  Patient? _patient;
  List<Admission> _admissions = [];
  DateTime _selectedDate = DateTime.now();
  List<IntakeOutputRecord> _records = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.activePatient != null) {
      _patient = widget.activePatient;
      _loadRecords();
    }
    _loadAdmissions();
  }

  Future<void> _loadAdmissions() async {
    try {
      final list = await ApiService.getAdmissions();
      if (mounted) setState(() => _admissions = list);
    } catch (_) {}
  }

  Future<void> _loadRecords() async {
    if (_patient == null) return;
    setState(() => _isLoading = true);
    final dateStr = intl.DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      final list = await ApiService.getIOHistory(_patient!.docSrl, dateStr);
      if (mounted) setState(() => _records = list);
    } catch (_) {
      if (mounted) setState(() => _records = []);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showAdmissionsModal() {
    final searchCtrl = TextEditingController();
    List<Admission> filtered = List.from(_admissions);
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.9, expand: false,
          builder: (_, scrollCtrl) => Column(children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Color(0xFF00ACC1), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: Column(children: [
                Text('اختر مريضاً', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                TextField(
                  controller: searchCtrl,
                  onChanged: (v) => setModalState(() => filtered = _admissions.where((a) => a.patientName.contains(v) || a.docNo.toString().contains(v)).toList()),
                  decoration: InputDecoration(hintText: 'بحث...', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                ),
              ]),
            ),
            Expanded(child: ListView.builder(
              controller: scrollCtrl, itemCount: filtered.length,
              itemBuilder: (_, i) {
                final a = filtered[i];
                return ListTile(
                  title: Text(a.patientName, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                  subtitle: Text('رقم الدخول: ${a.docNo}', style: GoogleFonts.tajawal(fontSize: 12)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final p = await ApiService.getAdmissionDetails(a.docNo, a.docSerial);
                    if (p != null) { setState(() => _patient = p); _loadRecords(); }
                  },
                );
              },
            )),
          ]),
        ),
      ),
    );
  }

  void _showAddRecordModal() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => const _AddIORecordSheet(),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        _saveRecord(result);
      }
    });
  }

  Future<void> _saveRecord(Map<String, dynamic> data) async {
    if (_patient == null) return;
    final now = DateTime.now();
    final dateStr = intl.DateFormat('yyyy-MM-dd').format(_selectedDate);
    final timeStr = intl.DateFormat('HH:mm:ss').format(now);

    final record = IntakeOutputRecord(
      docNo: _patient!.docNo,
      docSrlAdmt: _patient!.docSrl,
      patientNo: _patient!.patientNo,
      age: _patient!.age,
      ageType: _patient!.ageType,
      roomNo: _patient!.roomNo,
      bedNo: _patient!.bedNo,
      roomSer: _patient!.roomService,
      buildingNo: _patient!.buldNo,
      docTime: '${dateStr}T$timeStr',
      inIvf: data['inIvf'] ?? 0,
      inOral: data['inOral'] ?? 0,
      inNgt: data['inNgt'] ?? 0,
      inBld: data['inBld'] ?? 0,
      inOthr: data['inOthr'] ?? 0,
      outUrine: data['outUrine'] ?? 0,
      outGstrc: data['outGstrc'] ?? 0,
      outDrng1: data['outDrng1'] ?? 0,
      outDrng2: data['outDrng2'] ?? 0,
      outEmss: data['outEmss'] ?? 0,
      outOthr: data['outOthr'] ?? 0,
      notes: data['notes'] ?? '',
    );

    final res = await ApiService.saveIORecord(record);
    if (res['success'] != true) {
      await DBHelper.insertIO(record);
    }
    _loadRecords();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['success'] == true ? 'تم الحفظ بنجاح' : 'تم الحفظ محلياً (أوفلاين)'), backgroundColor: res['success'] == true ? Colors.green : Colors.orange),
    );
  }

  Future<void> _deleteRecord(IntakeOutputRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد الحذف', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        content: Text('هل تريد حذف هذا السجل؟', style: GoogleFonts.tajawal()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء', style: GoogleFonts.tajawal())),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(primary: Colors.red), child: Text('حذف', style: GoogleFonts.tajawal(color: Colors.white))),
        ],
      ),
    );
    if (confirm == true && record.docSrl != null) {
      await ApiService.deleteIORecord(record.docSrl!);
      _loadRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalIn = _records.fold<double>(0, (s, r) => s + r.totalIntake);
    final totalOut = _records.fold<double>(0, (s, r) => s + r.totalOutput);
    final balance = totalIn - totalOut;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00ACC1),
        title: Text('السوائل (Intake & Output)', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          if (_patient != null)
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
              onPressed: _showAddRecordModal,
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _showAdmissionsModal,
                  icon: const Icon(Icons.person_search, color: Colors.white, size: 18),
                  label: Text(_patient != null ? _patient!.patientName : 'اختر مريض', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(primary: const Color(0xFF00ACC1), minimumSize: const Size(double.infinity, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)));
                          if (picked != null) setState(() { _selectedDate = picked; _loadRecords(); });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                          child: Row(children: [
                            const Icon(Icons.calendar_today, size: 16, color: Color(0xFF00ACC1)),
                            const SizedBox(width: 8),
                            Text(intl.DateFormat('yyyy-MM-dd').format(_selectedDate), style: GoogleFonts.tajawal(fontSize: 13)),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(children: [
                      Text('الداخل', style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[600])),
                      Text('${totalIn.toStringAsFixed(0)} ml', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.blue[800])),
                    ]),
                    Column(children: [
                      Text('الخارج', style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[600])),
                      Text('${totalOut.toStringAsFixed(0)} ml', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.orange[800])),
                    ]),
                    Column(children: [
                      Text('الميزان', style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[600])),
                      Text('${balance.toStringAsFixed(0)} ml', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: balance >= 0 ? Colors.green[800] : Colors.red[800])),
                    ]),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? Center(child: Text(_patient == null ? 'اختر مريضاً' : 'لا توجد سجلات', style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 16)))
                    : _buildRecordsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _records.length,
      itemBuilder: (_, idx) {
        final r = _records[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.timeOnly, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14)),
                    Row(children: [
                      if (!r.isSynced)
                        const Icon(Icons.cloud_off, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        onPressed: () => _deleteRecord(r),
                      ),
                    ]),
                  ],
                ),
                const Divider(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ioField('IVF', r.inIvf, Colors.blue),
                    _ioField('Oral', r.inOral, Colors.blue),
                    _ioField('NGT', r.inNgt, Colors.blue),
                    _ioField('Blood', r.inBld, Colors.blue),
                    _ioField('Urine', r.outUrine, Colors.orange),
                    _ioField('Gastric', r.outGstrc, Colors.orange),
                    _ioField('Drain', (r.outDrng1 ?? 0) + (r.outDrng2 ?? 0), Colors.orange),
                    _ioField('Emesis', r.outEmss, Colors.orange),
                  ],
                ),
                if (r.notes != null && r.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('ملاحظات: ${r.notes}', style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[600])),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _ioField(String label, double? value, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.tajawal(fontSize: 9, color: Colors.grey[500])),
        Text('${(value ?? 0).toStringAsFixed(0)}', style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _AddIORecordSheet extends StatefulWidget {
  const _AddIORecordSheet();

  @override
  State<_AddIORecordSheet> createState() => _AddIORecordSheetState();
}

class _AddIORecordSheetState extends State<_AddIORecordSheet> {
  final _ivfCtrl = TextEditingController();
  final _oralCtrl = TextEditingController();
  final _ngtCtrl = TextEditingController();
  final _bldCtrl = TextEditingController();
  final _inOthrCtrl = TextEditingController();
  final _urineCtrl = TextEditingController();
  final _gstrcCtrl = TextEditingController();
  final _drng1Ctrl = TextEditingController();
  final _drng2Ctrl = TextEditingController();
  final _emssCtrl = TextEditingController();
  final _outOthrCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 12),
            Text('إضافة سجل سوائل', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF00ACC1))),
            const SizedBox(height: 16),
            Text('Intake (الدخول)', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.blue[800])),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _field(_ivfCtrl, 'IVF (وريدي)')),
              const SizedBox(width: 8),
              Expanded(child: _field(_oralCtrl, 'Oral (فموي)')),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _field(_ngtCtrl, 'NGT (أنبوب)')),
              const SizedBox(width: 8),
              Expanded(child: _field(_bldCtrl, 'Blood (دم)')),
            ]),
            const SizedBox(height: 8),
            _field(_inOthrCtrl, 'أخرى (دخول)'),
            const SizedBox(height: 16),
            Text('Output (الخروج)', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.orange[800])),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _field(_urineCtrl, 'Urine (بول)')),
              const SizedBox(width: 8),
              Expanded(child: _field(_gstrcCtrl, 'Gastric (معدة)')),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _field(_drng1Ctrl, 'Drain 1')),
              const SizedBox(width: 8),
              Expanded(child: _field(_drng2Ctrl, 'Drain 2')),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _field(_emssCtrl, 'Emesis (قيء)')),
              const SizedBox(width: 8),
              Expanded(child: _field(_outOthrCtrl, 'أخرى (خروج)')),
            ]),
            const SizedBox(height: 12),
            _field(_notesCtrl, 'ملاحظات'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'inIvf': double.tryParse(_ivfCtrl.text) ?? 0,
                    'inOral': double.tryParse(_oralCtrl.text) ?? 0,
                    'inNgt': double.tryParse(_ngtCtrl.text) ?? 0,
                    'inBld': double.tryParse(_bldCtrl.text) ?? 0,
                    'inOthr': double.tryParse(_inOthrCtrl.text) ?? 0,
                    'outUrine': double.tryParse(_urineCtrl.text) ?? 0,
                    'outGstrc': double.tryParse(_gstrcCtrl.text) ?? 0,
                    'outDrng1': double.tryParse(_drng1Ctrl.text) ?? 0,
                    'outDrng2': double.tryParse(_drng2Ctrl.text) ?? 0,
                    'outEmss': double.tryParse(_emssCtrl.text) ?? 0,
                    'outOthr': double.tryParse(_outOthrCtrl.text) ?? 0,
                    'notes': _notesCtrl.text.trim(),
                  });
                },
                style: ElevatedButton.styleFrom(primary: const Color(0xFF00ACC1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('حفظ السجل', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label, hintText: '0',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}
