import 'package:flutter/material.dart';

class TimerDisplay extends StatelessWidget {
  final int totalSeconds;
  final double fontSize;
  final String Function(int) formatTime;
  final TextStyle? style;

  const TimerDisplay({
    Key? key,
    required this.totalSeconds,
    required this.fontSize,
    required this.formatTime,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String formattedTime = formatTime(totalSeconds);
    return Text(
      formattedTime,
      style:
          style ??
          TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
    );
  }
}
