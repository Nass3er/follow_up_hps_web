import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../services/auth_service.dart';
import '../services/db_helper.dart';
import 'patient_dashboard_view.dart';
import 'vitals_view.dart';
import 'intake_output_view.dart';
import 'doctor_orders_view.dart';
import 'lab_results_view.dart';
import 'settings_view.dart';
import 'sync_view.dart';
import 'login_view.dart';

class HomeDashboardView extends StatefulWidget {
  const HomeDashboardView({super.key});

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView> {
  String _companyName = 'نظام متابعة المرضى (HPS)';
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final name = await AuthService.getCompanyName();
    final count = await DBHelper.getPendingSyncCount();
    if (mounted) setState(() { _companyName = name; _pendingCount = count; });
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginView()));
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = intl.DateFormat('yyyy/MM/dd', 'ar').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0), elevation: 2, automaticallyImplyLeading: false,
        title: Text(_companyName, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text('التاريخ: $formattedDate', style: GoogleFonts.tajawal(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500))),
          ),
          TextButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, color: Colors.white, size: 18),
            label: Text('تسجيل خروج', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مرحباً بك ...', style: GoogleFonts.tajawal(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50))),
            const SizedBox(height: 4),
            Text('اختر أحد الخدمات التالية للبدء بالعمل:', style: GoogleFonts.tajawal(fontSize: 14, color: const Color(0xFF7F8C8D))),
            const SizedBox(height: 16),
            if (_pendingCount > 0)
              GestureDetector(
                onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const SyncView())); _loadData(); },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFB74D))),
                  child: Row(children: [
                    const Icon(Icons.sync_problem, color: Color(0xFFE67E22), size: 28),
                    const SizedBox(width: 14),
                    Expanded(child: Text('لديك $_pendingCount سجلات تحتاج إلى مزامنة', style: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFFE67E22)))),
                    const Icon(Icons.arrow_back, color: Color(0xFFE67E22)),
                  ]),
                ),
              ),
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.95,
              children: [
                _buildCard('متابعة مريض', 'البحث عن مريض ومتابعة حالته', Icons.person_search, const Color(0xFF1565C0), border: Border.all(color: const Color(0xFF1565C0), width: 2), gradient: const LinearGradient(colors: [Color(0xFFE3F2FD), Colors.white]), badge: 'جديد', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientDashboardView()))),
                _buildCard('العلامات الحيوية', 'تسجيل علامات المريض الحيوية', Icons.monitor_heart, const Color(0xFF009688), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VitalsView()))),
                _buildCard('السوائل (I&O)', 'متابعة السوائل والمفرزات', Icons.water_drop, const Color(0xFF00ACC1), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IntakeOutputView()))),
                _buildCard('أوامر الأطباء', 'إدارة أوامر الأطباء', Icons.assignment, const Color(0xFF43A047), border: Border.all(color: const Color(0xFF55EFC4), width: 2), backgroundColor: const Color(0xFFE5FDF5), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorOrdersView()))),
                _buildCard('نتائج الفحوصات', 'عرض نتائج التحاليل والفحوصات', Icons.science, const Color(0xFF7B1FA2), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LabResultsView()))),
                _buildCard('المزامنة', 'مزامنة السجلات المحلية', Icons.sync, const Color(0xFFFB8C00), badge: _pendingCount > 0 ? '$_pendingCount' : null, onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const SyncView())); _loadData(); }),
                _buildCard('الإعدادات', 'إدارة البيانات والإعدادات', Icons.settings, const Color(0xFF546E7A), onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsView())); _loadData(); }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, String subtitle, IconData icon, Color color, {Border? border, Gradient? gradient, Color? backgroundColor, String? badge, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white, gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        border: border ?? Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Stack(
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(height: 8),
                  Text(title, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF2C3E50))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.tajawal(fontSize: 11, color: const Color(0xFF7F8C8D), height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                ]),
                if (badge != null)
                  Positioned(
                    top: 0, left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                      child: Text(badge, style: GoogleFonts.tajawal(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
