import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 嘗試載入 .env
    await dotenv.load(fileName: ".env");
    print("✅ .env 載入成功！");

    // 初始化 Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    print("✅ Supabase 初始化成功！");

  } catch (e) {
    print("❌ 啟動發生錯誤: $e");
    // 如果出錯，至少在終端機印出來，讓你一眼看出問題
  }

  runApp(const UndercoverApp());
}

// ... 剩下的 MaterialApp 程式碼與之前相同

class UndercoverApp extends StatelessWidget {
  const UndercoverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '誰是臥底',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.deepPurpleAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          secondary: Colors.redAccent,
        ),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}