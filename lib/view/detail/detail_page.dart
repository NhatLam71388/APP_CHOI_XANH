import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter_application_1/models/category_model.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/services/favourite_service.dart';
import 'package:flutter_application_1/view/auth/register.dart';
import 'package:flutter_application_1/view/cart/cart_page.dart';
import 'package:flutter_application_1/view/components/bottom_appbar.dart';
import 'package:flutter_application_1/view/detail/comment_card.dart';
import 'package:flutter_application_1/view/detail/bottom_bar.dart';
import 'package:flutter_application_1/view/detail/detail_description.dart';
import 'package:flutter_application_1/view/detail/detail_imggallery.dart';
import 'package:flutter_application_1/view/detail/detail_pricetitle.dart';
import 'package:flutter_application_1/view/detail/relatednews_card.dart';
import 'package:flutter_application_1/view/detail/relatedproduct_card.dart';
import 'package:flutter_application_1/view/detail/specs_data.dart';
import 'package:flutter_application_1/view/home/homepage.dart' show Global;
import 'package:flutter_application_1/view/profile/profile.dart';
import 'package:flutter_application_1/view/until/technicalspec_detail.dart';
import 'package:flutter_application_1/view/until/until.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart';
import 'package:share_plus/share_plus.dart';

class DetailPage extends StatefulWidget {
  final String productId;
  final ValueNotifier<int> categoryNotifier;
  final ValueNotifier<int> cartitemCount;
  final ValueNotifier<int> wishlistItemCountNotifier; // Thêm notifier
  final VoidCallback? onBack;
  final void Function(dynamic product)? onProductTap;
  final String? modelType;
  final void Function(int?) gotoCart;

  const DetailPage({
    super.key,
    required this.productId,
    required this.categoryNotifier,
    required this.cartitemCount,
    required this.wishlistItemCountNotifier, // Thêm vào constructor
    this.onBack,
    this.onProductTap,
    this.modelType,
    required this.gotoCart,
  });

  @override
  State<DetailPage> createState() => DetailPageState();
}

class DetailPageState extends State<DetailPage> {
  String? selectedImageUrl;
  String? htmlContent;
  bool isLoadingHtml = true;
  bool isExpanded = false;
  Map<String, dynamic>? productDetail;
  bool isLoading = true;
  bool isBackVisible = true;
  bool isFavourite = false; // Thêm biến trạng thái yêu thích
  final ScrollController _scrollController = ScrollController();
  List<dynamic> comments = [];
  bool isLoadingComments = true;
  int currentPage = 1;
  int totalPages = 1;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  double _userRating = 5.0; // Mặc định 5 sao
  bool _isSubmittingComment = false;
  late String moduleType;
  List<dynamic> _productsRelated = [];

  static String getModuleNameFromCategoryId(int categoryId) {
    if (categoryModules.containsKey(categoryId)) {
      final moduleParts = categoryModules[categoryId];
      if (moduleParts != null && moduleParts.length >= 3) {
        return moduleParts[1];
      } else {
        print('=> Không đủ phần tử hoặc null');
      }
    } else {
      print('=> Không tìm thấy categoryId trong map');
    }
    return '';
  }

  Future<void> loadProductDetail() async {
    final detail = await APIService.fetchProductDetail(
      APIService.baseUrl,
      moduleType,
      widget.productId,
          (_) => [],
    );
    if (detail != null) {
      setState(() {
        productDetail = detail;
        htmlContent = detail['noidungchitiet'];
        isLoading = false;
        isLoadingHtml = false;
      });
      if (detail['hienthibinhluan'] == 'True') {
        loadComments();
      }
      // Kiểm tra trạng thái yêu thích
      checkFavouriteStatus();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> checkFavouriteStatus() async {
    final wishlist = await APIFavouriteService.fetchWishlistItems(
      userId: Global.email,
      password: Global.pass,
    );
    setState(() {
      isFavourite = wishlist.any((item) => item['id'].toString() == widget.productId);
    });
  }

  Future<void> loadComments({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        isLoadingComments = true;
        comments.clear();
        currentPage = 1;
      });
    }

    final response = await APIService.fetchComments(
      productId: widget.productId,
      page: currentPage,
    );

    setState(() {
      if (response['data'] is List) {
        comments = loadMore ? [...comments, ...response['data']] : response['data'];
        totalPages = (response['recordsTotal'] / response['recordsFiltered']).ceil();
        isLoadingComments = false;
        if (loadMore) {
          currentPage++;
        }
      } else {
        comments = [];
        totalPages = 1;
        isLoadingComments = false;
      }
    });
  }



