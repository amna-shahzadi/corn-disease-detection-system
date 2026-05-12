import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CornDiseaseApp());
}

class CornDiseaseApp extends StatefulWidget {
  const CornDiseaseApp({super.key});

  // This allows any screen to call CornDiseaseApp.setLocale(context, locale)
  static void setLocale(BuildContext context, Locale newLocale) {
    _CornDiseaseAppState? state =
        context.findAncestorStateOfType<_CornDiseaseAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<CornDiseaseApp> createState() => _CornDiseaseAppState();
}

class _CornDiseaseAppState extends State<CornDiseaseApp> {
  Locale _locale = const Locale('en'); // Default English

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Corn Disease Detector', // This will be updated dynamically based on locale
      locale: _locale, // 👈 This controls the active language
      theme: ThemeData(
        primaryColor: Colors.green[800],
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ur'),
      ],
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}