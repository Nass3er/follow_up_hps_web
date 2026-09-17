import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/patient.dart';
import '../models/doctor_order.dart';
import '../services/api_service.dart';

class LabResultsView extends StatefulWidget {
  final Patient? activePatient;
  const LabResultsView({super.key, this.activePatient});

  @override
  State<LabResultsView> createState() => _LabResultsViewState();
}

class _LabResultsViewState extends State<LabResultsView> {
  Patient? _patient;
  List<LabResult> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.activePatient != null) {
      _patient = widget.activePatient;
      _loadResults();
    }
  }

  Future<void> _loadResults() async {
    if (_patient == null) return;
    setState(() => _isLoading = true);
    try {
      final list = await ApiService.getLabResults(_patient!.docSrl);
      if (mounted) setState(() => _results = list);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B1FA2),
        title: Text('نتائج الفحوصات', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: _patient == null
          ? Center(child: Text('لم يتم تحديد مريض', style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 16)))
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Color(0xFF7B1FA2)),
                      const SizedBox(width: 8),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_patient!.patientName, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('رقم الدخول: ${_patient!.docNo}', style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey)),
                        ],
                      )),
                      if (!_isLoading)
                        ElevatedButton(
                          onPressed: _loadResults,
                          style: ElevatedButton.styleFrom(primary: const Color(0xFF7B1FA2)),
                          child: Text('تحديث', style: GoogleFonts.tajawal(color: Colors.white, fontSize: 12)),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _results.isEmpty
                          ? Center(child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.science_outlined, size: 60, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text('لا توجد نتائج فحوصات', style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 16)),
                              ],
                            ))
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _results.length,
                              itemBuilder: (_, idx) {
                                final r = _results[idx];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ExpansionTile(
                                    leading: CircleAvatar(backgroundColor: const Color(0xFFEDE7F6), child: Icon(Icons.science, color: const Color(0xFF7B1FA2))),
                                    title: Text('طلب #${r.docNo}', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                                    subtitle: Text('التاريخ: ${r.docDate ?? '-'} | الطبيب: ${r.doctorName ?? '-'}', style: GoogleFonts.tajawal(fontSize: 12)),
                                    children: [
                                      if (r.details != null)
                                        ...r.details!.map((d) => Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                          child: Row(
                                            children: [
                                              Expanded(flex: 3, child: Text(d.itemName, style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold))),
                                              Expanded(flex: 2, child: Text(d.result, style: GoogleFonts.tajawal(fontSize: 12, color: const Color(0xFF1565C0)))),
                                              Expanded(flex: 2, child: Text('${d.normalValue} ${d.unit}', style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[600]))),
                                            ],
                                          ),
                                        )),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}
