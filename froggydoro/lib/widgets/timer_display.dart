import 'package:flutter/material.dart';

class TimerDisplay extends StatelessWidget {
  final ValueNotifier<int> secondsNotifier;
  final double fontSize;
  final String Function(int) formatTime;
  final TextStyle? style;

  const TimerDisplay({
    Key? key,
    required this.secondsNotifier,
    required this.fontSize,
    required this.formatTime,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: secondsNotifier,
      builder: (context, seconds, _) {
        final String formattedTime = formatTime(seconds);
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
      },
    );
  }
}
