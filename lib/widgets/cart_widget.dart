import 'package:flutter/material.dart';

Widget buildInfoRow(String title, String amount, {bool isTotal = false}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: isTotal ? 16 : 14,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      Text(
        amount,
        style: TextStyle(
          fontSize: isTotal ? 16 : 14,
          color: isTotal ? Colors.red : Colors.black,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ],
  );
}
