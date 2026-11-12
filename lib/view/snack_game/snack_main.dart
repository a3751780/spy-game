import 'package:flutter/material.dart';
import 'package:flutter_for_test_new/view/snack_game/snack_play.dart';

void main() {
  runApp(const SnackPage());
}

class SnackPage extends StatelessWidget {
  const SnackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '絲滑貪吃蛇',
      theme: ThemeData.dark(),
      home: const SmoothSnakeGamePage(),
    );
  }
}