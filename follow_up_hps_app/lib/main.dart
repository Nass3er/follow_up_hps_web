import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'views/login_view.dart';

const bool USE_WEBVIEW_MODE = true;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    WebView.platform = SurfaceAndroidWebView();
  }
  runApp(const HpsFollowUpApp());
}

class HpsFollowUpApp extends StatelessWidget {
  const HpsFollowUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'متابعة المرضى HPS',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        primaryColor: const Color(0xFF1565C0),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: USE_WEBVIEW_MODE ? const MainWebViewScreen() : const LoginView(),
    );
  }
}

class MainWebViewScreen extends StatefulWidget {
  const MainWebViewScreen({super.key});

  @override
  State<MainWebViewScreen> createState() => _MainWebViewScreenState();
}

class _MainWebViewScreenState extends State<MainWebViewScreen> {
  WebViewController? _webViewController;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_webViewController != null && await _webViewController!.canGoBack()) {
          _webViewController!.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: WebView(
            initialUrl: 'about:blank',
            javascriptMode: JavascriptMode.unrestricted,
            zoomEnabled: false,
            onWebViewCreated: (WebViewController controller) async {
              _webViewController = controller;
              await controller.loadFlutterAsset('assets/www/login.html');
            },
          ),
        ),
      ),
    );
  }
}
