import 'package:flutter/material.dart';
import 'timer_display.dart';

class MainTimerSection extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  final int totalSeconds;
  final bool isBreakTime;
  final int currentRound;
  final int roundCountSetting;
  final String Function(int) formatTime;
  final Widget Function(BuildContext) buildButtons;
  final VoidCallback onTestDurations;

  const MainTimerSection({
    Key? key,
    required this.screenWidth,
    required this.screenHeight,
    required this.totalSeconds,
    required this.isBreakTime,
    required this.currentRound,
    required this.roundCountSetting,
    required this.formatTime,
    required this.buildButtons,
    required this.onTestDurations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String roundsText = "Round $currentRound of $roundCountSetting";
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: screenHeight * 0.02),
        Text(
          isBreakTime ? "Break Time" : "Work Time",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w300,
            fontStyle: FontStyle.italic,
            fontSize: screenWidth * 0.06,
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        Text(
          roundsText,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.045,
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        Image.asset(
          isBreakTime ? 'assets/rest_froggy.png' : 'assets/froggy.png',
          height: screenHeight * 0.3,
          color: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
        ),
        SizedBox(height: screenHeight * 0.02),
        TimerDisplay(
          totalSeconds: totalSeconds,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.15,
          ),
          fontSize: screenWidth * 0.15,
          formatTime: formatTime,
        ),
        SizedBox(height: screenHeight * 0.02),
        buildButtons(context),
        SizedBox(height: screenHeight * 0.02),
        ElevatedButton(
          onPressed: onTestDurations,
          child: const Text('Load Test Durations'),
        ),
      ],
    );
  }
}
