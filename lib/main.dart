// lib/main.dart (Updated & Fixed)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/theme_provider.dart';
import 'features/dashboard/presentation/pages/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://yromirxnpjknpkohsnes.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlyb21pcnhucGprbnBrb2hzbmVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0NTE2ODQsImV4cCI6MjA5MzAyNzY4NH0.B06CD5Lj4FBeAm3ua5qXRvokYD5UKEDJd1Bw0ntIexA',
  );

  runApp(const ProviderScope(child: AzamKiryanaApp()));
}

class AzamKiryanaApp extends ConsumerWidget {
  const AzamKiryanaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Azam Kiryana Store POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeState.primaryColor,
          primary: themeState.primaryColor,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: themeState.primaryColor,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: themeState.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      // 🚀 Builder hata diya taake back/edges na katain
      home: const DashboardScreen(),
    );
  }
}