import 'package:flutter/material.dart';

Widget buttonProfile({
  required String title,
  required VoidCallback onPressed,
  Color backgroundColor = const Color(0xff0066FF),
  Color textColor =  Colors.white,
}) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      minimumSize: const Size(0, 35),
      backgroundColor: backgroundColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
    ),
    child: Text(
      title,
      style: TextStyle(color: textColor),
    ),
  );
}