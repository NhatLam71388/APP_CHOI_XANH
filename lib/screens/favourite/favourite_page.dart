import 'package:flutter/material.dart';
import 'package:flutter_application_1/Controller/favourite.dart';
import 'package:flutter_application_1/view/until/until.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';

class FavouritePage extends StatefulWidget {
  final Function(dynamic) onProductTap;
  final VoidCallback? onFavouriteToggle;
  final GlobalKey<favouritePageState> key;

  const FavouritePage({
    required this.onProductTap,
    this.onFavouriteToggle,
    required this.key,
  }) : super(key: key);

  @override
  favouritePageState createState() => favouritePageState();
}

class favouritePageState extends State<FavouritePage> {
  late FavouriteController favouriteController;

  @override
  void initState() {
    super.initState();
    favouriteController = FavouriteController();
    favouriteController.reloadFavourites();
  }

  @override
  void dispose() {
    favouriteController.dispose();
    super.dispose();
  }

  // Method để tương thích với layout_controller.dart
  Future<void> reloadFavourites() async {
    await favouriteController.reloadFavourites();
  }

  Future<void> _toggleFavourite(Map<String, dynamic> item, int index) async {
    final success = await favouriteController.toggleFavourite(
        item,
        index,
        context,
        widget.onFavouriteToggle
    );

    if (success) {
      // Hiển thị toast thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.favorite,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Đã xóa khỏi danh sách yêu thích',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF198754),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildItem(Map<String, dynamic> item, Animation<double>? animation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF198754).withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF198754).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onProductTap(item),
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color(0xFF198754).withOpacity(0.1),
          highlightColor: const Color(0xFF198754).withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image container với border và shadow
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF198754).withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF198754).withOpacity(0.05),
                      ),
                      child: item['hinhdaidien'].startsWith('assets/')
                          ? Image.asset(
                        item['hinhdaidien'],
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      )
                          : Image.network(
                        item['hinhdaidien'],
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF198754).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 40,
                            color: const Color(0xFF198754).withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        item['tieude'] ?? 'Không có tên',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a1a1a),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF198754).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF198754).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${formatCurrency(item['gia'])}₫',
                          style: const TextStyle(
                            color: const Color(0xFF198754),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Action buttons
                      Row(
                        children: [
                          // View button
                          Expanded(
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF198754),
                                    const Color(0xFF20C997),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF198754).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () => widget.onProductTap(item),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.visibility_outlined,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Xem chi tiết',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Remove button
                          Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: () => _toggleFavourite(item, favouriteController.wishlistItems.indexOf(item)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.red,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Icon(
                                Icons.favorite,
                                size: 18,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: favouriteController,
      child: Consumer<FavouriteController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FFF8), // Background xanh lá nhạt
            body: RefreshIndicator(
              color: const Color(0xFF198754), // Màu xanh lá
              onRefresh: controller.reloadFavourites,
              child: SafeArea(
                child: controller.isLoading
                    ? _buildLoadingState()
                    : controller.isEmpty
                    ? _buildEmptyState()
                    : _buildFavouritesList(controller),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF198754).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF198754),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Đang tải danh sách yêu thích...',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF198754).withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeInUp(
        duration: const Duration(milliseconds: 800),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF198754).withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.favorite_border,
                size: 80,
                color: const Color(0xFF198754).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Danh sách yêu thích trống',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF198754),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hãy thêm sản phẩm vào danh sách yêu thích\nđể xem chúng ở đây',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF198754).withOpacity(0.7),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavouritesList(FavouriteController controller) {
    return Column(
      children: [
        // Header
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF198754),
                const Color(0xFF20C997),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF198754).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Danh sách yêu thích',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${controller.itemCount} sản phẩm',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List items
        Expanded(
          child: AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: controller.wishlistItems.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 600),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildItem(controller.wishlistItems[index], null),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

String formatCurrency(dynamic price) {
  try {
    final doublePrice = price is String ? double.parse(price) : price.toDouble();
    return doublePrice.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  } catch (e) {
    return price?.toString() ?? '0';
  }
}