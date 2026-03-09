import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/widgets/until.dart';

import '../screens/register/register_view.dart';
import '../widgets/custom_snackbar.dart'; // Thêm import này

class LoginController extends ChangeNotifier {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode accountFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Constructor để nhận giá trị đã điền sẵn
  LoginController({
    String? preFilledEmail,
    String? preFilledPassword,
  }) {
    // Điền sẵn email và mật khẩu nếu có
    if (preFilledEmail != null) {
      usernameController.text = preFilledEmail;
    }
    if (preFilledPassword != null) {
      passwordController.text = preFilledPassword;
    }
  }

  // Xử lý đăng nhập
  Future<void> handleLogin(BuildContext context) async {
    if (usernameController.text.trim().isEmpty || 
        passwordController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, message: 'Vui lòng nhập đầy đủ thông tin');
      return;
    }

    _setLoading(true);
    
    try {
      await AuthService.handleLogin(
        context,
        usernameController.text.trim(), 
        passwordController.text.trim()
      );
    } catch (e) {
      showToast('Có lỗi xảy ra: $e', backgroundColor: Colors.red);
    } finally {
      _setLoading(false);
    }
  }

  // Xử lý đăng nhập Google
  Future<void> handleGoogleLogin(BuildContext context) async {
    _setLoading(true);
    
    try {
      await AuthService.handleGoogleLogin(context);
    } catch (e) {
      showToast('Đăng nhập Google thất bại: $e', backgroundColor: Colors.red);
    } finally {
      _setLoading(false);
    }
  }

  // Chuyển đến trang đăng ký
  void navigateToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Register()),
    );
  }

  // Quay lại trang trước
  void goBack(BuildContext context) {
    Navigator.pop(context);
  }

  // Cập nhật trạng thái loading
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Dispose resources
  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    accountFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }
}