  @override
  void initState() {
    super.initState();

    final categoryModule = getModuleNameFromCategoryId(widget.categoryNotifier.value);

    if ((widget.modelType ?? '').isEmpty) {
      moduleType = categoryModule;
    } else {
      moduleType = widget.modelType!;
    }

    print('categoryWidget: ${widget.modelType} , categoryModule: $categoryModule ,moduleType: $moduleType');

    getProducts();

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (isBackVisible) setState(() => isBackVisible = false);
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!isBackVisible) setState(() => isBackVisible = true);
      }
    });

    loadProductDetail();
  }

  void getProducts() async {
    List<dynamic> products = await APIService.getProductRelated(
      id: widget.productId,
      modelType: moduleType,
    );

    final enhancedProducts = products.map((item) {
      return {
        ...item as Map<String, dynamic>,
        'moduleType': moduleType,
      };
    }).toList();

    setState(() {
      _productsRelated = enhancedProducts;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF81C784).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF81C784).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: const TextStyle(color: Color(0xFF4CAF50)),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
      ),
    );
  }

  Future<void> _handleSubmitComment() async {
    if (_commentController.text.trim().isEmpty) {
      showToast('Vui lòng nhập nội dung bình luận', backgroundColor: Colors.red);
      return;
    }

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      // Tạo form data theo yêu cầu
      final formData = {
        'tenkh': _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : '',
        'txtemail': _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : '',
        'txtdienthoai': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : '',
        'noidungtxt': _commentController.text.trim(),
        'id2': '5', // Luôn bằng 5
        'id3': '/dist/images/user.jpg', // Luôn có giá trị này
        'l': '', // Để trống như yêu cầu
        'id': widget.productId
      };

      final response = await http.post(
        Uri.parse('https://demochung.125.atoz.vn/ww1/save.binhluan.asp'),
        body: formData,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse.isNotEmpty && jsonResponse[0] is Map) {
          final result = jsonResponse[0] as Map<String, dynamic>;
          
          if (result['maloi'] == '1') {
            // Thành công
            showToast('Gửi bình luận thành công!', backgroundColor: Colors.green);
            
            // Reset form
            setState(() {
              _nameController.clear();
              _emailController.clear();
              _phoneController.clear();
              _commentController.clear();
            });
            
            // Làm mới danh sách bình luận
            await loadComments();
          } else {
            // Thất bại
            showToast('Gửi bình luận thất bại: ${result['ThongBao']}', backgroundColor: Colors.red);
          }
        }
      } else {
        showToast('Lỗi kết nối, vui lòng thử lại', backgroundColor: Colors.red);
      }
    } catch (e) {
      print('❌ Lỗi khi gửi bình luận: $e');
      showToast('Lỗi kết nối, vui lòng thử lại', backgroundColor: Colors.red);
    } finally {
      setState(() {
        _isSubmittingComment = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white, title: const Text("Đang tải...")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    var model = moduleType;
    final product = productDetail ?? {};
    final String title = product['tieude'] ?? 'Sản phẩm chưa có tên';
    final String price = product['gia'] ?? 'Chưa có giá';
    final String description = (product['noidungchitiet'] ?? 'Không có mô tả').replaceAll("''", '"');
    final bool showComments = product['hienthibinhluan'] == 'True';
    final bool allowComments = product['chophepbinhluan'] == 'True';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: model == 'sanpham' ? 55 : 0, top: 0),
            child: NotificationListener<ScrollNotification>(
              onNotification: (_) => true,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    DetailImageGallery(
                      productId: widget.productId,
                      onImageSelected: (url) {
                        setState(() => selectedImageUrl = url);
                      },
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 8, right: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (model == 'sanpham')
                            Text(
                              'Giá: ${formatCurrency(price)}đ',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            '$title',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    DetailHtmlContent(
                      htmlContent: description,
                      isLoading: isLoadingHtml,
                      isExpanded: isExpanded,
                      onToggle: () => setState(() => isExpanded = !isExpanded),
                    ),
                    const SizedBox(height: 8),
                    TechnicalSpecs(
                      specs: {
                        for (var entry in productSpecsMapping)
                          entry.key: getNestedTengoi(product, entry.value)
                      },
                    ),
                    if (showComments) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                'Bình luận',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (isLoadingComments)
                              const Center(child: CircularProgressIndicator())
                            else if (comments.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Chưa có bình luận nào',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: comments.length,
                                itemBuilder: (context, index) {
                                  final comment = comments[index];
                                  return CommentCard(
                                    nguoidang: comment['nguoidang'] ?? 'Khách',
                                    ngaydang: comment['ngaydang'] ?? '',
                                    rating: comment['rating'] ?? '0',
                                    soluongthich: comment['soluongthich'] ?? '0',
                                    noidung: comment['noidungbinhluan'] ?? '',
                                    hinhdaidien: comment['hinhdaidien'] ?? '',
                                    replies: comment['replies'] ?? [], // Thêm trường replies
                                    productId: widget.productId, // Thêm productId
                                    commentId: comment['id'] ?? '', // Thêm commentId
                                    onLikeUpdated: (String newLikeCount) {
                                      // Cập nhật số lượng thích trong danh sách comments
                                      setState(() {
                                        comment['soluongthich'] = newLikeCount;
                                      });
                                    },
                                    onReplySubmitted: () {
                                      // Làm mới danh sách bình luận sau khi gửi reply thành công
                                      loadComments();
                                    },
                                  );
                                },
                              ),
                            if (currentPage < totalPages && !isLoadingComments)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: ElevatedButton(
                                    onPressed: () => loadComments(loadMore: true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('Xem thêm bình luận'),
                                  ),
                                ),
                              ),
                            if (allowComments) ...[
                              const SizedBox(height: 16),
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFFE8F5E8), Color(0xFFF1F8E9)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Color(0xFF81C784).withOpacity(0.3)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF4CAF50).withOpacity(0.1),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4CAF50),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.comment,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Bình luận của bạn',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    // Form fields với thiết kế đẹp
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildFormField(
                                            controller: _nameController,
                                            label: 'Tên',
                                            hint: 'Nhập tên của bạn',
                                            icon: Icons.person,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildFormField(
                                            controller: _emailController,
                                            label: 'Email',
                                            hint: 'Nhập email của bạn',
                                            icon: Icons.email,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _buildFormField(
                                      controller: _phoneController,
                                      label: 'Số điện thoại',
                                      hint: 'Nhập số điện thoại của bạn',
                                      icon: Icons.phone,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildFormField(
                                      controller: _commentController,
                                      label: 'Nội dung bình luận',
                                      hint: 'Viết bình luận của bạn...',
                                      icon: Icons.comment,
                                      maxLines: 3,
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Color(0xFF4CAF50).withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton.icon(
                                            onPressed: _isSubmittingComment ? null : _handleSubmitComment,
                                            icon: _isSubmittingComment
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                    ),
                                                  )
                                                : const Icon(Icons.send, size: 18),
                                            label: Text(
                                              _isSubmittingComment ? 'Đang gửi...' : 'Gửi bình luận',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (_productsRelated.isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              child: Text(
                                model == 'tintuc' ? 'Tin tức liên quan' : 'Sản phẩm liên quan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            model == 'tintuc'
                                ? ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              scrollDirection: Axis.vertical,
                              itemCount: _productsRelated.length,
                              itemBuilder: (context, index) {
                                final item = _productsRelated[index];
                                return RelatedNewsCard(
                                  model: model,
                                  product: item,
                                  onTap: () {
                                    if (widget.onProductTap != null) {
                                      widget.onProductTap!(item);
                                    }
                                  },
                                );
                              },
                            )
                                : SizedBox(
                              height: 220,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _productsRelated.length,
                                itemBuilder: (context, index) {
                                  final item = _productsRelated[index];
                                  return RelatedProductCard(
                                    model: model,
                                    product: item,
                                    onTap: () {
                                      if (widget.onProductTap != null) {
                                        widget.onProductTap!(item);
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isBackVisible ? 1.0 : 0.0,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          if (widget.onBack != null) {
                            widget.onBack!();
                          }
                        },
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: IconButton(
                        icon: Icon(
                          isFavourite ? Icons.favorite : Icons.favorite_border,
                          color: isFavourite ? Colors.red : Colors.white,
                        ),
                        onPressed: () async {
                          final result = await APIFavouriteService.toggleFavourite(
                            moduleType: moduleType,
                            context: context,
                            userId: Global.email,
                            tieude: product['tieude'],
                            gia: product['gia'] ?? '',
                            hinhdaidien: '${product['hinhdaidien']}',
                            password: Global.pass,
                            id: int.tryParse(widget.productId) ?? 0,
                            idbg: '',
                            wishlistItemCountNotifier: widget.wishlistItemCountNotifier, // Truyền notifier
                          );
                          if (result is bool) {
                            setState(() {
                              isFavourite = result; // Cập nhật trạng thái yêu thích
                            });
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 5),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: IconButton(
                        icon: Image.asset('asset/share.png', color: Colors.white),
                        onPressed: () async {
                          final productLink = '${APIService.baseUrl}/${product['url']}';
                          final message = 'Check out this awesome product: $productLink';
                          await Share.share(message);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (model == 'sanpham' &&
              (productDetail?['gia'] ?? '').toString().trim().isNotEmpty &&
              productDetail?['hinhdaidien'] != null)
            BottomActionBar(
              gotoCart: widget.gotoCart,
              moduleType: moduleType,
              tieude: product['tieude'],
              gia: product['gia'],
              hinhdaidien: product['hinhdaidien'],
              productId: int.tryParse(widget.productId) ?? 0,
              userId: Global.email,
              passwordHash: Global.pass,
              cartitemCount: widget.cartitemCount,
            ),
        ],
      ),
    );
  }
}