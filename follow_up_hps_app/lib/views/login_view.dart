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
  int _activeTab = 0; // 0: Login Tab, 1: Settings Tab

  // Login Controllers
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _branchController = TextEditingController();
  final _yearController = TextEditingController();
  final _activityController = TextEditingController();

  // Settings Controllers
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _serviceController = TextEditingController();

  String _deviceSerial = 'جاري التحميل...';
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeDashboardView()),
      );
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
    final userId = _userIdController.text.trim();
    final password = _passwordController.text.trim();
    final branch = _branchController.text.trim();
    final year = _yearController.text.trim();
    final act = _activityController.text.trim();

    if (userId.isEmpty || password.isEmpty || branch.isEmpty || year.isEmpty || act.isEmpty) {
      setState(() => _loginError = 'يرجى تعبئة جميع الحقول (رقم المستخدم، الباسوورد، رقم الفرع، السنة، النشاط)');
      return;
    }

    setState(() {
      _isLoggingIn = true;
      _loginError = null;
    });

    final uIdInt = int.tryParse(userId) ?? 0;
    final brnInt = int.tryParse(branch) ?? 0;
    final yearInt = int.tryParse(year) ?? 0;
    final actInt = int.tryParse(act) ?? 0;

    final res = await ApiService.login(
      userId: uIdInt,
      password: password,
      branchNo: brnInt,
      financialYear: yearInt,
      activityNo: actInt,
      deviceId: _deviceSerial,
    );

    if (res['success'] == true) {
      await AuthService.saveLastCredentials(
        userId: userId,
        branchNo: branch,
        year: year,
        activityNo: act,
      );
      await ApiService.fetchCompanyName();

      if (mounted) {
        setState(() => _isLoggingIn = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeDashboardView()),
        );
      }
    } else {
      if (res['message'] == 'OFFLINE_ERROR') {
        // Check offline fallback
        final lastCreds = await AuthService.getLastCredentials();
        final offlineToken = await AuthService.getToken();

        if (lastCreds['userId'] == userId &&
            lastCreds['branchNo'] == branch &&
            lastCreds['year'] == year &&
            lastCreds['activityNo'] == act &&
            offlineToken != null &&
            offlineToken.isNotEmpty) {
          
          if (mounted) {
            setState(() => _isLoggingIn = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ السيرفر غير متصل، تم تسجيل الدخول في وضع (عدم الاتصال) باستخدام بياناتك المتوفرة في الجهاز.'),
                backgroundColor: Color(0xFFE67E22),
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeDashboardView()),
            );
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoggingIn = false;
              _loginError = 'تعذر الاتصال بالسيرفر للمصادقة. يجب أن تكون متصلاً بالسيرفر في أول مرة لتسجيل الدخول.';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoggingIn = false;
            _loginError = res['message'];
          });
        }
      }
    }
  }

  Future<void> _handleSaveAndTestSettings() async {
    final host = _hostController.text.trim();
    final port = _portController.text.trim();
    final service = _serviceController.text.trim();

    if (host.isEmpty || service.isEmpty) {
      setState(() {
        _settingsStatusMsg = 'الرجاء إدخال الهوست واسم الخدمة على الأقل';
        _settingsStatusSuccess = false;
      });
      return;
    }

    setState(() {
      _isTestingSettings = true;
      _settingsStatusMsg = 'جاري الحفظ والاختبار...';
      _settingsStatusSuccess = false;
    });

    final res = await ApiService.saveAndTestSettings(host, port, service);

    if (mounted) {
      setState(() {
        _isTestingSettings = false;
        _settingsStatusMsg = res['message'];
        _settingsStatusSuccess = res['success'] == true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 30,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Login Header
                  Text(
                    'نظام متابعة المرضى (HPS)',
                    style: GoogleFonts.tajawal(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1976D2),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'مرحباً بك، يرجى تسجيل الدخول للمتابعة',
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      color: const Color(0xFF666666),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Tabs Switcher
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE0E0E0), width: 2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _activeTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: _activeTab == 0 ? const Color(0xFF1976D2) : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                '🔑 بيانات الدخول',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.tajawal(
                                  fontSize: 15,
                                  fontWeight: _activeTab == 0 ? FontWeight.bold : FontWeight.normal,
                                  color: _activeTab == 0 ? const Color(0xFF1976D2) : const Color(0xFF777777),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _activeTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: _activeTab == 1 ? const Color(0xFF1976D2) : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                '⚙️ إعدادات السيرفر',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.tajawal(
                                  fontSize: 15,
                                  fontWeight: _activeTab == 1 ? FontWeight.bold : FontWeight.normal,
                                  color: _activeTab == 1 ? const Color(0xFF1976D2) : const Color(0xFF777777),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // TAB CONTENT
                  if (_activeTab == 0) _buildLoginTab() else _buildSettingsTab(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // TAB 1: LOGIN TAB
  Widget _buildLoginTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dashed Orange Device Serial Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF2E9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFE67E22),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Text(
                'رقم سيريال الجهاز',
                style: GoogleFonts.tajawal(fontSize: 13, color: const Color(0xFF7F8C8D)),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFBD2B3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        _deviceSerial,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tajawal(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD35400),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _copySerial,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _isCopied ? const Color(0xFF27AE60) : const Color(0xFFE67E22),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isCopied ? Icons.check : Icons.copy,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isCopied ? 'تم!' : 'نسخ',
                              style: GoogleFonts.tajawal(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // User ID
        _buildLabel('رقم المستخدم'),
        _buildTextField(_userIdController, 'أدخل رقم المستخدم', TextInputType.number),
        const SizedBox(height: 12),

        // Password
        _buildLabel('كلمة المرور'),
        _buildTextField(_passwordController, 'أدخل كلمة المرور', TextInputType.text, obscureText: true),
        const SizedBox(height: 12),

        // 3 Column Row (Branch, Year, Activity)
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('الفرع'),
                  _buildTextField(_branchController, 'الفرع', TextInputType.number),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('السنة'),
                  _buildTextField(_yearController, 'السنة', TextInputType.number),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('النشاط'),
                  _buildTextField(_activityController, 'النشاط', TextInputType.number),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Login Button
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _isLoggingIn ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              primary: const Color(0xFF1976D2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoggingIn
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    'تسجيل الدخول',
                    style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),

        if (_loginError != null) ...[
          const SizedBox(height: 12),
          Text(
            _loginError!,
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(color: const Color(0xFFC62828), fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }

  // TAB 2: SETTINGS TAB
  Widget _buildSettingsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('اسم أو أي بي الهوست'),
        _buildTextField(_hostController, 'مثال: localhost أو 192.168.1.10', TextInputType.text),
        const SizedBox(height: 12),

        _buildLabel('البورت الخاص بالسيرفر'),
        _buildTextField(_portController, 'مثال: 80', TextInputType.number),
        const SizedBox(height: 12),

        _buildLabel('اسم الخدمة (Web Service)'),
        _buildTextField(_serviceController, 'مثال: hps', TextInputType.text),
        const SizedBox(height: 18),

        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _isTestingSettings ? null : _handleSaveAndTestSettings,
            style: ElevatedButton.styleFrom(
              primary: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isTestingSettings
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    'حفظ واختبار الاتصال',
                    style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),

        if (_settingsStatusMsg != null) ...[
          const SizedBox(height: 12),
          Text(
            _settingsStatusMsg!,
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(
              color: _settingsStatusSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        text,
        style: GoogleFonts.tajawal(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, TextInputType inputType, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      obscureText: obscureText,
      style: GoogleFonts.tajawal(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey[400]),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5),
        ),
      ),
    );
  }
}
