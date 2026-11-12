import 'package:flutter/material.dart';
import 'package:flutter_for_test_new/view/snack_game/snack_main.dart';
import 'package:flutter_for_test_new/view/spy_game/main.dart'; // 這裡引入你的 spy_game 下的 main.dart

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('遊戲大廳'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 150.0, left: 24.0, right: 24.0, top: 0.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '選擇你要玩的遊戲',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),

              // 貪吃蛇 按鈕
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SnackPage(),
                    ),
                  );
                },
                child: const Text(
                  '🐍 貪吃蛇遊戲',
                  style: TextStyle(fontSize: 20),
                ),
              ),

              const SizedBox(height: 24),

              // 誰是臥底 按鈕
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UndercoverApp(),
                    ),
                  );
                },
                child: const Text(
                  '🕵️ 誰是臥底',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
