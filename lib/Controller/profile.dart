import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../view/until/until.dart';

class ProfileLogic {
  bool isLogin = false;
  String userName = '';
  List<dynamic> settingsItems = [];

  Future<void> loadLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = await AuthService.isLoggedIn();
    final user = prefs.getString('customerName') ?? '';
    final email = prefs.getString('emailAddress') ?? '';
    final password = prefs.getString('passWord') ?? '';

    isLogin = loggedIn;
    userName = user;

    if (loggedIn) {
      await fetchSettingsItems(email, password);
    } else {
      settingsItems = [];
    }
  }

  Future<void> fetchSettingsItems(String email, String password) async {
    try {
      final md5Password = AuthService.generateMd5(password);
      final uri = Uri.parse(
        '${APIService.baseUrl}/ww1/member.1.asp?userid=$email&pass=$md5Password&pageid=1',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty && data[0]['ThongBao'] == 'Login fail') {
          print('API returned login failure: ${data[0]}');
          settingsItems = [];
          showToast('Đăng nhập thất bại', backgroundColor: Colors.red);
        } else {
          settingsItems = data;
        }
      } else {
        print('API error: ${response.statusCode}');
        showToast('Lỗi khi lấy dữ liệu cài đặt', backgroundColor: Colors.red);
      }
    } catch (e) {
      print('Error fetching settings: $e');
      showToast('Lỗi khi lấy dữ liệu cài đặt', backgroundColor: Colors.red);
    }
  }

  IconData getIconData(String title) {
    switch (title) {
      case 'Thông tin cá nhân':
        return Icons.person;
      case 'Thông báo':
        return Icons.notifications;
      case 'Danh mục quan tâm':
        return Icons.favorite;
      case 'Giỏ hàng của bạn':
        return Icons.shopping_cart;
      case 'Lịch sử đặt hàng':
        return Icons.work_history_outlined;
      case 'Quản lý bình luận':
        return Icons.comment;
      case 'Mật khẩu':
        return Icons.lock;
      case 'Đăng thoát':
        return Icons.logout_rounded;
      default:
        return Icons.info;
    }
  }

  Future<void> handleLogout(BuildContext context) async {
    await AuthService.handleLogout(context);
    showToast('Đã đăng xuất', backgroundColor: Colors.green);
  }
}