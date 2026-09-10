import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/patient.dart';
import '../models/vital_sign.dart';
import '../models/intake_output.dart';
import '../services/api_service.dart';
import '../services/db_helper.dart';
import 'vitals_view.dart';
import 'intake_output_view.dart';
import 'doctor_orders_view.dart';

class PatientDashboardView extends StatefulWidget {
  final Patient? initialPatient;

  const PatientDashboardView({super.key, this.initialPatient});

  @override
  State<PatientDashboardView> createState() => _PatientDashboardViewState();
}

class _PatientDashboardViewState extends State<PatientDashboardView> {
  final _searchController = TextEditingController();
  Patient? _activePatient;
  List<Patient> _searchResults = [];
  bool _isSearching = false;
  List<VitalSign> _vitalsList = [];
  List<IntakeOutputRecord> _ioList = [];
  bool _isLoadingPatientData = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPatient != null) {
      _selectPatient(widget.initialPatient!);
    }
  }

  Future<void> _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final results = await ApiService.searchPatients(query);
      if (mounted) {
        setState(() => _searchResults = results);
      }
    } catch (_) {
      final docNo = int.tryParse(query);
      if (docNo != null) {
        final local = await DBHelper.getPatient(docNo);
        if (local != null && mounted) {
          setState(() => _searchResults = [local]);
        }
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _selectPatient(Patient patient) async {
    setState(() {
      _activePatient = patient;
      _searchResults = [];
      _isLoadingPatientData = true;
    });

    await DBHelper.savePatient(patient);

    try {
      final vitals = await ApiService.getVitalsHistory(patient.docNo);
      final io = await ApiService.getIOHistory(patient.docNo);
      if (mounted) {
        setState(() {
          _vitalsList = vitals;
          _ioList = io;
        });
      }
    } catch (_) {
      final vitals = await DBHelper.getVitalsForPatient(patient.docNo);
      final io = await DBHelper.getIOForPatient(patient.docNo);
      if (mounted) {
        setState(() {
          _vitalsList = vitals;
          _ioList = io;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingPatientData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: Text(
          'متابعة مريض',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (_) => _handleSearch(),
                        decoration: InputDecoration(
                          hintText: 'أدخل رقم الدخول / رقم ملف المريض / الاسم...',
                          hintStyle: GoogleFonts.tajawal(fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF1565C0)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isSearching ? null : _handleSearch,
                      style: ElevatedButton.styleFrom(
                        primary: const Color(0xFF1565C0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      child: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text('بحث', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

            // Search Results List
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('نتائج البحث:', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                itemBuilder: (ctx, idx) {
                  final p = _searchResults[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE3F2FD),
                        child: Icon(Icons.person, color: Color(0xFF1565C0)),
                      ),
                      title: Text(p.patName, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                      subtitle: Text('رقم الدخول: ${p.docNo} | الغرفة: ${p.roomNo ?? '-'} | السرير: ${p.bedNo ?? '-'}', style: GoogleFonts.tajawal(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _selectPatient(p),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 20),

            // Active Patient Card Details
            if (_activePatient != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _activePatient!.patName,
                                style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                'رقم الملف: ${_activePatient!.patNo} | رقم الدخول: ${_activePatient!.docNo}',
                                style: GoogleFonts.tajawal(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPatientDetailChip('الطبيب', _activePatient!.doctorName ?? 'غير محدد'),
                        _buildPatientDetailChip('الغرفة/السرير', '${_activePatient!.roomNo ?? '-'}/${_activePatient!.bedNo ?? '-'}'),
                        _buildPatientDetailChip('العمر/الجنس', '${_activePatient!.age ?? '-'}/${_activePatient!.gender ?? '-'}'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Text('الإجراءات السريعة للمريض:', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      label: 'العلامات الحيوية',
                      icon: Icons.monitor_heart,
                      color: const Color(0xFF009688),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => VitalsView(activePatient: _activePatient)),
                        );
                        _selectPatient(_activePatient!);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      label: 'السوائل (I & O)',
                      icon: Icons.water_drop,
                      color: const Color(0xFF00ACC1),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => IntakeOutputView(activePatient: _activePatient)),
                        );
                        _selectPatient(_activePatient!);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      label: 'أوامر الطبيب',
                      icon: Icons.assignment,
                      color: const Color(0xFF43A047),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DoctorOrdersView(activePatient: _activePatient)),
                        );
                        _selectPatient(_activePatient!);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Patient Recent Data Overview
              if (_isLoadingPatientData)
                const Center(child: CircularProgressIndicator())
              else ...[
                // Latest Vitals
                _buildSummarySection(
                  title: 'آخر علامات حيوية مسجلة',
                  icon: Icons.favorite,
                  child: _vitalsList.isEmpty
                      ? Text('لا توجد علامات حيوية مسجلة مؤخراً.', style: GoogleFonts.tajawal(color: Colors.grey[600], fontSize: 13))
                      : Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildMetric('الضغط', '${_vitalsList.first.sysBp?.toInt() ?? '-'}/${_vitalsList.first.diaBp?.toInt() ?? '-'}'),
                                _buildMetric('النبض', '${_vitalsList.first.pulse?.toInt() ?? '-'} bpm'),
                                _buildMetric('الحرارة', '${_vitalsList.first.temp ?? '-'} °C'),
                                _buildMetric('الأكسجين', '${_vitalsList.first.o2Sat?.toInt() ?? '-'}%'),
                              ],
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 16),

                // Intake & Output Summary
                _buildSummarySection(
                  title: 'ملخص السوائل (Intake & Output)',
                  icon: Icons.water_drop,
                  child: Builder(
                    builder: (context) {
                      final totalIntake = _ioList.where((e) => e.category == 'intake').fold<double>(0.0, (s, e) => s + e.amount);
                      final totalOutput = _ioList.where((e) => e.category == 'output').fold<double>(0.0, (s, e) => s + e.amount);
                      final balance = totalIntake - totalOutput;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetric('الداخل (Intake)', '$totalIntake ml', color: Colors.blue),
                          _buildMetric('الخارج (Output)', '$totalOutput ml', color: Colors.orange),
                          _buildMetric('الميزانية (Balance)', '$balance ml', color: balance >= 0 ? Colors.green : Colors.red),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.person_search_rounded, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      'ابحث عن مريض بالاسم أو رقم الدخول لعرض بياناته',
                      style: GoogleFonts.tajawal(color: Colors.grey[600], fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPatientDetailChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.tajawal(color: Colors.white70, fontSize: 11)),
        Text(value, style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, {required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        primary: color,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSummarySection({required String title, required IconData icon, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1565C0), size: 20),
                const SizedBox(width: 8),
                Text(title, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, {Color color = Colors.black87}) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
