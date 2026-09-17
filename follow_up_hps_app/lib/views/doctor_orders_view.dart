import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../models/patient.dart';
import '../models/doctor_order.dart';
import '../services/api_service.dart';
import '../services/db_helper.dart';

class DoctorOrdersView extends StatefulWidget {
  final Patient? activePatient;
  const DoctorOrdersView({super.key, this.activePatient});

  @override
  State<DoctorOrdersView> createState() => _DoctorOrdersViewState();
}

class _DoctorOrdersViewState extends State<DoctorOrdersView> {
  Patient? _patient;
  List<Admission> _admissions = [];
  List<ProcedureType> _procedureTypes = [];
  List<UsageMethod> _usageMethods = [];
  Map<int, List<OrderItem>> _itemsByType = {};
  int _selectedProcedureType = 1;
  List<OrderDetailItem> _detailItems = [];
  int _priorityNo = 1;
  final _notesCtrl = TextEditingController();
  final _refNoCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.activePatient != null) _patient = widget.activePatient;
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    final types = await ApiService.getProcedureTypes();
    final methods = await ApiService.getUsageMethods();
    for (var t in types) {
      final items = await ApiService.getItems(t.procedureType);
      _itemsByType[t.procedureType] = items;
    }
    if (mounted) setState(() { _procedureTypes = types; _usageMethods = methods; });
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
              decoration: const BoxDecoration(color: Color(0xFF43A047), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: Column(children: [
                Text('اختر مريض', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
              itemBuilder: (_, i) => ListTile(
                title: Text(filtered[i].patientName, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                subtitle: Text('رقم الدخول: ${filtered[i].docNo}', style: GoogleFonts.tajawal(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final p = await ApiService.getAdmissionDetails(filtered[i].docNo, filtered[i].docSerial);
                  if (p != null) setState(() => _patient = p);
                },
              ),
            )),
          ]),
        ),
      ),
    );
  }

  void _showItemsModal() {
    final items = _itemsByType[_selectedProcedureType] ?? [];
    final searchCtrl = TextEditingController();
    List<OrderItem> filtered = List.from(items);
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.9, expand: false,
          builder: (_, scrollCtrl) => Column(children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Color(0xFF43A047), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: Column(children: [
                Text('اختر عنصر', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                TextField(
                  controller: searchCtrl,
                  onChanged: (v) => setModalState(() => filtered = items.where((i) => i.itemName.contains(v) || i.itemCode.contains(v)).toList()),
                  decoration: InputDecoration(hintText: 'بحث بالاسم أو الكود...', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                ),
              ]),
            ),
            Expanded(child: ListView.builder(
              controller: scrollCtrl, itemCount: filtered.length,
              itemBuilder: (_, i) {
                final item = filtered[i];
                return ListTile(
                  title: Text(item.itemName, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('كود: ${item.itemCode} | السعر: ${item.price}', style: GoogleFonts.tajawal(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _detailItems.add(OrderDetailItem(
                        itemCode: item.itemCode,
                        pSize: item.pSize ?? 0,
                        price: item.price,
                        unit: item.unit,
                        quantity: 1,
                      ));
                    });
                  },
                );
              },
            )),
          ]),
        ),
      ),
    );
  }

  Future<void> _saveOrder() async {
    if (_patient == null || _detailItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر مريض وأضف عناصر على الأقل')));
      return;
    }
    setState(() => _isLoading = true);

    final dateStr = intl.DateFormat('yyyy-MM-dd').format(DateTime.now());
    final order = DoctorOrder(
      procedureType: _selectedProcedureType,
      docDate: dateStr,
      priorityNo: _priorityNo,
      notes: _notesCtrl.text.trim(),
      refNo: _refNoCtrl.text.trim(),
      details: _detailItems,
    );

    final res = await ApiService.saveDoctorOrder(order,
      branchNo: 1, admissionDocNo: _patient!.docNo, admissionDocSrl: _patient!.docSrl,
      patientNo: _patient!.patientNo, roomSer: _patient!.roomService ?? 0,
      roomNo: _patient!.roomNo ?? 0, deptNo: _patient!.deptNo ?? 0,
      buildNo: _patient!.buldNo ?? 0, bedNo: _patient!.bedNo ?? 0,
      gender: _patient!.gender ?? 0, age: _patient!.age ?? '',
      ageType: _patient!.ageType ?? 1, doctorNo: _patient!.dctrNo ?? '',
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['success'] == true ? 'تم الحفظ بنجاح' : 'فشل الحفظ: ${res['message']}'),
          backgroundColor: res['success'] == true ? Colors.green : Colors.red,
        ),
      );
      if (res['success'] == true) {
        setState(() { _detailItems = []; _notesCtrl.clear(); _refNoCtrl.clear(); });
      }
    }
  }

  void _showHistoryModal() async {
    if (_patient == null) return;
    final history = await ApiService.getDoctorOrderHistory(_patient!.docSrl);
    if (!mounted) return;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.9, expand: false,
        builder: (_, scrollCtrl) => Column(children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Color(0xFF43A047), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Text('سجل الأوامر', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: history.isEmpty
                ? Center(child: Text('لا توجد أوامر سابقة', style: GoogleFonts.tajawal(color: Colors.grey)))
                : ListView.builder(
                    controller: scrollCtrl, itemCount: history.length,
                    itemBuilder: (_, i) {
                      final o = history[i];
                      return ListTile(
                        leading: const Icon(Icons.assignment, color: Color(0xFF43A047)),
                        title: Text(o.procedureTypeName ?? '-', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                        subtitle: Text('رقم: ${o.docNo} | التاريخ: ${o.docDate ?? '-'}', style: GoogleFonts.tajawal(fontSize: 12)),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final details = await ApiService.getDoctorOrderDetails(o.docSrl!);
                          if (details != null && mounted) _showOrderDetails(details);
                        },
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }

  void _showOrderDetails(DoctorOrder order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('تفاصيل الأمر #${order.docNo}', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('النوع: ${order.procedureTypeName ?? '-'}', style: GoogleFonts.tajawal()),
              Text('الأولوية: ${order.priorityText}', style: GoogleFonts.tajawal()),
              if (order.notes != null && order.notes!.isNotEmpty)
                Text('ملاحظات: ${order.notes}', style: GoogleFonts.tajawal()),
              const Divider(),
              if (order.details != null)
                ...order.details!.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• ${d.itemCode} - الكمية: ${d.quantity.toStringAsFixed(0)}', style: GoogleFonts.tajawal(fontSize: 13)),
                )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إغلاق', style: GoogleFonts.tajawal())),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF43A047),
        title: Text('أوامر الأطباء', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.history, color: Colors.white), onPressed: _showHistoryModal),
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _isLoading ? null : _saveOrder,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Selection
            ElevatedButton.icon(
              onPressed: _showAdmissionsModal,
              icon: const Icon(Icons.person_search, color: Colors.white, size: 18),
              label: Text(_patient != null ? _patient!.patientName : 'اختر مريض', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(primary: const Color(0xFF43A047), minimumSize: const Size(double.infinity, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 12),

            // Procedure Type
            DropdownButtonFormField<int>(
              value: _selectedProcedureType,
              decoration: InputDecoration(
                labelText: 'نوع الإجراء',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: _procedureTypes.map((t) => DropdownMenuItem(
                value: t.procedureType,
                child: Text(t.procedureTypeName, style: GoogleFonts.tajawal(fontSize: 14)),
              )).toList(),
              onChanged: (v) { if (v != null) setState(() => _selectedProcedureType = v); },
            ),
            const SizedBox(height: 12),

            // Priority
            Row(
              children: [
                Expanded(child: Text('الأولوية:', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold))),
                ChoiceChip(
                  label: Text('عادي', style: GoogleFonts.tajawal(fontSize: 12)),
                  selected: _priorityNo == 1,
                  selectedColor: Colors.green[100],
                  onSelected: (_) => setState(() => _priorityNo = 1),
                ),
                const SizedBox(width: 4),
                ChoiceChip(
                  label: Text('عاجل', style: GoogleFonts.tajawal(fontSize: 12)),
                  selected: _priorityNo == 2,
                  selectedColor: Colors.orange[100],
                  onSelected: (_) => setState(() => _priorityNo = 2),
                ),
                const SizedBox(width: 4),
                ChoiceChip(
                  label: Text('حرج', style: GoogleFonts.tajawal(fontSize: 12)),
                  selected: _priorityNo == 3,
                  selectedColor: Colors.red[100],
                  onSelected: (_) => setState(() => _priorityNo = 3),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Notes & Ref
            TextField(controller: _notesCtrl, decoration: InputDecoration(labelText: 'ملاحظات', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 8),
            TextField(controller: _refNoCtrl, decoration: InputDecoration(labelText: 'رقم المرجع', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 16),

            // Add Item Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _patient != null ? _showItemsModal : null,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text('إضافة عنصر', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(primary: const Color(0xFF26A69A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ),
            const SizedBox(height: 12),

            // Detail Items Table
            if (_detailItems.isNotEmpty)
              Text('العناصر المضافة (${_detailItems.length}):', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            ...List.generate(_detailItems.length, (i) {
              final item = _detailItems[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: const Color(0xFFE8F5E9), child: Text('${i + 1}', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 12))),
                  title: Text(item.itemCode, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('السعر: ${item.price} | الوحدة: ${item.unit}', style: GoogleFonts.tajawal(fontSize: 11)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 60,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(text: item.quantity.toStringAsFixed(0)),
                          onChanged: (v) {
                            final qty = double.tryParse(v) ?? 1;
                            setState(() => _detailItems[i] = OrderDetailItem(
                              itemCode: item.itemCode, pSize: item.pSize,
                              price: item.price, unit: item.unit, quantity: qty,
                              expectedDate: item.expectedDate, notes: item.notes,
                              mthdUse: item.mthdUse, mthdUseDsc: item.mthdUseDsc,
                              durtion: item.durtion, durTyp: item.durTyp,
                            ));
                          },
                          decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
                          style: GoogleFonts.tajawal(fontSize: 12),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.red),
                        onPressed: () => setState(() => _detailItems.removeAt(i)),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
