import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/widgets/button_widget.dart';
import 'package:flutter_application_1/widgets/input_widget.dart';

class OrderConfirmationSheet extends StatefulWidget {
  final TextEditingController addressController;
  final TextEditingController fullnameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final double tongThanhToan;
  final VoidCallback onConfirm;
  final BuildContext parentContext;

  const OrderConfirmationSheet({
    super.key,
    required this.addressController,
    required this.fullnameController,
    required this.phoneController,
    required this.emailController,
    required this.tongThanhToan,
    required this.onConfirm,
    required this.parentContext,
  });

  @override
  State<OrderConfirmationSheet> createState() => _OrderConfirmationSheetState();
}

class _OrderConfirmationSheetState extends State<OrderConfirmationSheet> {
  final _fullNameFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    // Kiểm tra trạng thái đăng nhập khi khởi tạo
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await AuthService.isLoggedIn();
    setState(() {
      isLoggedIn = loggedIn;
    });
  }

  @override
  void dispose() {
    _fullNameFocus.dispose();
    _addressFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    if (widget.fullnameController.text.trim().isEmpty ||
        widget.phoneController.text.trim().isEmpty ||
        widget.emailController.text.trim().isEmpty ||
        widget.addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    widget.onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Xác nhận đặt hàng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                focusNode: _fullNameFocus,
                nextFocusNode: _addressFocus,
                label: 'Họ và tên',
                controller: widget.fullnameController,
                icon: Icons.person,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                focusNode: _addressFocus,
                nextFocusNode: _phoneFocus,
                label: 'Địa chỉ nhận hàng',
                controller: widget.addressController,
                icon: Icons.location_on,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                focusNode: _phoneFocus,
                nextFocusNode: _emailFocus,
                label: 'Số điện thoại',
                controller: widget.phoneController,
                icon: Icons.phone,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                focusNode: _emailFocus,
                label: 'Email',
                controller: widget.emailController,
                icon: Icons.email,
                readOnly: false,
                enable: !isLoggedIn, // Chỉ cho phép chỉnh sửa nếu chưa đăng nhập
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(width: 0.5, color: Colors.black38),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 30),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Color(0xff0066FF),
                      ),
                      child: const Text(
                        'Xác nhận',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}