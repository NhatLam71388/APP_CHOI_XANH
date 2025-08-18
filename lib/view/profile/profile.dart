import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/view/auth/login.dart';
import 'package:flutter_application_1/view/auth/register.dart';
import 'package:flutter_application_1/view/profile/profile_button.dart';
import 'package:flutter_application_1/widgets/card_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/api_service.dart';
import '../home/homepage.dart';
import '../until/until.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback onTapCartHistory;
  final VoidCallback? onLogout;
  final VoidCallback? onTapPersonalInfo;
  final VoidCallback? onTapNotification;
  final VoidCallback? onTapFavourite;
  final VoidCallback? onTapCart;

  const ProfilePage({
    super.key,
    required this.onTapCartHistory,
    this.onLogout,
    this.onTapPersonalInfo,
    this.onTapNotification,
    this.onTapFavourite,
    this.onTapCart,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isLogin = false;
  String userName = '';
  List<dynamic> settingsItems = [];

  @override
  void initState() {
    super.initState();
    loadLoginStatus();
  }

  Future<void> loadLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = await AuthService.isLoggedIn();
    final user = prefs.getString('customerName') ?? '';
    final email = prefs.getString('emailAddress') ?? '';
    final password = prefs.getString('passWord') ?? '';

    setState(() {
      isLogin = loggedIn;
      userName = user;
    });

    if (loggedIn) {
      await fetchSettingsItems(email, password);
    } else {
      setState(() {
        settingsItems = [];
      });
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
          setState(() {
            settingsItems = [];
          });
          showToast('Đăng nhập thất bại', backgroundColor: Colors.red);
        } else {
          setState(() {
            settingsItems = data;
          });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        color: const Color(0xff0066FF),
        onRefresh: loadLoginStatus,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Card(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.zero),
                ),
                elevation: 0,
                color: Colors.white,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Image.asset(
                        'asset/avatar.png',
                        width: 70,
                        height: 70,
                        color: Colors.black26,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: isLogin
                            ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào, ${Global.email}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Bạn đã đăng nhập',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        )
                            : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vui lòng đăng nhập để mua hàng',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                buttonProfile(
                                  title: 'Đăng nhập',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const Login(),
                                      ),
                                    ).then((_) {
                                      loadLoginStatus();
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                buttonProfile(
                                  backgroundColor: Colors.black12,
                                  title: 'Đăng ký',
                                  textColor: Colors.black,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const Register(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (isLogin)
                ...settingsItems.map((item) {
                  return SettingItemCard(
                    icon: getIconData(item['tieude'] ?? 'Unknown'),
                    title: item['tieude'] ?? 'Unknown',
                    iconRight: Icons.chevron_right,
                    onTap: item['tieude'] == 'Thông tin cá nhân'
                        ? widget.onTapPersonalInfo
                        : item['tieude'] == 'Thông báo'
                        ? widget.onTapNotification
                        : item['tieude'] == 'Danh mục quan tâm'
                        ? widget.onTapFavourite
                        : item['tieude'] == 'Giỏ hàng của bạn'
                        ? widget.onTapCart
                        : item['tieude'] == 'Lịch sử đặt hàng'
                        ? widget.onTapCartHistory
                        : item['tieude'] == 'Đăng thoát'
                        ? () async {
                      await AuthService.handleLogout(context);
                      await loadLoginStatus();
                      if (widget.onLogout != null) {
                        widget.onLogout!();
                      }
                      showToast('Đã đăng xuất', backgroundColor: Colors.green);
                    }
                        : null,
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}