import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? trailingIcon;
  final VoidCallback onTap;

  const SettingsTile({
    required this.title,
    required this.subtitle,
    this.trailingIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final textColor = brightness == Brightness.dark
        ? const Color(0xFFB0C8AE)
        : const Color(0xFF586F51);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        title: Text(title, style: TextStyle(color: textColor)),
        subtitle: Text(subtitle, style: TextStyle(color: textColor)),
        trailing: trailingIcon != null ? Icon(trailingIcon) : null,
        onTap: onTap,
      ),
    );
  }
}
