import 'package:flutter/material.dart';

class GradientProgressBar extends StatelessWidget {
  final double value; // 0.0 ~ 1.0
  final double height;
  final BorderRadiusGeometry borderRadius;
  final List<Color> gradientColors;
  final Color backgroundColor;

  const GradientProgressBar({
    super.key,
    required this.value,
    this.height = 10.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.gradientColors = const [Colors.blue, Colors.green],
    this.backgroundColor = const Color(0xFFE0E0E0),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        children: [
          Container(
            height: height,
            decoration: BoxDecoration(
              color: backgroundColor,
            ),
          ),
          Text(value.toString()),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
              ),
            ),
          ),
        ],
      ),
    );
  }
}