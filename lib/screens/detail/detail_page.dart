import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_application_1/widgets/button_widget.dart';
import 'package:html/parser.dart' as html_parser;

import 'package:flutter_application_1/screens/detail/relatednews_card.dart';
import 'package:flutter_application_1/screens/detail/relatedproduct_card.dart';
import 'package:flutter_application_1/screens/detail/specs_data.dart';
import 'package:flutter_application_1/screens/detail/technicalspec_detail.dart';
import 'package:flutter_application_1/widgets/loading_widget.dart';
import 'package:provider/provider.dart';

import '../../Controller/home.dart';
import '../../Controller/detail_controller.dart';
import '../../widgets/until.dart';
import 'bottom_bar.dart';
import 'comment_card.dart';
import 'detail_description.dart';
import 'detail_imggallery.dart';

class DetailPage extends StatefulWidget {
  final String productId;
  final ValueNotifier<int> categoryNotifier;
  final ValueNotifier<int> cartitemCount;
  final ValueNotifier<int> wishlistItemCountNotifier; // Thêm notifier
  final VoidCallback? onBack;
  final void Function(dynamic product)? onProductTap;
  final String? modelType;
  final void Function(int?) gotoCart;
  final dynamic productData; // [THAY_DOI_1]: Thêm dữ liệu sản phẩm/tin tức

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
    this.productData, // [THAY_DOI_2]: Optional cho dữ liệu sản phẩm/tin tức
  });

  @override
  State<DetailPage> createState() => DetailPageState();
}

class DetailPageState extends State<DetailPage> {
  String _stripHtmlTags(String htmlString) {
    if (htmlString.isEmpty) return '';
    final document = html_parser.parse(htmlString);
    return document.body?.text ?? '';
  }

