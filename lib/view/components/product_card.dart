import 'package:flutter/material.dart';
import 'package:flutter_application_1/view/detail/detail_page.dart';
import 'package:flutter_application_1/view/until/technicalspec_item.dart';
import 'package:flutter_application_1/view/until/until.dart';

class ProductCard extends StatelessWidget {
  final dynamic product;
  final int categoryId;
  final VoidCallback? onTap;

  const ProductCard(
      {super.key, required this.product, required this.categoryId, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hinhDaiDienList = getDanhSachHinh(product);
    final hinhDaiDien = hinhDaiDienList.isNotEmpty
        ? hinhDaiDienList.first
        : '';

    final Map<String, String> specs = {
      'Thương hiệu': getNestedTengoi(product, 'thuonghieu'),
      'CPU': getNestedTengoi(product, 'cpu'),
      'RAM': getNestedTengoi(product, 'ram'),
      'Ổ cứng': getNestedTengoi(product, 'ocung'),
      'Kích cỡ màn hình': getNestedTengoi(product, 'kichcomanhinh'),
      'Hiệu năng và pin': getNestedTengoi(product, 'hieunangvapin'),
      'Bộ nhớ trong': getNestedTengoi(product, 'bonhotrong'),
      'Tần số quét': getNestedTengoi(product, 'tansoquet'),
      'Chip xử lý': getNestedTengoi(product, 'chipxuli'),
      'Hãng sản xuất': getNestedTengoi(product, 'hangsanxuat'),
      'Hệ điều hành tivi': getNestedTengoi(product, 'hedieuhanhtivi'),
      'Độ phân giải': getNestedTengoi(product, 'dophangiai'),
      'Kích cỡ màn hình tivi': getNestedTengoi(product, 'kichcomanhinhtivi'),
      'Kiểu dáng': getNestedTengoi(product, 'kieudang'),
      'Phân loại': getNestedTengoi(product, 'phanloai'),
      'Công nghệ': getNestedTengoi(product, 'congnghe'),
      'Công suất': getNestedTengoi(product, 'congsuat'),
      'Loại máy': getNestedTengoi(product, 'loaimay'),
      
    };

    return InkWell(
      onTap: () {
       onTap?.call();

      },
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  hinhDaiDien,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.broken_image, size: 60),
                ),
              ),
              const SizedBox(height: 8),
              if (categoryId != 35004 &&
                  (product['gia']?.toString().trim().isNotEmpty ?? false))
                Text('${formatCurrency(product['gia'])}₫',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red)),
              if (product['tieude']?.toString().trim().isNotEmpty ?? false)
                Text(product['tieude'],
                    style: TextStyle(fontWeight: FontWeight.w600,fontSize: 13)),
              if (categoryId == 35004 &&
                  (product['diachiND']?.toString().trim().isNotEmpty ?? false))
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 4),
                    Expanded(child: Text(product['diachiND'])),
                  ],
                ),
              if (product['emailND']?.toString().trim().isNotEmpty ?? false)
                Row(
                  children: [
                    Icon(Icons.email, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 4),
                    Expanded(child: Text(product['emailND'])),
                  ],
                ),
              const SizedBox(height: 4),
              TechnicalSpecsItem(specs: specs),
            ],
          ),
        ),
      ),
    );
  }
}
