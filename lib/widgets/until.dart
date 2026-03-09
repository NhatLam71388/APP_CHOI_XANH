import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

String getNestedTengoi(Map<String, dynamic> product, String key) {
  final list = product[key];
  if (list is List && list.isNotEmpty) {
    return list[0]['tengoi'] ?? '';
  }
  return '';
}

String buildImageUrl(String url) {
  return url;
}

bool isImageUrl(String url) {
  return url.endsWith('.jpg') ||
      url.endsWith('.jpeg') ||
      url.endsWith('.png') ||
      url.endsWith('.gif') ||
      url.endsWith('.webp');
}

void showToast(String message, {Color backgroundColor = Colors.green}) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: backgroundColor,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

List<String> getDanhSachHinh(dynamic product) {
  List<String> imageList = [];

  if (product == null) return [];

  // Hình đại diện
  final dynamic hinhDaiDien = product['hinhdaidien'];
  if (hinhDaiDien != null) {
    final String url = hinhDaiDien.toString().trim();
    if (url.isNotEmpty) {
      final fullUrl = buildImageUrl(url);
      if (isImageUrl(fullUrl)) {
        imageList.add(fullUrl);
      } else {
        imageList.add(fullUrl);
      }
    }
  }

  // Hình liên quan
  final dynamic rawHinhanh = product['hinhlienquan'];
  final daiDienUrl = imageList.isNotEmpty ? imageList[0] : null;

  if (rawHinhanh is List) {
    for (var item in rawHinhanh) {
      String? url;
      if (item is Map && item['hinhdaidien'] != null) {
        url = item['hinhdaidien'].toString().trim();
      }

      if (url != null && url.isNotEmpty) {
        final fullUrl = buildImageUrl(url);
        if (isImageUrl(fullUrl) && fullUrl != daiDienUrl) {
          imageList.add(fullUrl);
        }
      }
    }
  } else if (rawHinhanh is String) {
    final parts = rawHinhanh.split(RegExp(r'[;,]'));
    for (var part in parts) {
      final url = part.trim();
      if (url.isNotEmpty) {
        final fullUrl = buildImageUrl(url);
        if (isImageUrl(fullUrl) && fullUrl != daiDienUrl) {
          imageList.add(fullUrl);
        }
      }
    }
  }

  return imageList;
}

bool hasValidImage(dynamic product) {
  final hinh = product['hinhdaidien'];
  final hinhanh = product['hinhanh'];

  return !(hinh == null || hinh.toString().isEmpty) ||
      !(hinhanh == null || !(hinhanh is List) || hinhanh.isEmpty);
}

class FilterBottomSheet extends StatelessWidget {
  final void Function()? onApply;

  const FilterBottomSheet({super.key, this.onApply});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bộ lọc',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('Chọn mức giá:'),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('< 1 triệu'),
                selected: false,
                onSelected: (value) {
                  // xử lý lọc
                },
              ),
              FilterChip(
                label: const Text('1 - 5 triệu'),
                selected: false,
                onSelected: (value) {},
              ),
              FilterChip(
                label: const Text('> 5 triệu'),
                selected: false,
                onSelected: (value) {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // đóng popup
                if (onApply != null) onApply!(); // callback nếu cần
              },
              child: const Text('Áp dụng lọc'),
            ),
          ),
        ],
      ),
    );
  }
}


String formatCurrency(dynamic price) {
  try {
    final number = price is String ? double.tryParse(price) : price;
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(number).replaceAll(',', '.'); // hoặc giữ dấu phẩy nếu thích
  } catch (e) {
    return price.toString();
  }
}