import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart';
import 'package:share_plus/share_plus.dart';

import '../models/category_model.dart';
import '../services/api_service.dart';
import '../services/favourite_service.dart';
import '../widgets/until.dart';
import 'home.dart';

class DetailController extends ChangeNotifier {
  String? selectedImageUrl;
  String? htmlContent;
  bool isLoadingHtml = true;
  bool isExpanded = false;
  Map<String, dynamic>? productDetail;
  bool isLoading = true;
  bool isBackVisible = true;
  bool isFavourite = false;
  List<dynamic> comments = [];
  bool isLoadingComments = true;
  int currentPage = 1;
  int totalPages = 1;
  final TextEditingController commentController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  double userRating = 5.0;
  bool isSubmittingComment = false;
  late String moduleType;
  List<dynamic> productsRelated = [];
  final ScrollController scrollController = ScrollController();

  // Getters
  String get title => productDetail?['tieude'] ?? 'Sản phẩm chưa có tên';
  String get price => productDetail?['gia'] ?? 'Chưa có giá';
  String get description => (productDetail?['noidungchitiet'] ?? 'Không có mô tả').replaceAll("''", '"');
  bool get showComments => productDetail?['hienthibinhluan'] == 'True';
  bool get allowComments => productDetail?['chophepbinhluan'] == 'True';

  static String getModuleNameFromCategoryId(int categoryId) {
    print('=> Tìm kiếm categoryId: $categoryId');
    print('=> Các categoryId có sẵn: ${categoryModules.keys.toList()}');
    
    if (categoryModules.containsKey(categoryId)) {
      final moduleParts = categoryModules[categoryId];
      if (moduleParts != null && moduleParts.length >= 3) {
        print('=> Tìm thấy module: ${moduleParts[1]}');
        return moduleParts[1];
      } else {
        print('=> Không đủ phần tử hoặc null');
      }
    } else {
      print('=> Không tìm thấy categoryId trong map');
    }
    return '';
  }

  void initializeModuleType(int categoryId, String? modelType) {
    final categoryModule = getModuleNameFromCategoryId(categoryId);
    
    // Nếu categoryModule không rỗng, sử dụng nó
    if (categoryModule.isNotEmpty) {
      moduleType = categoryModule.toLowerCase();
    } 
    // Nếu categoryModule rỗng nhưng modelType có chứa "tintuc", sử dụng "tintuc"
    else if ((modelType ?? '').toLowerCase().contains('tintuc')) {
      moduleType = 'tintuc';
    }
    // Nếu categoryModule rỗng nhưng modelType có chứa "sanpham", sử dụng "sanpham"
    else if ((modelType ?? '').toLowerCase().contains('sanpham')) {
      moduleType = 'sanpham';
    }
    // Mặc định sử dụng modelType
    else {
      moduleType = (modelType ?? '').toLowerCase();
    }
    
    print('categoryWidget: $modelType , categoryModule: $categoryModule ,moduleType: $moduleType');
  }

