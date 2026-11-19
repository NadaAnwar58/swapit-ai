import 'package:flutter/material.dart';

/// شارة صغيرة مستديرة (نسبة التوافق، الحالة، ...).
class Pill extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const Pill({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
