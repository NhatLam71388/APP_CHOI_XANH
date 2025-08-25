import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/favourite_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavouriteController extends ChangeNotifier {
  List<Map<String, dynamic>> wishlistItems = [];
  bool isLoading = true;

  Future<void> reloadFavourites() async {
    isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('emailAddress') ?? '';
      final password = prefs.getString('passWord') ?? '';
      
      // Nếu chưa đăng nhập, vẫn gọi API để lấy danh sách yêu thích
      final items = await APIFavouriteService.fetchWishlistItems(
        userId: userId.isNotEmpty ? userId : null,
        password: userId.isNotEmpty ? password : null,
      );
      
      wishlistItems = items;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Lỗi khi tải danh sách yêu thích: $e');
      wishlistItems = [];
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleFavourite(Map<String, dynamic> item, int index, BuildContext context, VoidCallback? onFavouriteToggle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('emailAddress') ?? '';
      final password = prefs.getString('passWord') ?? '';

      final result = await APIFavouriteService.toggleFavourite(
        context: context,
        userId: userId.isNotEmpty ? userId : null,
        password: userId.isNotEmpty ? password : null,
        id: item['id'] is String ? int.parse(item['id']) : item['id'],
        idbg: item['idbg'],
        tieude: item['tieude'],
        gia: item['gia'].toString(),
        hinhdaidien: item['hinhdaidien'],
        moduleType: item['moduleType'],
      );

      if (result is bool && !result) {
        // Xóa sản phẩm khỏi danh sách
        wishlistItems.removeAt(index);
        notifyListeners();
        
        if (onFavouriteToggle != null) {
          onFavouriteToggle();
        }
        
        return true; // Successfully removed
      } else if (result is bool && result) {
        // Sản phẩm đã được thêm vào yêu thích, cần refresh danh sách
        await reloadFavourites();
        
        if (onFavouriteToggle != null) {
          onFavouriteToggle();
        }
        
        return true; // Successfully added
      }
      return false;
    } catch (e) {
      print('❌ Lỗi khi toggle favourite: $e');
      return false;
    }
  }

  // Method để refresh danh sách khi cần thiết (ví dụ: khi quay lại từ trang khác)
  Future<void> refreshFavourites() async {
    await reloadFavourites();
  }

  void removeItem(int index) {
    if (index >= 0 && index < wishlistItems.length) {
      wishlistItems.removeAt(index);
      notifyListeners();
    }
  }

  int get itemCount => wishlistItems.length;
  
  bool get isEmpty => wishlistItems.isEmpty;
  
  bool get hasItems => wishlistItems.isNotEmpty;
}