  @override
  void initState() {
    super.initState();
    // Không làm gì ở đây
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DetailController(),
      child: Builder(
        builder: (context) {
          // Sử dụng context mới này để khởi tạo controller
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final controller = context.read<DetailController>();
            controller.initializeModuleType(widget.categoryNotifier.value, widget.modelType);
            controller.setupScrollListener();
            controller.loadProductDetail(widget.productId);
            controller.getProducts(widget.productId);
          });
          
          return Consumer<DetailController>(
            builder: (context, controller, child) {
              return _buildDetailPage(context, controller);
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailPage(BuildContext context, DetailController controller) {
    if (controller.isLoading) {
      return LoadingWidget();
    }

    final product = controller.productDetail ?? {};
    final model = controller.moduleType;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: model == 'sanpham' ? 55 : 0, top: 0),
            child: NotificationListener<ScrollNotification>(
              onNotification: (_) => true,
              child: SingleChildScrollView(
                controller: controller.scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    DetailImageGallery(
                      itemId: widget.productId,
                      moduleType: controller.moduleType,
                      newsImage: controller.moduleType == 'tintuc'
                          ? (widget.productData != null && widget.productData is Map 
                              ? widget.productData['hinhdaidien'] 
                              : (controller.productDetail != null ? controller.productDetail!['hinhdaidien'] : null))
                          : null,
                      onImageSelected: (url) => controller.updateSelectedImage(url),
                    ),
                    const SizedBox(height: 16),
                    _buildProductHeader(context, controller),
                    DetailHtmlContent(
                      htmlContent: controller.description,
                      isLoading: controller.isLoadingHtml,
                      isExpanded: controller.isExpanded,
                      onToggle: () => controller.toggleExpanded(),
                    ),
                    const SizedBox(height: 8),
                    TechnicalSpecs(
                      specs: {
                        for (var entry in productSpecsMapping)
                          entry.key: getNestedTengoi(product, entry.value)
                      },
                    ),
                    if (controller.showComments) ...[
                      _buildCommentsSection(context, controller),
                    ],
                    if (controller.productsRelated.isNotEmpty) ...[
                      _buildRelatedProductsSection(context, controller),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _buildTopBar(context, controller),
          if (model == 'sanpham' &&
              (controller.productDetail?['gia'] ?? '').toString().trim().isNotEmpty &&
              controller.productDetail?['hinhdaidien'] != null)
            BottomActionBar(
              gotoCart: widget.gotoCart,
              moduleType: controller.moduleType,
              tieude: controller.title,
              gia: controller.price,
              hinhdaidien: controller.productDetail!['hinhdaidien'],
              productId: int.tryParse(widget.productId) ?? 0,
              userId: Global.email,
              passwordHash: Global.pass,
              cartitemCount: widget.cartitemCount,
            ),
        ],
      ),
    );
  }

  Widget _buildProductHeader(BuildContext context, DetailController controller) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.moduleType == 'sanpham')
            Text(
              'Giá: ${formatCurrency(controller.price)}đ',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (controller.moduleType == 'tintuc' && controller.productDetail?['ngaydang'] != null)
            Text(
              'Ngày đăng: ${controller.productDetail!['ngaydang']}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            controller.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (controller.moduleType == 'tintuc' && controller.productDetail?['noidungtomtat'] != null) ...[
            const SizedBox(height: 8),
            Text(
              _stripHtmlTags(controller.productDetail!['noidungtomtat']),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentsSection(BuildContext context, DetailController controller) {
    return Container(
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
          if (controller.isLoadingComments)
            const Center(child: CircularProgressIndicator())
          else if (controller.comments.isEmpty)
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
              itemCount: controller.comments.length,
              itemBuilder: (context, index) {
                final comment = controller.comments[index];
                return CommentCard(
                  nguoidang: comment['nguoidang'] ?? 'Khách',
                  ngaydang: comment['ngaydang'] ?? '',
                  rating: comment['rating'] ?? '0',
                  soluongthich: comment['soluongthich'] ?? '0',
                  noidung: comment['noidungbinhluan'] ?? '',
                  hinhdaidien: comment['hinhdaidien'] ?? '',
                  replies: comment['replies'] ?? [],
                  productId: widget.productId,
                  commentId: comment['id'] ?? '',
                  onLikeUpdated: (String newLikeCount) {
                    controller.updateCommentLike(comment['id'].toString(), newLikeCount);
                  },
                  onReplySubmitted: () {
                    controller.refreshComments(widget.productId);
                  },
                );
              },
            ),
          if (controller.currentPage < controller.totalPages && !controller.isLoadingComments)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: CustomButton(text: "Xem thêm bình luận", onPressed: () => controller.loadComments(widget.productId, loadMore: true)),
              ),
            ),
          if (controller.allowComments) ...[
            const SizedBox(height: 16),
            _buildCommentForm(context, controller),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentForm(BuildContext context, DetailController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F5E8), Color(0xFFF1F8E9)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF81C784).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
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
          _buildFormFields(context, controller),
          const SizedBox(height: 20),
          _buildSubmitButton(context, controller),
        ],
      ),
    );
  }

  Widget _buildFormFields(BuildContext context, DetailController controller) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                controller: controller.nameController,
                label: 'Tên',
                hint: 'Nhập tên của bạn',
                icon: Icons.person,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormField(
                controller: controller.emailController,
                label: 'Email',
                hint: 'Nhập email của bạn',
                icon: Icons.email,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: controller.phoneController,
          label: 'Số điện thoại',
          hint: 'Nhập số điện thoại của bạn',
          icon: Icons.phone,
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: controller.commentController,
          label: 'Nội dung bình luận',
          hint: 'Viết bình luận của bạn...',
          icon: Icons.comment,
          maxLines: 3,
        ),
      ],
    );
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

  Widget _buildSubmitButton(BuildContext context, DetailController controller) {
    return Row(
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
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: controller.isSubmittingComment 
                ? null 
                : () => controller.handleSubmitComment(widget.productId),
            icon: controller.isSubmittingComment
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
              controller.isSubmittingComment ? 'Đang gửi...' : 'Gửi bình luận',
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
    );
  }

  Widget _buildRelatedProductsSection(BuildContext context, DetailController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.moduleType == 'tintuc' ? 'Tin tức liên quan' : 'Sản phẩm liên quan',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          controller.moduleType == 'tintuc'
              ? ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  itemCount: controller.productsRelated.length,
                  itemBuilder: (context, index) {
                    final item = controller.productsRelated[index];
                    return RelatedNewsCard(
                      model: controller.moduleType,
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
                    itemCount: controller.productsRelated.length,
                    itemBuilder: (context, index) {
                      final item = controller.productsRelated[index];
                      return RelatedProductCard(
                        model: controller.moduleType,
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
    );
  }

  Widget _buildTopBar(BuildContext context, DetailController controller) {
    return SafeArea(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: controller.isBackVisible ? 1.0 : 0.0,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(
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
                    controller.isFavourite ? Icons.favorite : Icons.favorite_border,
                    color: controller.isFavourite ? Colors.red : Colors.white,
                  ),
                  onPressed: () => controller.toggleFavourite(
                    context: context,
                    tieude: controller.title,
                    gia: controller.price,
                    hinhdaidien: controller.productDetail?['hinhdaidien'] ?? '',
                    id: int.tryParse(widget.productId) ?? 0,
                    wishlistItemCountNotifier: widget.wishlistItemCountNotifier,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  color: Colors.black.withOpacity(0.5),
                ),
                child: IconButton(
                  icon: Image.asset('asset/share.png', color: Colors.white),
                  onPressed: () => controller.shareProduct(controller.productDetail?['url'] ?? ''),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}