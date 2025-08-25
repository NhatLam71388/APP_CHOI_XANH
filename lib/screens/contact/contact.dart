import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/button_widget.dart';
import 'package:flutter_application_1/widgets/input_widget.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

import '../../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Controller/contact_controller.dart';
import '../../widgets/button_widget.dart';
import '../../widgets/input_widget.dart';

class ContactForm extends StatefulWidget {
  const ContactForm({super.key});

  @override
  _ContactFormState createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _fullNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _codeFocus = FocusNode();
  final _textFocus = FocusNode();

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Không gọi fetchContactData ở 
  }

  @override
  void dispose() {
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _addressFocus.dispose();
    _phoneFocus.dispose();
    _codeFocus.dispose();
    _textFocus.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ContactController(),
      child: Builder(
        builder: (context) {
          // Sử dụng context mới từ Builder
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<ContactController>().fetchContactData();
          });
          
          return Consumer<ContactController>(
            builder: (context, controller, child) {
              return _buildContactPage(context, controller);
            },
          );
        },
      ),
    );
  }

  Widget _buildContactPage(BuildContext context, ContactController controller) {
    final screenWidth = MediaQuery.of(context).size.width;
    double fontSize = screenWidth * 0.037;

    if (controller.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xff0066FF))),
      );
    }

    if (controller.errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                controller.errorMessage,
                style: const TextStyle(fontSize: 18, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  controller.resetError();
                  controller.fetchContactData();
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.apartment, controller.contactInfo['companyName'] ?? '', '', fontSize),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on, controller.contactInfo['address'] ?? '', '', fontSize),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone, 'Điện thoại:', controller.contactInfo['phone'], fontSize),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.email, 'Email:', controller.contactInfo['email'], fontSize),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.language, 'Website:', controller.contactInfo['website'], fontSize),
                if (controller.showForm) ...[
                  const SizedBox(height: 20),
                  _buildContactForm(context, controller),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactForm(BuildContext context, ContactController controller) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            controller: _fullNameController,
            focusNode: _fullNameFocus,
            nextFocusNode: _emailFocus,
            label: 'Họ tên',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập họ tên';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          CustomTextField(
            controller: _emailController,
            focusNode: _emailFocus,
            nextFocusNode: _addressFocus,
            label: 'Địa chỉ email',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Email không hợp lệ';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          CustomTextField(
            controller: _addressController,
            focusNode: _addressFocus,
            nextFocusNode: _phoneFocus,
            label: 'Địa chỉ',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập địa chỉ';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: CustomTextField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  nextFocusNode: _codeFocus,
                  label: 'Điện thoại',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _codeController,
                  focusNode: _codeFocus,
                  nextFocusNode: _textFocus,
                  label: 'Mã xác nhận',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mã xác nhận';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CustomTextField(
            controller: _contentController,
            focusNode: _textFocus,
            label: 'Nội dung',
            maxline: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập nội dung';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          CustomButton(
            text: 'Gửi đi',
            onPressed: () => _submitForm(context, controller),
          ),
        ],
      ),
    );
  }

  void _submitForm(BuildContext context, ContactController controller) {
    if (_formKey.currentState!.validate()) {
      final formData = {
        'fullName': _fullNameController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'code': _codeController.text,
        'content': _contentController.text,
      };
      
      controller.submitContactForm(formData);
    }
  }

  Widget _buildInfoRow(
      IconData icon, String textStart, String? textEnd, double fontSize) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: fontSize + 4),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: textStart,
              style: TextStyle(fontSize: fontSize, color: Colors.black),
              children: [
                if (textEnd != null && textEnd.isNotEmpty)
                  TextSpan(
                    text: " $textEnd",
                    style: TextStyle(fontSize: fontSize, color: Colors.blue),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}