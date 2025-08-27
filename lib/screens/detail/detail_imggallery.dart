import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/api_service.dart';

import 'img_expand.dart';

class DetailImageGallery extends StatefulWidget {
  final String productId; // [THAY_DOI_1]: Nhận productId thay vì images
  final Function(String) onImageSelected;

  const DetailImageGallery({
    super.key,
    required this.productId,
    required this.onImageSelected,
  });

  @override
  State<DetailImageGallery> createState() => _DetailImageGalleryState();
}

class _DetailImageGalleryState extends State<DetailImageGallery> {
  int currentIndex = 0;
  late PageController _pageController;
  List<String> images = []; // [THAY_DOI_2]: Lưu danh sách ảnh từ API
  bool isLoading = true; // [THAY_DOI_3]: Trạng thái tải ảnh

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentIndex);
    _fetchImages(); // [THAY_DOI_4]: Gọi API để lấy ảnh
  }

  // [THAY_DOI_5]: Hàm lấy danh sách ảnh từ API
  Future<void> _fetchImages() async {
    final fetchedImages = await APIService.fetchProductImages(widget.productId);
    setState(() {
      images = fetchedImages;
      isLoading = false;
      if (images.isNotEmpty) {
        widget.onImageSelected(images[0]); // Gọi callback cho ảnh đầu tiên
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void onImageSelected(int index) {
    setState(() {
      currentIndex = index;
    });
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    widget.onImageSelected(images[index]); // [THAY_DOI_6]: Gọi callback với ảnh được chọn
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (images.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(child: Text('Không có ảnh sản phẩm')),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                onPageChanged: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                  widget.onImageSelected(images[index]);
                },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenGalleryViewer(
                            images: images, // [THAY_DOI_7]: Sử dụng images từ state
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    child: Image.network(
                      images[index], // [THAY_DOI_8]: Sử dụng images từ state
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${currentIndex + 1}/${images.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => onImageSelected(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 2,
                      color:
                      currentIndex == index ? Colors.blue : Colors.black12,
                    ),
                  ),
                  child: Image.network(
                    images[index], // [THAY_DOI_9]: Sử dụng images từ state
                    width: 80,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}