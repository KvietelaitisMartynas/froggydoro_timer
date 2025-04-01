import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ButtonWidget extends StatelessWidget {
  final Color color;
  final String iconLocation;
  final String text;
  final VoidCallback onClicked;
  final double width;

  const ButtonWidget({
    Key? key,
    required this.color,
    required this.iconLocation,
    required this.text,
    required this.onClicked,
    required this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => ElevatedButton(


    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          iconLocation, // Path to your SVG file in the assets folder
          width: 20, // Icon size
          height: 20, // Icon size
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
        const SizedBox(width: 5), // Space between icon and text
        Text(
          text,
        ),
      ],
    ),
    style: ElevatedButton.styleFrom(
      minimumSize: Size(width, 50), // Button width and height
      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      elevation: 4, // Shadow effect
    ),
    onPressed: onClicked,
  );
}

