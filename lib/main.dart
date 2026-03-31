import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CornDiseaseApp());
}

class CornDiseaseApp extends StatelessWidget {
  const CornDiseaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Corn Disease Detector',
      theme: ThemeData(
        primaryColor: Colors.green[800],
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}