import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/chat_screen.dart';
import 'screens/faq_screen.dart';
import 'screens/Opportunities.dart';  // add this if not already imported
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://eqtejejvrkjdqvdlptfx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVxdGVqZWp2cmtqZHF2ZGxwdGZ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ4NjM3NTAsImV4cCI6MjA2MDQzOTc1MH0.QzYwT0EIRnAt55Ju-UBuXOvmjboxBO3CJNfzFsa8740',
  );

  runApp(const AshaChatApp());
}

class AshaChatApp extends StatelessWidget {
  const AshaChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asha Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const ChatScreen(),
        '/faq': (context) => const FAQScreen(),
      },
    );
  }
}
