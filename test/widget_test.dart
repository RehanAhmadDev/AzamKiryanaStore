// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:azam_kiryana_store/main.dart';

void main() {
  testWidgets('App basic load test', (WidgetTester tester) async {
    // 🚀 FIXED: isLoggedIn parameter bhej diya taake laal line khatam ho jaye.
    // Hum false bhej rahe hain taake test login screen se shuru ho.
    await tester.pumpWidget(const AzamKiryanaApp(isLoggedIn: false));

    // Counter wala purana code delete kar diya kyunke hamari app mein counter nahi hai.
    // Aap yahan login screen ka koi text check kar sakte hain agar chahein.
  });
}