import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/login/login_view.dart';
import 'package:flutter_application_1/widgets/card_widget.dart';
import 'package:flutter_application_1/widgets/button_widget.dart';

import '../../Constant/app_colors.dart';
import '../../Controller/profile.dart';
import '../register/register_view.dart';

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
  final ProfileLogic _logic = ProfileLogic();

  @override
  void initState() {
    super.initState();
    _logic.loadLoginStatus().then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: RefreshIndicator(
        color: const Color(0xff0066FF),
        onRefresh: () async {
          await _logic.loadLoginStatus();
          setState(() {});
        },
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF198754).withOpacity(0.05),
                      const Color(0xFF198754).withOpacity(0.02),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF198754).withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF198754).withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF198754).withOpacity(0.1),
                              const Color(0xFF198754).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF198754).withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'asset/avatar.png',
                          width: 60,
                          height: 60,
                          color: const Color(0xFF198754),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _logic.isLogin
                            ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào, ${_logic.userName}',
                              style: const TextStyle(
                                color: Color(0xff1a1a1a),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF198754).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF198754).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: const Color(0xFF198754),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Bạn đã đăng nhập',
                                    style: TextStyle(
                                      color: const Color(0xFF198754),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                            : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vui lòng đăng nhập để mua hàng',
                              style: TextStyle(
                                color: Color(0xff1a1a1a),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    text: 'Đăng nhập',
                                    height: 40,
                                    fontSize: 14,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const LoginView(),
                                        ),
                                      ).then((_) {
                                        _logic.loadLoginStatus().then((_) {
                                          setState(() {});
                                        });
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CustomButton.outlined(
                                    text: 'Đăng ký',
                                    height: 40,
                                    fontSize: 14,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const Register(),
                                        ),
                                      );
                                    },
                                  ),
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
              if (_logic.isLogin)
                ..._logic.settingsItems.map((item) {
                  return SettingItemCard(
                    icon: _logic.getIconData(item['module'] ?? 'Unknown'),
                    title: item['tieude'] ?? 'Unknown',
                    iconRight: Icons.chevron_right,
                    onTap: item['module'] == 'HosoUV'
                        ? widget.onTapPersonalInfo
                        : item['module'] == 'Thongbaocongviec'
                        ? widget.onTapNotification
                        : item['module'] == 'Quanlydanhmucquantam'
                        ? widget.onTapFavourite
                        : item['module'] == 'Quanlylichsudathang'
                        ? widget.onTapCartHistory
                        : item['module'] == 'Logout'
                        ? () async {
                      await _logic.handleLogout(context);
                      await _logic.loadLoginStatus();
                      if (widget.onLogout != null) {
                        widget.onLogout!();
                      }
                      setState(() {});
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