import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/Controller/login_controller.dart';
import 'package:flutter_application_1/widgets/button_widget.dart';
import 'package:flutter_application_1/widgets/input_widget.dart';
import 'package:flutter_application_1/widgets/widget_auth.dart';

class LoginView extends StatelessWidget {
  final String? preFilledEmail;
  final String? preFilledPassword;
  
  const LoginView({
    super.key,
    this.preFilledEmail,
    this.preFilledPassword,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LoginController(
        preFilledEmail: preFilledEmail,
        preFilledPassword: preFilledPassword,
      ),
      child: _LoginViewContent(
        preFilledEmail: preFilledEmail,
        preFilledPassword: preFilledPassword,
      ),
    );
  }
}

class _LoginViewContent extends StatelessWidget {
  final String? preFilledEmail;
  final String? preFilledPassword;
  
  const _LoginViewContent({
    this.preFilledEmail,
    this.preFilledPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginController>(
      builder: (context, controller, child) {
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
                        // Logo app
                        _buildAppLogo(),
                        
                        const SizedBox(height: 6),
                        
                        // Input tài khoản
                        CustomTextField(
                          focusNode: controller.accountFocus,
                          nextFocusNode: controller.passwordFocus,
                          label: 'Nhập số điện thoại hoặc email',
                          icon: Icons.person,
                          controller: controller.usernameController,
                          maxline: 1,
                        ),
                        
                        const SizedBox(height: 10),
                        const SizedBox(height: 6),
                        
                        // Input mật khẩu
                        CustomTextField(
                          focusNode: controller.passwordFocus,
                          maxline: 1,
                          label: 'Nhập mật khẩu',
                          icon: Icons.key,
                          isPassword: true,
                          controller: controller.passwordController,
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Nút đăng nhập
                        Center(
                          child: CustomButton(
                            onPressed: controller.isLoading
                                ? () {} // Hàm rỗng khi đang tải
                                : () => controller.handleLogin(context),
                            text: 'Đăng nhập',
                            textColor: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(height: 10),
                        
                        // Link đăng ký
                        textSwitchPage(
                          firstText: 'Bạn chưa có tài khoản',
                          actionText: 'Đăng ký',
                          onTap: () => controller.navigateToRegister(context),
                        ),
                        
                        const SizedBox(height: 10),
                        
                        const Divider(color: Colors.black12),
                        
                        // Đăng nhập bằng mạng xã hội
                        Center(child: textLoginWith()),
                        
                        buildSocialIconButton(
                          'asset/google.png',
                          'Đăng nhập với Google',
                          () => controller.handleGoogleLogin(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget logo app
  Widget _buildAppLogo() {
    return Center(
      child: Container(
        height: 90,
        child: appLogo,
      ),
    );
  }
}