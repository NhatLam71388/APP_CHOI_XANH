import 'package:flutter/material.dart';
import 'package:flutter_application_1/view/detail/detail_page.dart';
import 'package:flutter_application_1/view/until/technicalspec_item.dart';
import 'package:flutter_application_1/view/until/until.dart';

class NewsCard extends StatelessWidget {
  final dynamic product;
  final int categoryId;
  final VoidCallback? onTap;

  const NewsCard(
      {super.key, required this.product, required this.categoryId, this.onTap});

  @override
Widget build(BuildContext context) {
  final hinhDaiDienList = getDanhSachHinh(product);
  final hinhDaiDien = hinhDaiDienList.isNotEmpty ? hinhDaiDienList.first : '';

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
  };

  return InkWell(
    onTap: () => onTap?.call(),
    child: Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hình ảnh bên trái
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                hinhDaiDien,
                width: 120,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.broken_image, size: 60),
              ),
            ),
            const SizedBox(width: 12),

            // Thông tin bên phải
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product['kieuhienthi'] == 'sanpham')
                    Text('${formatCurrency(product['gia'])}₫',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.red)),

                  if (product['tieude']?.toString().trim().isNotEmpty ?? false)
                    Text(product['tieude'],
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                        ),

                  if (categoryId == 35004 &&
                      (product['diachiND']?.toString().trim().isNotEmpty ?? false))
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product['diachiND'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  if (product['emailND']?.toString().trim().isNotEmpty ?? false)
                    Row(
                      children: [
                        Icon(Icons.email, size: 16, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product['emailND'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 4),
                  TechnicalSpecsItem(specs: specs),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

}
