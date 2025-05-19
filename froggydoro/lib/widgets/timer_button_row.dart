import 'package:flutter/material.dart';
import 'build_button.dart';
import 'dialog_helper.dart';

class TimerButtonRow extends StatelessWidget {
  final bool isRunning;
  final bool hasStarted;
  final bool isBreakTime;
  final int workMinutes;
  final int workSeconds;
  final int breakMinutes;
  final int breakSeconds;
  final int totalSeconds;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;

  const TimerButtonRow({
    Key? key,
    required this.isRunning,
    required this.hasStarted,
    required this.isBreakTime,
    required this.workMinutes,
    required this.workSeconds,
    required this.breakMinutes,
    required this.breakSeconds,
    required this.totalSeconds,
    required this.onStart,
    required this.onStop,
    required this.onReset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final maxSeconds =
        isBreakTime
            ? (breakMinutes * 60 + breakSeconds)
            : (workMinutes * 60 + workSeconds);
    final isCompleted = totalSeconds == maxSeconds || totalSeconds == 0;
    final theme = Theme.of(context);
    final buttonColor =
        theme.brightness == Brightness.dark
            ? const Color(0xFFB0C8AE)
            : const Color(0xFF586F51);

    if (!hasStarted && !isRunning) {
      return ButtonWidget(
        color: buttonColor,
        text: 'Start',
        iconLocation: 'assets/Icons/Play.svg',
        width: 200,
        onClicked: onStart,
      );
    }

    return isRunning || !isCompleted
        ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ButtonWidget(
              color: buttonColor,
              text: isRunning ? 'Stop' : 'Start',
              iconLocation:
                  isRunning
                      ? 'assets/Icons/Pause.svg'
                      : 'assets/Icons/Play.svg',
              width: 120,
              onClicked: isRunning ? onStop : onStart,
            ),
            const SizedBox(width: 20),
            ButtonWidget(
              color: buttonColor,
              text: 'Reset',
              iconLocation: 'assets/Icons/Rewind.svg',
              width: 120,
              onClicked: () {
                TimerDialogsHelper.showResetConfirmationDialog(
                  context: context,
                  onConfirmed: onReset,
                );
              },
            ),
          ],
        )
        : ButtonWidget(
          color: buttonColor,
          text: 'Start',
          iconLocation: 'assets/Icons/Play.svg',
          width: 200,
          onClicked: onStart,
        );
  }
}
