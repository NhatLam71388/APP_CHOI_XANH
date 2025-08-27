import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/widgets/custom_snackbar.dart';
import 'package:flutter_application_1/widgets/until.dart';
import 'package:http/http.dart' as http;
import '../screens/login/login_view.dart';

class RegisterController extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController fullnameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  final FocusNode emailFocus = FocusNode();
  final FocusNode fullnameFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode phoneFocus = FocusNode();
  final FocusNode usernameFocus = FocusNode();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Xử lý đăng ký
  Future<void> handleRegister(BuildContext context) async {
    String email = emailController.text.trim();
    String fullname = fullnameController.text.trim();
    String password = passwordController.text.trim();
    String phone = phoneController.text.trim();
    String username = usernameController.text.trim();

    if (fullname.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty || username.isEmpty) {
      CustomSnackBar.showError(context, message: 'Vui lòng nhập đầy đủ thông tin');
      return;
    }

    // Kiểm tra số điện thoại (phải có 10 chữ số)
    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      CustomSnackBar.showError(context, message: 'Số điện thoại phải có 10 chữ số');
      phoneFocus.requestFocus();
      return;
    }

    // Kiểm tra định dạng email
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      CustomSnackBar.showError(context, message: 'Email không hợp lệ');
      emailFocus.requestFocus();
      return;
    }

    // Kiểm tra độ dài mật khẩu (ít nhất 6 ký tự)
    if (password.length < 6) {
      CustomSnackBar.showError(context, message: 'Mật khẩu phải có ít nhất 6 ký tự');
      passwordFocus.requestFocus();
      return;
    }

    _setLoading(true);

    try {
      bool isSuccess = await _register(
        name: fullname,
        email: email,
        password: password,
        phone: phone,
        username: username,
      );

      if (isSuccess) {
        CustomSnackBar.showSuccess(context, message: 'Đăng ký thành công! Chuyển đến trang đăng nhập...');
        
        // Chuyển sang trang đăng nhập với email và mật khẩu đã điền sẵn
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginView(
              preFilledEmail: email,
              preFilledPassword: password,
            ),
          ),
        );
      } else {
        CustomSnackBar.showError(context, message: 'Đăng ký không thành công');
      }
    } catch (e) {
      CustomSnackBar.showError(context, message: 'Có lỗi xảy ra: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Gọi API đăng ký mới
  Future<bool> _register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String username,
  }) async {
    try {
      final Uri url = Uri.parse('https://demochung.125.atoz.vn/ww1/userlogin.asp');
      
      // Tạo payload theo yêu cầu
      final Map<String, String> body = {
        'id2': 'Chophepdangky',
        'loaithanhvien': '1',
        'tenkh': name,
        'email': email,
        'tel': phone,
        'userid': username,
        'pass': password,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        
        if (responseData.isNotEmpty) {
          final Map<String, dynamic> result = responseData[0];
          
          // Kiểm tra maloi để xác định thành công
          if (result['maloi'] == '0') {
            print('Đăng ký thành công: ${result['ThongBao']}');
            return true;
          } else {
            print('Đăng ký thất bại: ${result['ThongBao']}');
            return false;
          }
        } else {
          print('Response không hợp lệ');
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
    emailController.dispose();
    fullnameController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    usernameController.dispose();
    emailFocus.dispose();
    fullnameFocus.dispose();
    passwordFocus.dispose();
    phoneFocus.dispose();
    usernameFocus.dispose();
    super.dispose();
  }
}
