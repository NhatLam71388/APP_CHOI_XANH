import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/view/auth/login.dart';
import 'package:flutter_application_1/view/until/until.dart';
import 'package:flutter_application_1/widgets/button_widget.dart';
import 'package:flutter_application_1/widgets/input_widget.dart';
import 'package:flutter_application_1/widgets/widget_auth.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:http/http.dart' as http;

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _fullnameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _fullnameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  Future<bool> _register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final Uri url = Uri.parse('${APIService.baseUrl}/api/register.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'name': name,
          'email': email,
          'password': password,
        },
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body['success'] == true) {
          print('Đăng ký thành công: ${body['message']}');
          return true;
        } else {
          print('Đăng ký thất bại: ${body['message']}');
          return false;
        }
      } else {
        print('Lỗi kết nối server: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Lỗi: $e');
      return false;
    }
  }

  void handleRegister() async {
    String email = _emailController.text.trim();
    String fullname = _fullnameController.text.trim();
    String password = _passwordController.text.trim();

    if (fullname.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    bool isSuccess = await _register(
      name: fullname,
      email: email,
      password: password,
    );

    if (isSuccess) {
      showToast('Đăng ký thành công');
      // Tự động đăng nhập để lấy cookie
      await AuthService.handleLogin(context, email, password);
    } else {
      showToast('Đăng ký thất bại');
    }
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
                padding: const EdgeInsets.all(30),
                margin: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(right: 30, left: 30),
                        decoration: BoxDecoration(
                          color: Color(0xff0066FF),
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
                        height: 90,
                        child: appLogo,
                      ),
                    ),
                    const SizedBox(height: 6),
                    CustomTextField(
                      focusNode: _fullnameFocus,
                      nextFocusNode: _emailFocus,
                      label: 'Nhập họ và tên',
                      icon: Icons.abc,
                      controller: _fullnameController,
                      maxline: 1,
                    ),
                    const SizedBox(height: 10),
                    const SizedBox(height: 6),
                    CustomTextField(
                      focusNode: _emailFocus,
                      nextFocusNode: _passwordFocus,
                      label: 'Nhập email',
                      icon: Icons.email,
                      controller: _emailController,
                      maxline: 1,
                    ),
                    const SizedBox(height: 10),
                    const SizedBox(height: 6),
                    CustomTextField(
                      focusNode: _passwordFocus,
                      label: 'Nhập lại mật khẩu',
                      icon: Icons.key,
                      controller: _passwordController,
                      maxline: 1,
                      isPassword: true,
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: CustomButton(
                        onPressed: () {
                          handleRegister();
                        },
                        text: 'Đăng ký',
                        textColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}