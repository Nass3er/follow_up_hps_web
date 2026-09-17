import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'home_dashboard_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  int _activeTab = 0;
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _branchController = TextEditingController();
  final _yearController = TextEditingController();
  final _activityController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _serviceController = TextEditingController();

  String _deviceSerial = '';
  bool _isCopied = false;
  bool _isLoggingIn = false;
  String? _loginError;
  bool _isTestingSettings = false;
  String? _settingsStatusMsg;
  bool _settingsStatusSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _checkExistingToken();
  }

  Future<void> _loadInitialData() async {
    final serial = await AuthService.getDeviceSerial();
    final config = await AuthService.getApiConfig();
    final lastCreds = await AuthService.getLastCredentials();
    if (mounted) {
      setState(() {
        _deviceSerial = serial;
        _hostController.text = config['host'] ?? '';
        _portController.text = config['port'] ?? '';
        _serviceController.text = config['service'] ?? '';
        _userIdController.text = lastCreds['userId'] ?? '';
        _branchController.text = lastCreds['branchNo'] ?? '';
        _yearController.text = lastCreds['year'] ?? '';
        _activityController.text = lastCreds['activityNo'] ?? '';
      });
    }
  }

  Future<void> _checkExistingToken() async {
    final token = await AuthService.getToken();
    if (token != null && token.isNotEmpty && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeDashboardView()));
    }
  }

  void _copySerial() {
    Clipboard.setData(ClipboardData(text: _deviceSerial));
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  Future<void> _handleLogin() async {
    if (_userIdController.text.isEmpty || _passwordController.text.isEmpty ||
        _branchController.text.isEmpty || _yearController.text.isEmpty || _activityController.text.isEmpty) {
      setState(() => _loginError = 'يرجى تعبئة جميع الحقول');
      return;
    }
    setState(() { _isLoggingIn = true; _loginError = null; });

    final res = await ApiService.login(
      userId: int.tryParse(_userIdController.text.trim()) ?? 0,
      password: _passwordController.text.trim(),
      branchNo: int.tryParse(_branchController.text.trim()) ?? 0,
      financialYear: int.tryParse(_yearController.text.trim()) ?? 0,
      activityNo: int.tryParse(_activityController.text.trim()) ?? 0,
      deviceId: _deviceSerial,
    );

    if (res['success'] == true) {
      await AuthService.saveLastCredentials(
        userId: _userIdController.text.trim(),
        branchNo: _branchController.text.trim(),
        year: _yearController.text.trim(),
        activityNo: _activityController.text.trim(),
      );
      await ApiService.fetchCompanyName();
      if (mounted) {
        setState(() => _isLoggingIn = false);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeDashboardView()));
      }
    } else if (res['message'] == 'OFFLINE_ERROR') {
      final lastCreds = await AuthService.getLastCredentials();
      final offlineToken = await AuthService.getToken();
      if (lastCreds['userId'] == _userIdController.text.trim() &&
          lastCreds['branchNo'] == _branchController.text.trim() &&
          offlineToken != null && offlineToken.isNotEmpty) {
        if (mounted) {
          setState(() => _isLoggingIn = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('السيرفر غير متصل، تم تسجيل الدخول في وضع عدم الاتصال'), backgroundColor: Color(0xFFE67E22)),
          );
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeDashboardView()));
        }
      } else {
        if (mounted) setState(() { _isLoggingIn = false; _loginError = 'تعذر الاتصال بالسيرفر. يجب الاتصال في أول مرة.'; });
      }
    } else {
      if (mounted) setState(() { _isLoggingIn = false; _loginError = res['message']; });
    }
  }

  Future<void> _handleSaveAndTestSettings() async {
    if (_hostController.text.isEmpty || _serviceController.text.isEmpty) {
      setState(() { _settingsStatusMsg = 'أدخل الهوست واسم الخدمة على الأقل'; _settingsStatusSuccess = false; });
      return;
    }
    setState(() { _isTestingSettings = true; _settingsStatusMsg = 'جاري الحفظ والاختبار...'; _settingsStatusSuccess = false; });
    final res = await ApiService.saveAndTestSettings(_hostController.text.trim(), _portController.text.trim(), _serviceController.text.trim());
    if (mounted) setState(() { _isTestingSettings = false; _settingsStatusMsg = res['message']; _settingsStatusSuccess = res['success'] == true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)], begin: Alignment.topRight, end: Alignment.bottomLeft),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 30, offset: Offset(0, 10))],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('نظام متابعة المرضى (HPS)', style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1976D2)), textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('مرحباً بك، يرجى تسجيل الدخول للمتابعة', style: GoogleFonts.tajawal(fontSize: 14, color: const Color(0xFF666666)), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Container(
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 2))),
                    child: Row(
                      children: [
                        Expanded(child: _buildTab('بيانات الدخول', 0)),
                        Expanded(child: _buildTab('إعدادات السيرفر', 1)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_activeTab == 0) _buildLoginTab() else _buildSettingsTab(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _activeTab == index ? const Color(0xFF1976D2) : Colors.transparent, width: 2))),
        child: Text(title, textAlign: TextAlign.center, style: GoogleFonts.tajawal(fontSize: 15, fontWeight: _activeTab == index ? FontWeight.bold : FontWeight.normal, color: _activeTab == index ? const Color(0xFF1976D2) : const Color(0xFF777777))),
      ),
    );
  }

  Widget _buildLoginTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(color: const Color(0xFFFDF2E9), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE67E22))),
          child: Column(
            children: [
              Text('رقم سيريال الجهاز', style: GoogleFonts.tajawal(fontSize: 13, color: const Color(0xFF7F8C8D))),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFFBD2B3))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: Text(_deviceSerial, textAlign: TextAlign.center, style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFD35400)))),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _copySerial,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: _isCopied ? const Color(0xFF27AE60) : const Color(0xFFE67E22), borderRadius: BorderRadius.circular(5)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_isCopied ? Icons.check : Icons.copy, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(_isCopied ? 'تم!' : 'نسخ', style: GoogleFonts.tajawal(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildLabel('رقم المستخدم'), _buildTextField(_userIdController, 'أدخل رقم المستخدم', TextInputType.number), const SizedBox(height: 12),
        _buildLabel('كلمة المرور'), _buildTextField(_passwordController, 'أدخل كلمة المرور', TextInputType.text, obscureText: true), const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('الفرع'), _buildTextField(_branchController, 'الفرع', TextInputType.number)])),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('السنة'), _buildTextField(_yearController, 'السنة', TextInputType.number)])),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('النشاط'), _buildTextField(_activityController, 'النشاط', TextInputType.number)])),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 46,
          child: ElevatedButton(
            onPressed: _isLoggingIn ? null : _handleLogin,
            style: ElevatedButton.styleFrom(primary: const Color(0xFF1976D2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: _isLoggingIn
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('تسجيل الدخول', style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
        if (_loginError != null) ...[const SizedBox(height: 12), Text(_loginError!, textAlign: TextAlign.center, style: GoogleFonts.tajawal(color: const Color(0xFFC62828), fontSize: 13, fontWeight: FontWeight.bold))],
      ],
    );
  }

  Widget _buildSettingsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('اسم أو أي بي الهوست'), _buildTextField(_hostController, 'localhost أو 192.168.1.10', TextInputType.text), const SizedBox(height: 12),
        _buildLabel('البورت'), _buildTextField(_portController, '80', TextInputType.number), const SizedBox(height: 12),
        _buildLabel('اسم الخدمة'), _buildTextField(_serviceController, 'hps', TextInputType.text), const SizedBox(height: 18),
        SizedBox(
          width: double.infinity, height: 46,
          child: ElevatedButton(
            onPressed: _isTestingSettings ? null : _handleSaveAndTestSettings,
            style: ElevatedButton.styleFrom(primary: const Color(0xFF2E7D32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: _isTestingSettings
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('حفظ واختبار الاتصال', style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
        if (_settingsStatusMsg != null) ...[const SizedBox(height: 12), Text(_settingsStatusMsg!, textAlign: TextAlign.center, style: GoogleFonts.tajawal(color: _settingsStatusSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828), fontSize: 13, fontWeight: FontWeight.bold))],
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(text, style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF333333))));
  }

  Widget _buildTextField(TextEditingController controller, String hint, TextInputType inputType, {bool obscureText = false}) {
    return TextField(
      controller: controller, keyboardType: inputType, obscureText: obscureText, style: GoogleFonts.tajawal(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint, hintStyle: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey[400]),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5)),
      ),
    );
  }
}
