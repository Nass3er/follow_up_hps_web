import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../models/patient.dart';
import '../models/vital_sign.dart';
import '../models/doctor_order.dart';
import '../services/api_service.dart';
import '../services/db_helper.dart';

class VitalsView extends StatefulWidget {
  final Patient? activePatient;
  const VitalsView({super.key, this.activePatient});

  @override
  State<VitalsView> createState() => _VitalsViewState();
}

class _VitalsViewState extends State<VitalsView> {
  Patient? _patient;
  List<Admission> _admissions = [];
  DateTime _selectedDate = DateTime.now();
  int _interval = 30;
  List<_TimeSlotRow> _timeSlots = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.activePatient != null) {
      _patient = widget.activePatient;
      _loadTable();
    }
    _loadAdmissions();
  }

  Future<void> _loadAdmissions() async {
    try {
      final list = await ApiService.getAdmissions();
      if (mounted) setState(() => _admissions = list);
    } catch (_) {}
  }

  Future<void> _loadTable() async {
    if (_patient == null) return;
    setState(() => _isLoading = true);
    final dateStr = intl.DateFormat('yyyy-MM-dd').format(_selectedDate);
    List<VitalSign> serverVitals = [];
    try {
      serverVitals = await ApiService.getVitalsHistory(_patient!.patientNo, dateStr);
    } catch (_) {}

    final slots = _generateTimeSlots();
    for (var v in serverVitals) {
      final time = v.timeOnly;
      final idx = slots.indexWhere((s) => s.time == time);
      if (idx >= 0) {
        slots[idx].vital = v;
        slots[idx].isSynced = true;
      } else {
        slots.add(_TimeSlotRow(time: time, vital: v, isSynced: true));
        slots.sort((a, b) => a.time.compareTo(b.time));
      }
    }
    if (mounted) setState(() { _timeSlots = slots; _isLoading = false; });
  }

  List<_TimeSlotRow> _generateTimeSlots() {
    final slots = <_TimeSlotRow>[];
    for (int h = 1; h <= 23; h++) {
      for (int m = 0; m < 60; m += _interval) {
        if (h == 23 && m > 0) break;
        final time = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
        slots.add(_TimeSlotRow(time: time));
      }
    }
    return slots;
  }

  void _showAdmissionsModal() {
    final searchCtrl = TextEditingController();
    List<Admission> filtered = List.from(_admissions);
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.9, expand: false,
              builder: (_, scrollCtrl) => Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(color: Color(0xFF009688), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                    child: Column(children: [
                      Text('اختر مريضاً', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: searchCtrl,
                        onChanged: (v) => setModalState(() => filtered = _admissions.where((a) => a.patientName.contains(v) || a.docNo.toString().contains(v)).toList()),
                        decoration: InputDecoration(hintText: 'بحث...', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                      ),
                    ]),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollCtrl, itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final a = filtered[i];
                        return ListTile(
                          title: Text(a.patientName, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                          subtitle: Text('رقم الدخول: ${a.docNo}', style: GoogleFonts.tajawal(fontSize: 12)),
                          onTap: () async {
                            Navigator.pop(ctx);
                            final p = await ApiService.getAdmissionDetails(a.docNo, a.docSerial);
                            if (p != null) {
                              setState(() => _patient = p);
                              _loadTable();
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showVitalsEntryModal({VitalSign? existing, int? slotIndex}) {
    final tempCtrl = TextEditingController(text: existing?.temperature?.toString() ?? '');
    final pulseCtrl = TextEditingController(text: existing?.pulseRate?.toString() ?? '');
    final respCtrl = TextEditingController(text: existing?.respirationRate?.toString() ?? '');
    final spo2Ctrl = TextEditingController(text: existing?.spO2?.toString() ?? '');
    final bp1Ctrl = TextEditingController(text: existing?.bloodPressureOne?.toInt().toString() ?? '');
    final bp2Ctrl = TextEditingController(text: existing?.bloodPressureTwo?.toInt().toString() ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    final timeStr = slotIndex != null ? _timeSlots[slotIndex].time : '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(existing != null ? 'تعديل العلامات - $timeStr' : 'إضافة علامات - $timeStr', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _modalField(bp1Ctrl, 'الضغط العالي (Systolic)', TextInputType.number),
              const SizedBox(height: 8),
              _modalField(bp2Ctrl, 'الضغط المنخفض (Diastolic)', TextInputType.number),
              const SizedBox(height: 8),
              _modalField(pulseCtrl, 'النبض (Pulse)', TextInputType.number),
              const SizedBox(height: 8),
              _modalField(tempCtrl, 'الحرارة (C)', TextInputType.number),
              const SizedBox(height: 8),
              _modalField(respCtrl, 'التنفس (Resp)', TextInputType.number),
              const SizedBox(height: 8),
              _modalField(spo2Ctrl, 'الأكسجين SpO2', TextInputType.number),
              const SizedBox(height: 8),
              _modalField(notesCtrl, 'ملاحظات', TextInputType.text),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.tajawal())),
          ElevatedButton(
            onPressed: () async {
              final now = DateTime.now();
              final dateStr = intl.DateFormat('yyyy-MM-dd').format(_selectedDate);
              final vital = VitalSign(
                docSrl: existing?.docSrl,
                docNo: _patient!.docNo,
                docSrlAdmt: _patient!.docSrl,
                patientNo: _patient!.patientNo,
                age: _patient!.age,
                ageType: _patient!.ageType,
                roomNo: _patient!.roomNo,
                bedNo: _patient!.bedNo,
                roomSer: _patient!.roomService,
                buildingNo: _patient!.buldNo,
                docTime: '${dateStr}T${timeStr}:00',
                temperature: double.tryParse(tempCtrl.text),
                pulseRate: double.tryParse(pulseCtrl.text),
                respirationRate: double.tryParse(respCtrl.text),
                spO2: double.tryParse(spo2Ctrl.text),
                bloodPressureOne: double.tryParse(bp1Ctrl.text),
                bloodPressureTwo: double.tryParse(bp2Ctrl.text),
                notes: notesCtrl.text.trim(),
              );

              if (existing != null && existing.docSrl != null) {
                final res = await ApiService.updateVitalSign(vital);
                if (res['success'] != true && res['message'] == 'OFFLINE') {
                  await DBHelper.insertVital(vital);
                }
              } else {
                final res = await ApiService.saveVitalSign(vital);
                if (res['success'] != true && res['message'] == 'OFFLINE') {
                  await DBHelper.insertVital(vital);
                }
              }
              Navigator.pop(ctx);
              _loadTable();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(existing != null ? 'تم التعديل بنجاح' : 'تم الحفظ بنجاح'), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(primary: const Color(0xFF009688)),
            child: Text('حفظ', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _deleteVital(VitalSign vital) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد الحذف', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        content: Text('هل تريد حذف هذا السجل؟', style: GoogleFonts.tajawal()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء', style: GoogleFonts.tajawal())),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(primary: Colors.red),
            child: Text('حذف', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true && vital.docSrl != null) {
      await ApiService.deleteVitalSign(vital.docSrl!);
      _loadTable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF009688),
        title: Text('العلامات الحيوية', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Column(
        children: [
          // Patient & Controls
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showAdmissionsModal,
                        icon: const Icon(Icons.person_search, color: Colors.white, size: 18),
                        label: Text(_patient != null ? _patient!.patientName : 'اختر مريض', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(primary: const Color(0xFF009688), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      ),
                    ),
                  ],
                ),
                if (_patient != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('الغرفة: ${_patient!.roomNo ?? '-'}', style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('السرير: ${_patient!.bedNo ?? '-'}', style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('العمر: ${_patient!.age ?? '-'} ${_patient!.ageTypeText}', style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)));
                          if (picked != null) setState(() { _selectedDate = picked; _loadTable(); });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                          child: Row(children: [
                            const Icon(Icons.calendar_today, size: 18, color: Color(0xFF009688)),
                            const SizedBox(width: 8),
                            Text(intl.DateFormat('yyyy-MM-dd').format(_selectedDate), style: GoogleFonts.tajawal(fontSize: 13)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _interval,
                        decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        items: [15, 30, 60].map((v) => DropdownMenuItem(value: v, child: Text('$v دقيقة', style: GoogleFonts.tajawal(fontSize: 12)))).toList(),
                        onChanged: (v) { if (v != null) setState(() { _interval = v; _loadTable(); }); },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Time Slot Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _patient == null
                    ? Center(child: Text('اختر مريضاً لعرض الجدول', style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 16)))
                    : _timeSlots.isEmpty
                        ? Center(child: Text('لا توجد بيانات', style: GoogleFonts.tajawal(color: Colors.grey)))
                        : _buildTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 8,
          headingRowColor: MaterialStateProperty.all(const Color(0xFFE0F2F1)),
          columns: [
            DataColumn(label: Text('الوقت', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('الحرارة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('النبض', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('التنفس', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('SpO2', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('الضغط', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('إجراء', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
          rows: _timeSlots.map((slot) {
            final hasData = slot.vital != null;
            return DataRow(
              color: MaterialStateProperty.all(
                hasData ? (slot.isSynced ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0)) : null,
              ),
              cells: [
                DataCell(Text(slot.time, style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold))),
                DataCell(Text(hasData ? '${slot.vital!.temperature ?? '-'}' : '-', style: GoogleFonts.tajawal(fontSize: 12))),
                DataCell(Text(hasData ? '${slot.vital!.pulseRate?.toInt() ?? '-'}' : '-', style: GoogleFonts.tajawal(fontSize: 12))),
                DataCell(Text(hasData ? '${slot.vital!.respirationRate?.toInt() ?? '-'}' : '-', style: GoogleFonts.tajawal(fontSize: 12))),
                DataCell(Text(hasData ? '${slot.vital!.spO2?.toInt() ?? '-'}' : '-', style: GoogleFonts.tajawal(fontSize: 12))),
                DataCell(Text(hasData ? slot.vital!.bpText : '-', style: GoogleFonts.tajawal(fontSize: 12))),
                DataCell(
                  hasData
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: Color(0xFFF39C12)),
                              onPressed: () => _showVitalsEntryModal(existing: slot.vital, slotIndex: _timeSlots.indexOf(slot)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: Color(0xFFE74C3C)),
                              onPressed: () => _deleteVital(slot.vital!),
                            ),
                          ],
                        )
                      : IconButton(
                          icon: const Icon(Icons.add_circle, size: 22, color: Color(0xFF009688)),
                          onPressed: () => _showVitalsEntryModal(slotIndex: _timeSlots.indexOf(slot)),
                        ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _modalField(TextEditingController ctrl, String label, TextInputType type) {
    return TextField(
      controller: ctrl, keyboardType: type,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
    );
  }
}

class _TimeSlotRow {
  final String time;
  VitalSign? vital;
  bool isSynced;
  _TimeSlotRow({required this.time, this.vital, this.isSynced = false});
}