  void setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (isBackVisible) {
          isBackVisible = false;
          notifyListeners();
        }
      } else if (scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!isBackVisible) {
          isBackVisible = true;
          notifyListeners();
        }
      }
    });
  }

  Future<void> loadProductDetail(String productId) async {
    try {
      isLoading = true;
      notifyListeners();

      final detail = await APIService.fetchProductDetail(
        APIService.baseUrl,
        moduleType,
        productId,
        (_) => [],
      );

      if (detail != null) {
        productDetail = detail;
        htmlContent = detail['noidungchitiet'];
        isLoading = false;
        isLoadingHtml = false;
        notifyListeners();

        if (detail['hienthibinhluan'] == 'True') {
          loadComments(productId);
        }
        
        checkFavouriteStatus(productId);
      } else {
        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      print('❌ Lỗi khi tải chi tiết sản phẩm: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkFavouriteStatus(String productId) async {
    try {
      final wishlist = await APIFavouriteService.fetchWishlistItems(
        userId: Global.email,
        password: Global.pass,
      );
      
      isFavourite = wishlist.any((item) => item['id'].toString() == productId);
      notifyListeners();
    } catch (e) {
      print('❌ Lỗi khi kiểm tra trạng thái yêu thích: $e');
    }
  }

  Future<void> loadComments(String productId, {bool loadMore = false}) async {
    try {
      if (!loadMore) {
        isLoadingComments = true;
        comments.clear();
        currentPage = 1;
        notifyListeners();
      }

      final response = await APIService.fetchComments(
        productId: productId,
        page: currentPage,
      );

      if (response['data'] is List) {
        comments = loadMore ? [...comments, ...response['data']] : response['data'];
        totalPages = (response['recordsTotal'] / response['recordsFiltered']).ceil();
        isLoadingComments = false;
        
        if (loadMore) {
          currentPage++;
        }
        
        notifyListeners();
      } else {
        comments = [];
        totalPages = 1;
        isLoadingComments = false;
        notifyListeners();
      }
    } catch (e) {
      print('❌ Lỗi khi tải bình luận: $e');
      isLoadingComments = false;
      notifyListeners();
    }
  }

  Future<void> getProducts(String productId) async {
    try {
      print('🔍 Đang tải related products/news cho ID: $productId, moduleType: $moduleType');
      List<dynamic> products = await APIService.getProductRelated(
        id: productId,
        modelType: moduleType,
      );

      print('📦 Số lượng related items nhận được: ${products.length}');
      print('📦 Dữ liệu related items: $products');

      final enhancedProducts = products.map((item) {
        return {
          ...item as Map<String, dynamic>,
          'moduleType': moduleType,
        };
      }).toList();

      productsRelated = enhancedProducts;
      print('✅ Đã cập nhật productsRelated: ${productsRelated.length} items');
      notifyListeners();
    } catch (e) {
      print('❌ Lỗi khi tải sản phẩm liên quan: $e');
    }
  }

  Future<void> handleSubmitComment(String productId) async {
    if (commentController.text.trim().isEmpty) {
      showToast('Vui lòng nhập nội dung bình luận', backgroundColor: Colors.red);
      return;
    }

    isSubmittingComment = true;
    notifyListeners();

    try {
      final formData = {
        'tenkh': nameController.text.trim().isNotEmpty ? nameController.text.trim() : '',
        'txtemail': emailController.text.trim().isNotEmpty ? emailController.text.trim() : '',
        'txtdienthoai': phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : '',
        'noidungtxt': commentController.text.trim(),
        'id2': '5',
        'id3': '/dist/images/user.jpg',
        'l': '',
        'id': productId
      };

      final response = await http.post(
        Uri.parse('${APIService.baseUrl}/ww1/save.binhluan.asp'),
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
            showToast('Gửi bình luận thành công!', backgroundColor: Colors.green);
            
            // Reset form
            nameController.clear();
            emailController.clear();
            phoneController.clear();
            commentController.clear();
            
            // Làm mới danh sách bình luận
            await loadComments(productId);
          } else {
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
      isSubmittingComment = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavourite({
    required String tieude,
    required BuildContext context,
    required String gia,
    required String hinhdaidien,
    required int id,
    required ValueNotifier<int> wishlistItemCountNotifier,
  }) async {
    try {
      final result = await APIFavouriteService.toggleFavourite(
        moduleType: moduleType,
        context: context, // Sẽ được truyền từ view
        userId: Global.email,
        tieude: tieude,
        gia: gia,
        hinhdaidien: hinhdaidien,
        password: Global.pass,
        id: id,
        idbg: '',
        wishlistItemCountNotifier: wishlistItemCountNotifier,
      );

      if (result is bool) {
        isFavourite = result;
        notifyListeners();
      }
    } catch (e) {
      print('❌ Lỗi khi toggle favourite: $e');
    }
  }

  Future<void> shareProduct(String url) async {
    try {
      final productLink = '${APIService.baseUrl}/$url';
      final message = 'Check out this awesome product: $productLink';
      await Share.share(message);
    } catch (e) {
      print('❌ Lỗi khi chia sẻ sản phẩm: $e');
    }
  }

  void updateCommentLike(String commentId, String newLikeCount) {
    final commentIndex = comments.indexWhere((comment) => comment['id'].toString() == commentId);
    if (commentIndex != -1) {
      comments[commentIndex]['soluongthich'] = newLikeCount;
      notifyListeners();
    }
  }

  void refreshComments(String productId) {
    loadComments(productId);
  }

  void toggleExpanded() {
    isExpanded = !isExpanded;
    notifyListeners();
  }

  void updateSelectedImage(String? url) {
    selectedImageUrl = url;
    notifyListeners();
  }

  @override
  void dispose() {
    scrollController.dispose();
    commentController.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}




