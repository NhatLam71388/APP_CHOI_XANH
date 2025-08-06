import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/view/allpage.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/view/auth/register.dart';
import 'package:flutter_application_1/widgets/button_widget.dart';
import 'package:flutter_application_1/widgets/input_widget.dart';
import 'package:flutter_application_1/widgets/label_widget.dart';
import 'package:flutter_application_1/widgets/widget_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController _username = TextEditingController();
  TextEditingController _password = TextEditingController();
  final _accFocus = FocusNode();
  final _passFocus = FocusNode();
  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: gradientBackground,
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Center(
            child: SingleChildScrollView(
                child: Container(
              padding: EdgeInsets.all(30),
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(16))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start, // label sát trái
                children: [
                  GestureDetector(
                    onTap: () {
                      // Thêm chức năng quay lại nếu cần
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(right: 30, left: 30),
                      decoration: BoxDecoration(
                        color: Color(0xff0066FF), // Nền đen trong suốt
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.keyboard_backspace_outlined,
                              size: 24, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'Quay lại trang trước',
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      height: 90, // giảm chiều cao tùy ý
                      child: appLogo,
                    ),
                  ),
                  FormLabel('Số điện thoại/Email'),
                  const SizedBox(height: 6),
                  CustomTextField(
                    focusNode: _accFocus,
                    nextFocusNode: _passFocus,
                    label: 'Nhập số điện thoại hoặc email',
                    icon: Icons.person,
                    controller: _username,
                    maxline: 1,
                  ),
                  const SizedBox(height: 10),
                  FormLabel('Mật khẩu'),
                  const SizedBox(height: 6),
                  CustomTextField(
                    focusNode: _passFocus,
                    maxline: 1,
                    label: 'Nhập mật khẩu',
                    icon: Icons.key,
                    isPassword: true,
                    controller: _password,
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Center(
                    child: CustomButton(
                      onPressed: () async {
                        final login = await AuthService.handleLogin(context,
                            _username.text.trim(), _password.text.trim());
                      },
                      text: 'Đăng nhập',
                      textColor: Colors.white,
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  textSwitchPage(
                      firstText: 'Bạn chưa có tài khoản',
                      actionText: 'Đăng ký',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Register()),
                        );
                      }),
                  SizedBox(
                    height: 10,
                  ),
                  Divider(
                    color: Colors.black12,
                  ),
                  Center(child: textLoginWith()),
                  buildSocialIconButton(
                    'asset/google.png',
                    'Đăng nhập với Google',
                    () => AuthService.handleGoogleLogin(context),
                  )
                ],
              ),
            )),
          ),
        ),
      ),
    );
  }
}
