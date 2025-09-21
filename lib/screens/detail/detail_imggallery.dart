import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/api_service.dart';

import 'img_expand.dart';

class DetailImageGallery extends StatefulWidget {
  final String itemId; // [THAY_DOI_1]: Nhận itemId thay vì productId
  final String moduleType; // [THAY_DOI_2]: Thêm moduleType để phân biệt sản phẩm/tin tức
  final String? newsImage; // [THAY_DOI_3]: Hình ảnh tin tức từ dữ liệu đã có
  final Function(String) onImageSelected;

  const DetailImageGallery({
    super.key,
    required this.itemId,
    required this.moduleType,
    this.newsImage, // [THAY_DOI_4]: Optional cho tin tức
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

  // [THAY_DOI_5]: Hàm lấy danh sách ảnh từ API hoặc dữ liệu có sẵn
  Future<void> _fetchImages() async {
    List<String> fetchedImages = [];
    
    print('🔍 DetailImageGallery - moduleType: ${widget.moduleType}');
    print('🔍 DetailImageGallery - newsImage: ${widget.newsImage}');
    
    // Phân biệt giữa sản phẩm và tin tức
    if (widget.moduleType.toLowerCase() == 'tintuc') {
      // Tin tức: sử dụng hình ảnh từ dữ liệu đã có
      if (widget.newsImage != null && widget.newsImage!.isNotEmpty) {
        fetchedImages = [widget.newsImage!];
        print('✅ Tin tức - sử dụng hình ảnh: ${widget.newsImage}');
      } else {
        print('❌ Tin tức - không có hình ảnh');
      }
    } else {
      // Sản phẩm: gọi API để lấy danh sách ảnh
      print('🛍️ Sản phẩm - gọi API lấy ảnh cho ID: ${widget.itemId}');
      fetchedImages = await APIService.fetchProductImages(widget.itemId);
    }
    
    setState(() {
      images = fetchedImages;
      isLoading = false;
      print('📸 Tổng số ảnh: ${images.length}');
    });
    
    // Gọi callback sau khi setState hoàn thành
    if (images.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onImageSelected(images[0]);
      });
    }
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
      return SizedBox(
        height: 300,
        child: Center(
          child: Text(
            widget.moduleType.toLowerCase() == 'tintuc' 
              ? 'Không có ảnh tin tức' 
              : 'Không có ảnh sản phẩm'
          ),
        ),
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
                            images: images,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    child: Image.network(
                      images[index],
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
              // Ẩn số thứ tự ảnh nếu là tintuc
              if (widget.moduleType.toLowerCase() != 'tintuc')
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        // Ẩn thanh ảnh nhỏ nếu là tintuc
        if (widget.moduleType.toLowerCase() != 'tintuc')
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
                        color: currentIndex == index ? Colors.blue : Colors.black12,
                      ),
                    ),
                    child: Image.network(
                      images[index],
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