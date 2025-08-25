import 'package:flutter/material.dart';
import 'package:flutter_application_1/view/auth/login.dart';
import 'package:flutter_application_1/view/auth/register.dart';
import 'package:flutter_application_1/widgets/card_widget.dart';

import '../../Controller/profile.dart';

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
      backgroundColor: Colors.grey[100],
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
                      const Color(0xff0066FF).withOpacity(0.05),
                      const Color(0xff0066FF).withOpacity(0.02),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xff0066FF).withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff0066FF).withOpacity(0.08),
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
                              const Color(0xff0066FF).withOpacity(0.1),
                              const Color(0xff0066FF).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xff0066FF).withOpacity(0.2),
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
                          color: const Color(0xff0066FF),
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
                                color: const Color(0xff0066FF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xff0066FF).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: const Color(0xff0066FF),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Bạn đã đăng nhập',
                                    style: TextStyle(
                                      color: const Color(0xff0066FF),
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
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xff0066FF),
                                          Color(0xff0052CC),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xff0066FF).withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const Login(),
                                          ),
                                        ).then((_) {
                                          _logic.loadLoginStatus().then((_) {
                                            setState(() {});
                                          });
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: const Text(
                                        'Đăng nhập',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xff0066FF).withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const Register(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: const Color(0xff0066FF),
                                        elevation: 0,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: const Text(
                                        'Đăng ký',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
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
                    icon: _logic.getIconData(item['tieude'] ?? 'Unknown'),
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