import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../services/auth_service.dart';
import '../services/db_helper.dart';
import 'patient_dashboard_view.dart';
import 'vitals_view.dart';
import 'intake_output_view.dart';
import 'doctor_orders_view.dart';
import 'settings_view.dart';
import 'sync_view.dart';
import 'login_view.dart';

class HomeDashboardView extends StatefulWidget {
  const HomeDashboardView({super.key});

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView> {
  String _companyName = '🏥 نظام متابعة المرضى (HPS)';
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final name = await AuthService.getCompanyName();
    final count = await DBHelper.getPendingSyncCount();
    if (mounted) {
      setState(() {
        _companyName = name;
        _pendingCount = count;
      });
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = intl.DateFormat('yyyy/MM/dd', 'ar').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 2,
        automaticallyImplyLeading: false,
        title: Text(
          _companyName,
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'التاريخ: $formattedDate',
                style: GoogleFonts.tajawal(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, color: Colors.white, size: 18),
            label: Text(
              'تسجيل خروج 🚪',
              style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مرحباً بك ...',
              style: GoogleFonts.tajawal(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'اختر أحد الخدمات التالية للبدء بالعمل:',
              style: GoogleFonts.tajawal(fontSize: 14, color: const Color(0xFF7F8C8D)),
            ),
            const SizedBox(height: 16),

            // Sync Warning Banner (Matches index.html sync card)
            if (_pendingCount > 0)
              GestureDetector(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const SyncView()));
                  _loadData();
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFB74D)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text('🔄', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'لديك $_pendingCount سجلات تحتاج إلى مزامنة',
                          style: GoogleFonts.tajawal(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE67E22),
                          ),
                        ),
                      ),
                      const Text('⬅️', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              ),

            // Dashboard Grid (Matching Website)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.95,
              children: [
                // 1. Patient Follow-up Card (Special Gradient + Border + Badge)
                _buildWebCard(
                  title: 'متابعة مريض',
                  subtitle: 'البحث عن مريض ومتابعة حالته (علامات، سوائل، أوامر) في مكان واحد وبسهولة',
                  emojiIcon: '👤',
                  badge: 'جديد ✨',
                  border: Border.all(color: const Color(0xFF1565C0), width: 2),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE3F2FD), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientDashboardView())),
                ),

                // 2. Vitals Card
                _buildWebCard(
                  title: 'العلامات الحيوية',
                  subtitle: 'تسجيل علامات المريض الحيوية كل ساعة ومتابعة التطورات',
                  emojiIcon: '🩺',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VitalsView())),
                ),

                // 3. Intake & Output Card
                _buildWebCard(
                  title: 'السوائل (Intake & Output)',
                  subtitle: 'متابعة السوائل المغذية (داخل) والمفرزات (خارج) للمريض',
                  emojiIcon: '💧',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IntakeOutputView())),
                ),

                // 4. Doctor Orders Card (Special Green Styling)
                _buildWebCard(
                  title: 'أوامر الأطباء',
                  subtitle: 'إدارة وتسجيل الأدوية والفحوصات والأشعة الخاصة بالمريض',
                  emojiIcon: '📋',
                  border: Border.all(color: const Color(0xFF55EFC4), width: 2),
                  backgroundColor: const Color(0xFFE5FDF5),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorOrdersView())),
                ),

                // 5. Sync Center Card
                _buildWebCard(
                  title: 'مركز المزامنة أوفلاين',
                  subtitle: 'مزامنة السجلات المخزنة محلياً مع السيرفر الرئيسي',
                  emojiIcon: '🔄',
                  badge: _pendingCount > 0 ? '$_pendingCount' : null,
                  badgeColor: const Color(0xFFE67E22),
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SyncView()));
                    _loadData();
                  },
                ),

                // 6. Settings Card
                _buildWebCard(
                  title: 'الإعدادات والنسخ',
                  subtitle: 'إدارة البيانات المحلية والنسخ الاحتياطي',
                  emojiIcon: '⚙️',
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsView()));
                    _loadData();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebCard({
    required String title,
    required String subtitle,
    required String emojiIcon,
    String? badge,
    Color? badgeColor,
    Border? border,
    Gradient? gradient,
    Color backgroundColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        border: border ?? Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emojiIcon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        color: const Color(0xFF7F8C8D),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                if (badge != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor ?? const Color(0xFF1565C0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.tajawal(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
