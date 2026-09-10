import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final _docNoCtrl = TextEditingController();
  List<DoctorOrder> _ordersList = [];
  String _selectedCategory = 'all';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.activePatient != null) {
      _docNoCtrl.text = widget.activePatient!.docNo.toString();
      _loadOrders();
    }
  }

  Future<void> _loadOrders() async {
    final docNo = int.tryParse(_docNoCtrl.text.trim());
    if (docNo == null) return;

    setState(() => _isLoading = true);

    try {
      final online = await ApiService.getDoctorOrders(docNo);
      await DBHelper.saveDoctorOrders(online);
      if (mounted) setState(() => _ordersList = online);
    } catch (_) {
      final offline = await DBHelper.getDoctorOrdersForPatient(docNo);
      if (mounted) setState(() => _ordersList = offline);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _executeOrder(DoctorOrder order) async {
    final notesCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('تأكيد تنفيذ الأمر الطبي', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل تم إعطاء / تنفيذ (${order.itemName}) للمريض؟', style: GoogleFonts.tajawal(fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'ملاحظات التنفيذ (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء', style: GoogleFonts.tajawal())),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(primary: const Color(0xFF43A047)),
            child: Text('تأكيد التنفيذ ✅', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notes = notesCtrl.text.trim();
      bool synced = false;
      try {
        synced = await ApiService.markDoctorOrderExecuted(order.id, notes);
      } catch (_) {
        synced = false;
      }

      if (synced) {
        await DBHelper.updateDoctorOrderExecution(order.id, notes);
        await DBHelper.markDoctorOrderSynced(order.id);
      } else {
        await DBHelper.updateDoctorOrderExecution(order.id, notes);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(synced ? 'تم رفع إنجاز الأمر للسيرفر بنجاح ✅' : 'تم حفظ الإنجاز أوفلاين وسيطرح للمزامنة 📱'),
            backgroundColor: synced ? Colors.green : Colors.orange[800],
          ),
        );
        _loadOrders();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _ordersList.where((o) {
      if (_selectedCategory == 'all') return true;
      return o.category == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF43A047),
        title: Text('أوامر الأطباء والوصفات', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                      onPressed: _loadOrders,
                      style: ElevatedButton.styleFrom(
                        primary: const Color(0xFF43A047),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      child: Text('جلب الأوامر', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Categories Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('الكل', 'all'),
                  _buildFilterChip('الأدوية (Medication)', 'medication'),
                  _buildFilterChip('الفحوصات والأشعة', 'lab'),
                  _buildFilterChip('ملاحظات التمريض', 'nursing'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Orders List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Text('لا توجد أوامر طبية مسجلة لهذه الفئة', style: GoogleFonts.tajawal(color: Colors.grey)),
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (ctx, idx) {
                            final order = filtered[idx];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: order.isExecuted ? Colors.green[100] : Colors.amber[100],
                                      child: Icon(
                                        order.isExecuted ? Icons.check_circle : Icons.pending_actions,
                                        color: order.isExecuted ? Colors.green[800] : Colors.amber[800],
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            order.itemName,
                                            style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'الجرعة: ${order.dosage ?? "حسب إرشاد الطبيب"} | التكرار: ${order.frequency ?? "-"}',
                                            style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[700]),
                                          ),
                                          Text(
                                            'الطبيب: ${order.doctorName ?? "غير محدد"} | التاريخ: ${order.orderDate ?? "-"}',
                                            style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[500]),
                                          ),
                                          if (order.isExecuted) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'تم التنفيذ: ${order.executedAt ?? ""} (${order.executionNotes ?? "بدون ملاحظات"})',
                                              style: GoogleFonts.tajawal(fontSize: 11, color: Colors.green[800], fontWeight: FontWeight.bold),
                                            ),
                                          ]
                                        ],
                                      ),
                                    ),
                                    if (!order.isExecuted)
                                      ElevatedButton(
                                        onPressed: () => _executeOrder(order),
                                        style: ElevatedButton.styleFrom(
                                          primary: const Color(0xFF43A047),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        child: Text('تنفيذ 💉', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: FilterChip(
        label: Text(label, style: GoogleFonts.tajawal(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
        selected: isSelected,
        selectedColor: const Color(0xFF43A047),
        backgroundColor: Colors.white,
        onSelected: (val) {
          setState(() => _selectedCategory = value);
        },
      ),
    );
  }
}
