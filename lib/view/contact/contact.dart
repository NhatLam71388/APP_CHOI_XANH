import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/button_widget.dart';
import 'package:flutter_application_1/widgets/input_widget.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

import '../../services/api_service.dart';

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

  Map<String, String> contactInfo = {};
  bool isLoading = true;
  bool showForm = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchContactData();
  }

  Future<void> fetchContactData() async {
    try {
      final response = await http.get(
        Uri.parse('${APIService.baseUrl}/ww2/module.tintuc.asp?id=35028&sl=30&pageid=1'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json is List && json.isNotEmpty) {
          final data = json[0];
          final noidungchitiet = data['noidungchitiet'] ?? '';
          final showFormFlag = noidungchitiet.contains('noidungformlienhe');

          // Parse HTML để trích xuất thông tin
          final document = parse(noidungchitiet);
          final companyName = document.querySelector('span[itemprop="name"]')?.text ?? 'Công ty TNHH Chồi Xanh Media';
          final streetAddress = document.querySelector('span[itemprop="streetAddress"]')?.text ?? '82A-82B Dân Tộc';
          final addressLocality = document.querySelector('span[itemprop="addressLocality"]')?.text ?? 'Quận Tân Phú';
          final addressRegion = document.querySelector('span[itemprop="addressRegion"]')?.text ?? 'TP. Hồ Chí Minh';
          final phone = document.querySelector('a[itemprop="telephone"]')?.text ?? '028 3974 3179';
          final email = document.querySelector('a[itemprop="email"]')?.text ?? 'info@TuyenNhanSu.com';
          final website = document.querySelector('a[itemprop="url"]')?.text ?? 'TuyenNhanSu.com';

          if (mounted) {
            setState(() {
              contactInfo = {
                'companyName': companyName,
                'address': '$streetAddress, $addressLocality, $addressRegion',
                'phone': phone,
                'email': email,
                'website': website,
              };
              showForm = showFormFlag;
              isLoading = false;
            });
          }
        } else {
          throw Exception('Dữ liệu API không hợp lệ');
        }
      } else {
        throw Exception('Không thể tải dữ liệu: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Lỗi khi tải dữ liệu liên hệ: $e';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double fontSize = screenWidth * 0.037;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xff0066FF)));
    }

    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage, style: const TextStyle(fontSize: 18, color: Colors.red)));
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
                _buildInfoRow(Icons.apartment, contactInfo['companyName'] ?? '', '', fontSize),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on, contactInfo['address'] ?? '', '', fontSize),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone, 'Điện thoại:', contactInfo['phone'], fontSize),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.email, 'Email:', contactInfo['email'], fontSize),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.language, 'Website:', contactInfo['website'], fontSize),
                if (showForm) ...[
                  const SizedBox(height: 20),
                  CustomTextField(
                      focusNode: _fullNameFocus,
                      nextFocusNode: _emailFocus,
                      label: 'Họ tên'),
                  const SizedBox(height: 10),
                  CustomTextField(
                      focusNode: _emailFocus,
                      nextFocusNode: _addressFocus,
                      label: 'Địa chỉ email'),
                  const SizedBox(height: 10),
                  CustomTextField(
                      focusNode: _addressFocus,
                      nextFocusNode: _phoneFocus,
                      label: 'Địa chỉ'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: CustomTextField(
                            focusNode: _phoneFocus,
                            nextFocusNode: _codeFocus,
                            label: 'Điện thoại'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: CustomTextField(
                            focusNode: _codeFocus,
                            nextFocusNode: _textFocus,
                            label: 'Mã xác nhận'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                      focusNode: _textFocus, label: 'Nội dung', maxline: 3),
                  const SizedBox(height: 30),
                  CustomButton(
                    text: 'Gửi đi',
                    onPressed: () {
                      // Xử lý gửi thông tin ở đây
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
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