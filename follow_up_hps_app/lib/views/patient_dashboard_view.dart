import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/patient.dart';
import '../services/api_service.dart';
import '../services/db_helper.dart';
import 'vitals_view.dart';
import 'intake_output_view.dart';
import 'doctor_orders_view.dart';
import 'lab_results_view.dart';

class PatientDashboardView extends StatefulWidget {
  const PatientDashboardView({super.key});

  @override
  State<PatientDashboardView> createState() => _PatientDashboardViewState();
}

class _PatientDashboardViewState extends State<PatientDashboardView> {
  Patient? _activePatient;
  List<Admission> _admissions = [];
  bool _isLoadingAdmissions = false;

  @override
  void initState() {
    super.initState();
    _loadAdmissions();
  }

  Future<void> _loadAdmissions() async {
    setState(() => _isLoadingAdmissions = true);
    try {
      final list = await ApiService.getAdmissions();
      if (mounted) setState(() => _admissions = list);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingAdmissions = false);
  }

  Future<void> _selectAdmission(Admission adm) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final patient = await ApiService.getAdmissionDetails(adm.docNo, adm.docSerial);
    Navigator.pop(context);
    if (patient != null) {
      await DBHelper.savePatient(patient);
      setState(() => _activePatient = patient);
    } else {
      final local = await DBHelper.getPatient(adm.docNo);
      if (local != null) {
        setState(() => _activePatient = local);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر جلب بيانات المريض')));
      }
    }
  }

  void _showSearchModal() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final searchCtrl = TextEditingController();
        List<Admission> filtered = List.from(_admissions);
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollCtrl) => Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1565C0),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(height: 12),
                        Text('قائمة الدخول النشطة', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: searchCtrl,
                          onChanged: (val) {
                            setModalState(() {
                              filtered = _admissions.where((a) =>
                                a.patientName.contains(val) || a.docNo.toString().contains(val)
                              ).toList();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'بحث بالاسم أو رقم الدخول...',
                            hintStyle: GoogleFonts.tajawal(color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF1565C0)),
                            filled: true, fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(child: Text('لا توجد نتائج', style: GoogleFonts.tajawal(color: Colors.grey)))
                        : ListView.builder(
                            controller: scrollCtrl, itemCount: filtered.length,
                            itemBuilder: (_, idx) {
                              final adm = filtered[idx];
                              return ListTile(
                                leading: CircleAvatar(backgroundColor: const Color(0xFFE3F2FD), child: Icon(Icons.person, color: const Color(0xFF1565C0))),
                                title: Text(adm.patientName, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                                subtitle: Text('رقم الدخول: ${adm.docNo} | التاريخ: ${adm.date ?? '-'}', style: GoogleFonts.tajawal(fontSize: 12)),
                                trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
                                onTap: () { Navigator.pop(ctx); _selectAdmission(adm); },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: Text('متابعة مريض', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _isLoadingAdmissions ? null : _showSearchModal,
          ),
        ],
      ),
      body: _activePatient != null ? _buildPatientView() : _buildWelcomeView(),
    );
  }

  Widget _buildWelcomeView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('ابحث عن مريض نشط لعرض بياناته', style: GoogleFonts.tajawal(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isLoadingAdmissions ? null : _showSearchModal,
            icon: const Icon(Icons.search, color: Colors.white),
            label: Text('بحث عن مريض', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(primary: const Color(0xFF1565C0), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientView() {
    final p = _activePatient!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1E88E5)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26, backgroundColor: Colors.white24,
                      child: Icon(p.gender == 1 ? Icons.male : p.gender == 2 ? Icons.female : Icons.person, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.patientName, style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('رقم الملف: ${p.patientNo} | رقم الدخول: ${p.docNo}', style: GoogleFonts.tajawal(color: Colors.white70, fontSize: 12)),
                      ]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => setState(() => _activePatient = null),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 24),
                Wrap(
                  spacing: 16, runSpacing: 8,
                  children: [
                    _infoChip('الطبيب', p.doctorName ?? '-'),
                    _infoChip('الغرفة/السرير', '${p.roomNo ?? '-'}/${p.bedNo ?? '-'}'),
                    _infoChip('العمر', '${p.age ?? '-'} ${p.ageTypeText}'),
                    _infoChip('الجنس', p.genderText),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text('الإجراءات السريعة:', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(child: _actionBtn('العلامات الحيوية', Icons.monitor_heart, const Color(0xFF009688), () => Navigator.push(context, MaterialPageRoute(builder: (_) => VitalsView(activePatient: p))))),
              const SizedBox(width: 8),
              Expanded(child: _actionBtn('السوائل (I&O)', Icons.water_drop, const Color(0xFF00ACC1), () => Navigator.push(context, MaterialPageRoute(builder: (_) => IntakeOutputView(activePatient: p))))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _actionBtn('أوامر الطبيب', Icons.assignment, const Color(0xFF43A047), () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorOrdersView(activePatient: p))))),
              const SizedBox(width: 8),
              Expanded(child: _actionBtn('نتائج الفحوصات', Icons.science, const Color(0xFF7B1FA2), () => Navigator.push(context, MaterialPageRoute(builder: (_) => LabResultsView(activePatient: p))))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.tajawal(color: Colors.white70, fontSize: 11)),
      Text(value, style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
    ]);
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(label, style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
      style: ElevatedButton.styleFrom(primary: color, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }
}
