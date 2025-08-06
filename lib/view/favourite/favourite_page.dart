import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/favourite_service.dart';
import 'package:flutter_application_1/view/home/homepage.dart';
import 'package:flutter_application_1/view/until/until.dart';

class favouritePage extends StatefulWidget {
  final Function(dynamic product) onProductTap;
  const favouritePage({super.key, required this.onProductTap});

  @override
  State<favouritePage> createState() => favouritePageState();
}

class favouritePageState extends State<favouritePage> with WidgetsBindingObserver {
  List<Map<String, dynamic>> favouriteItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadUserAndFavourites();
  }

  Future<void> loadUserAndFavourites() async {
    try {
      // Lấy userId từ AuthService (có thể null nếu chưa đăng nhập)
      final userId = await AuthService.getUserId();
      print('User ID: $userId');

      // Lấy danh sách yêu thích từ server
      final serverItems = await APIFavouriteService.fetchWishlistItems(userId: userId, password: Global.pass);
      print('Danh sách yêu thích từ server: $serverItems');

      setState(() {
        favouriteItems = serverItems;
      });
    } catch (e) {
      print('Lỗi khi tải danh sách yêu thích: $e');
      showToast('Không thể tải danh sách yêu thích', backgroundColor: Colors.red);
    }
  }

  Future<void> reloadFavourites() async {
    await loadUserAndFavourites(); // Tái sử dụng hàm loadUserAndFavourites để làm mới
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        color: Color(0xff0066FF),
        onRefresh: reloadFavourites,
        child: favouriteItems.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('Chưa có sản phẩm yêu thích'),
            ],
          ),
        )
            : ListView.builder(
          itemCount: favouriteItems.length,
          itemBuilder: (context, index) {
            final item = favouriteItems[index];
            return GestureDetector(
              onTap: () {
                widget.onProductTap(item);
              },
              child: Card(
                elevation: 0,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            border: Border.all(width: 0.5, color: Colors.black12)),
                        child: Image.network(
                          '${item['hinhdaidien']}',
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 60),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item['tieude']}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 4),
                              if (item['gia'] != null && item['gia'].toString().trim().isNotEmpty)
                                Text(
                                  '${formatCurrency(item['gia'])}₫',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 15,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}