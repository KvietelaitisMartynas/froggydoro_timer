/* import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ButtonWidget extends StatelessWidget {
  final Color
  color; // This color is used ONLY for the SVG icon filter as before
  final String iconLocation;
  final String text;
  final VoidCallback onClicked;
  final double width;

  const ButtonWidget({
    super.key,
    required this.color,
    required this.iconLocation,
    required this.text,
    required this.onClicked,
    required this.width,
  });

  @override
  Widget build(BuildContext context) => ElevatedButton(
    style: ElevatedButton.styleFrom(
      // Keep your original textStyle, elevation etc.
      // ONLY change minimumSize to fixedSize:
      fixedSize: Size(width + 10, 50), // <--- THE ONLY STYLE CHANGE
      textStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ), // Kept original
      elevation: 4, // Kept original
      // We are NOT setting backgroundColor or foregroundColor here,
      // so it will use the default ElevatedButton theme colors.
    ),
    onPressed: onClicked,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      // Add mainAxisSize: MainAxisSize.min to prevent Row stretching inside button
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          iconLocation, // Path to your SVG file in the assets folder
          width: 20, // Icon size
          height: 20, // Icon size
          // Using the passed 'color' for the SVG filter, as in your original code
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
        const SizedBox(width: 5), // Space between icon and text (kept original)
        Text(text), // Text color will be default from theme
      ],
    ),
  );
}
 */

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ButtonWidget extends StatelessWidget {
  final Color color; // For SVG filter
  final String iconLocation;
  final String text;
  final VoidCallback onClicked;
  final double width;

  const ButtonWidget({
    super.key,
    required this.color,
    required this.iconLocation,
    required this.text,
    required this.onClicked,
    required this.width,
  });

  @override
  Widget build(BuildContext context) => ElevatedButton(
    style: ElevatedButton.styleFrom(
      // Use the exact width passed, unless +10 was intentional for visuals
      fixedSize: Size(width, 50),
      // Optional: Reduce padding if space is tight
      // padding: EdgeInsets.symmetric(horizontal: 8.0),
      textStyle: const TextStyle(
        // Use const for static styles
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      elevation: 4,
      // Rely on theme for background/foreground colors
    ),
    onPressed: onClicked,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min, // Keep this
      children: [
        SvgPicture.asset(
          iconLocation,
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
        const SizedBox(width: 5), // Use const
        // --- Wrap Text with Flexible ---
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis, // Handle long text gracefully
          ),
        ),
        // --- End Flexible ---
      ],
    ),
  );
}
