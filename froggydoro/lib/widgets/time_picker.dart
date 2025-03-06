import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

class TimePickerWidget extends StatelessWidget {
  final String label;
  final int hours;
  final int minutes;
  final int seconds;
  final ValueChanged<int> onHoursChanged;
  final ValueChanged<int> onMinutesChanged;
  final ValueChanged<int> onSecondsChanged;

  const TimePickerWidget({
    required this.label,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.onHoursChanged,
    required this.onMinutesChanged,
    required this.onSecondsChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 18)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNumberPicker(hours, 23, onHoursChanged),
            const Text(" : "),
            _buildNumberPicker(minutes, 59, onMinutesChanged),
            const Text(" : "),
            _buildNumberPicker(seconds, 59, onSecondsChanged),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberPicker(int value, int max, ValueChanged<int> onChanged) {
    return SizedBox(
      width: 60,
      child: NumberPicker(
        value: value,
        minValue: 0,
        maxValue: max,
        onChanged: onChanged,
      ),
    );
  }
}
