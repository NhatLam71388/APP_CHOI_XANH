import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/Controller/register_controller.dart';
import 'package:flutter_application_1/widgets/button_widget.dart';
import 'package:flutter_application_1/widgets/input_widget.dart';
import 'package:flutter_application_1/widgets/widget_auth.dart';

class Register extends StatelessWidget {
  const Register({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RegisterController(),
      child: const _RegisterViewContent(),
    );
  }
}

class _RegisterViewContent extends StatelessWidget {
  const _RegisterViewContent();

  @override
  Widget build(BuildContext context) {
    return Consumer<RegisterController>(
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
                        // Nút quay lại
                        _buildBackButton(context, controller),
                        
                        // Logo app
                        _buildAppLogo(),
                        
                        const SizedBox(height: 6),
                        
                        // Input họ và tên
                        CustomTextField(
                          focusNode: controller.fullnameFocus,
                          nextFocusNode: controller.emailFocus,
                          label: 'Nhập họ và tên',
                          icon: Icons.abc,
                          controller: controller.fullnameController,
                          maxline: 1,
                        ),
                        
                        const SizedBox(height: 10),
                        const SizedBox(height: 6),
                        
                        // Input email
                        CustomTextField(
                          focusNode: controller.emailFocus,
                          nextFocusNode: controller.passwordFocus,
                          label: 'Nhập email',
                          icon: Icons.email,
                          controller: controller.emailController,
                          maxline: 1,
                        ),
                        
                        const SizedBox(height: 10),
                        const SizedBox(height: 6),
                        
                        // Input mật khẩu
                        CustomTextField(
                          focusNode: controller.passwordFocus,
                          label: 'Nhập lại mật khẩu',
                          icon: Icons.key,
                          controller: controller.passwordController,
                          maxline: 1,
                          isPassword: true,
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Nút đăng ký
                        Center(
                          child: CustomButton(
                            onPressed: controller.isLoading
                                ? () {} // Hàm rỗng khi đang tải
                                : () => controller.handleRegister(context),
                            text: controller.isLoading ? 'Đang đăng ký...' : 'Đăng ký',
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
      },
    );
  }

  // Widget nút quay lại
  Widget _buildBackButton(BuildContext context, RegisterController controller) {
    return GestureDetector(
      onTap: () => controller.goBack(context),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(right: 30, left: 30),
        decoration: BoxDecoration(
          color: const Color(0xff0066FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.keyboard_backspace_outlined, size: 24, color: Colors.white),
            SizedBox(width: 5),
            Text(
              'Quay lại trang trước',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
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
