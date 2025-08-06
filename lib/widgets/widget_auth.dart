import 'package:flutter/material.dart';
import 'package:flutter_application_1/view/auth/register.dart';

Widget textLoginWith() {
  return Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 8),
    child: Text(
      'Hoặc đăng nhập với',
      style: TextStyle(color: Colors.black38, fontSize: 16),
    ),
  );
}

Widget textSwitchPage({
  required String firstText,
  required String actionText,
  required VoidCallback onTap,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Text(
        firstText,
        style: const TextStyle(color: Colors.blue, fontSize: 16),
      ),
      const SizedBox(width: 5),
      GestureDetector(
        onTap: onTap,
        child: Text(
          actionText,
          style: const TextStyle(
            color: Color(0xFF30C47D),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );
}

const BoxDecoration gradientBackground = BoxDecoration(
  gradient: LinearGradient(
    colors: [
      Color(0xFF0033FF),
      Colors.lightBlueAccent,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
);


final Widget appLogo = Image.asset(
  'asset/logoapp.png',
  width: 150,         // Giữ nguyên chiều rộng
  fit: BoxFit.contain, // Đảm bảo ảnh nằm gọn trong container
);
