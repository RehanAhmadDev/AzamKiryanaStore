// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Aapka current dashboard screen ka path
import 'features/khata/presentation/pages/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Supabase Initialization ---
  // URL ko Project ID ke mutabiq fix kar diya gaya hai (h add kiya gaya hai)
  await Supabase.initialize(
    url: 'https://yromirxnpjknpkohsnes.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlyb21pcnhucGprbnBrb2hzbmVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0NTE2ODQsImV4cCI6MjA5MzAyNzY4NH0.B06CD5Lj4FBeAm3ua5qXRvokYD5UKEDJd1Bw0ntIexA',
  );

  // --- Status Bar Design Setup ---
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF0F172A),
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFF8FAFC),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: AzamKiryanaApp(),
    ),
  );
}

class AzamKiryanaApp extends StatelessWidget {
  const AzamKiryanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Azam Kiryana Store POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          primary: const Color(0xFF0F172A),
          secondary: const Color(0xFF10B981),
          background: const Color(0xFFF8FAFC),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const DashboardScreen(),
    );
  }
}