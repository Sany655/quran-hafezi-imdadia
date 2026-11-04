import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/wudu_reminder_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QuranApp());
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'আল-কুরআন',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F5132), // Emerald Islamic Green
          primary: const Color(0xFF0F5132),
          secondary: const Color(0xFFD4AF37), // Islamic Gold
        ),
        textTheme: GoogleFonts.notoSansBengaliTextTheme(Theme.of(context).textTheme),
        scaffoldBackgroundColor: const Color(0xFFFBF8EE),
      ),
      home: const WuduReminderScreen(), // Starts at Purity & Adab Gateway
    );
  }
}
