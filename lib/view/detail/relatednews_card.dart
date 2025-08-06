import 'package:flutter/material.dart';

class RelatedNewsCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final String model;

  const RelatedNewsCard({
    Key? key,
    required this.product,
    required this.onTap,
    required this.model,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = product['hinhdaidien'] ?? '';
    final hasImages = imageUrl.isNotEmpty ||
        (product['hinhanh'] != null && (product['hinhanh'] as List).isNotEmpty);

    if (!hasImages) return const SizedBox.shrink();

    final title = product['tieude'] ?? 'Không có tiêu đề';
    final price = product['gia'];
    final hasPrice = price != null && price.toString().trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric( vertical: 2),
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(8),
            height: 100,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 60),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (hasPrice)
                        Text(
                          price.toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
