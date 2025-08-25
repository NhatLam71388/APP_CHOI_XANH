import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import '../services/api_service.dart';

class ContactController extends ChangeNotifier {
  Map<String, String> contactInfo = {};
  bool isLoading = true;
  bool showForm = false;
  String errorMessage = '';

  Future<void> fetchContactData() async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

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

          contactInfo = {
            'companyName': companyName,
            'address': '$streetAddress, $addressLocality, $addressRegion',
            'phone': phone,
            'email': email,
            'website': website,
          };
          showForm = showFormFlag;
        } else {
          throw Exception('Dữ liệu API không hợp lệ');
        }
      } else {
        throw Exception('Không thể tải dữ liệu: ${response.statusCode}');
      }
    } catch (e) {
      errorMessage = 'Lỗi khi tải dữ liệu liên hệ: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitContactForm(Map<String, String> formData) async {
    try {
      // TODO: Implement form submission logic
      // Gửi dữ liệu form đến API
      print('Form data: $formData');
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Show success message or handle response
    } catch (e) {
      errorMessage = 'Lỗi khi gửi form: $e';
      notifyListeners();
    }
  }

  void resetError() {
    errorMessage = '';
    notifyListeners();
  }
}
