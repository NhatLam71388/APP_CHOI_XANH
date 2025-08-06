import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/view/until/until.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:http/http.dart' as http;

class APIFavouriteService {
  static const String baseUrl = 'https://demochung.125.atoz.vn';

  static Future<bool>? get isAlreadyFavourite => null;

  static Future<Object?> toggleFavourite({
    required BuildContext context,
    required String? userId,
    required int productId,
    required String tieude,
    required String gia,
    required String hinhdaidien,
    required String moduleType,
    String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = await AuthService.isLoggedIn();

    try {
      // Kiểm tra trạng thái hiện tại của sản phẩm trong danh sách yêu thích
      final wishlist = await fetchWishlistItems(userId: userId, password: password);
      bool isAlreadyFavourite = wishlist.any((item) => item['id'] == productId.toString());
      print(isLoggedIn);
      print(userId);
      print(password);
      if (isLoggedIn && userId != null && password != null) {
        // Trường hợp đã đăng nhập
        final md5Password = AuthService.generateMd5(password);
        final uri = isAlreadyFavourite
            ? Uri.parse('$baseUrl/ww1/remove.listwishlist.asp?userid=$userId&pass=$md5Password&id=$productId')
            : Uri.parse('$baseUrl/ww1/save.wishlist.asp?userid=$userId&pass=$md5Password&id=$productId');

        print('Toggle favourite URL (logged in): $uri');
        final response = await http.get(uri, headers: {
          'Accept': 'application/json',
        }).timeout(Duration(seconds: 5));

        print('Toggle favourite response status: ${response.statusCode}');
        print('Toggle favourite response body: ${response.body}');

        if (response.statusCode == 200) {
          final List<dynamic> jsonResponse = json.decode(response.body);
          if (jsonResponse.isNotEmpty && jsonResponse[0] is Map && jsonResponse[0].containsKey('ThongBao')) {
            final responseData = jsonResponse[0];
            final thongbao = responseData['ThongBao']?.toString() ?? '';
            final maloi = responseData['maloi']?.toString() ?? '0';
            final cleanMessage = thongbao.replaceAll(RegExp(r'<[^>]+>'), '').trim();

            if (maloi == '1') {
              if (isAlreadyFavourite && thongbao.contains('xóa khỏi danh mục wishlist')) {
                showToast(cleanMessage.isNotEmpty ? cleanMessage : 'Đã xóa $tieude khỏi yêu thích');
                return false; // Xóa thành công
              } else if (!isAlreadyFavourite && thongbao.contains('Đưa vào wishlist')) {
                showToast(cleanMessage.isNotEmpty ? cleanMessage : 'Đã thêm $tieude vào yêu thích');
                return true; // Thêm thành công
              }
            }
            showToast(cleanMessage.isNotEmpty ? cleanMessage : 'Thao tác thất bại', backgroundColor: Colors.red);
            return isAlreadyFavourite;
          } else {
            showToast('Dữ liệu phản hồi không hợp lệ', backgroundColor: Colors.red);
            return isAlreadyFavourite;
          }
        } else {
          showToast('Lỗi máy chủ: ${response.statusCode}', backgroundColor: Colors.red);
          return isAlreadyFavourite;
        }
      } else {
        // Trường hợp chưa đăng nhập
        String? wishlistCookie = prefs.getString('wishlistCookie') ?? '';
        if (wishlistCookie.isEmpty) {
          final cookies = await AuthService.fetchCookies();
          wishlistCookie = cookies['WishlistMabaogia'];
          if (wishlistCookie == null) {
            showToast('Không thể lấy cookie yêu thích', backgroundColor: Colors.red);
            return isAlreadyFavourite;
          }
          await prefs.setString('wishlistCookie', wishlistCookie);
        }

        final uri = isAlreadyFavourite
            ? Uri.parse('$baseUrl/cart/xoawl.asp?choixanh=xoasanpham&idpart=$productId')
            : Uri.parse('$baseUrl/ww1/addwishlist.asp?IDPart=$productId&id=$wishlistCookie');

        print('Toggle favourite URL (not logged in): $uri');
        final response = await http.get(uri, headers: {
          'Accept': 'application/json',
          'Cookie': 'WishlistMabaogia=$wishlistCookie',
        }).timeout(Duration(seconds: 5));

        print('Toggle favourite response status: ${response.statusCode}');
        print('Toggle favourite response body: ${response.body}');

        if (response.statusCode == 200) {
          // Xử lý phản hồi JavaScript
          String responseBody = response.body.trim();
          if (responseBody.startsWith('var info = ')) {
            responseBody = responseBody.replaceFirst('var info = ', '');
            if (responseBody.endsWith(';')) {
              responseBody = responseBody.substring(0, responseBody.length - 1);
            }
          }

          try {
            final responseData = json.decode(responseBody);
            if (responseData is Map && responseData.containsKey('thongbao')) {
              final thongbao = responseData['thongbao']?.toString() ?? '';
              final cleanMessage = thongbao.replaceAll(RegExp(r'<[^>]+>'), '').trim();

              if (isAlreadyFavourite && thongbao.contains('Đã xóa')) {
                showToast(cleanMessage.isNotEmpty ? cleanMessage : 'Đã xóa $tieude khỏi yêu thích');
                return false; // Xóa thành công
              } else if (!isAlreadyFavourite && thongbao.contains('Đã đưa') && thongbao.contains('vào yêu thích')) {
                showToast(cleanMessage.isNotEmpty ? cleanMessage : 'Đã thêm $tieude vào yêu thích');
                return true; // Thêm thành công
              } else {
                showToast(cleanMessage.isNotEmpty ? cleanMessage : 'Thao tác thất bại',
                    backgroundColor: Colors.red);
                return isAlreadyFavourite;
              }
            } else {
              showToast('Dữ liệu phản hồi không hợp lệ', backgroundColor: Colors.red);
              return isAlreadyFavourite;
            }
          } catch (e) {
            print('Lỗi phân tích JSON: $e');
            if (isAlreadyFavourite && responseBody.contains('Đã xóa')) {
              showToast('Đã xóa $tieude khỏi yêu thích');
              return false; // Xóa thành công
            } else if (!isAlreadyFavourite && responseBody.contains('Đã đưa') && responseBody.contains('vào yêu thích')) {
              showToast('Đã thêm $tieude vào yêu thích');
              return true; // Thêm thành công
            } else {
              showToast('Dữ liệu phản hồi không hợp lệ', backgroundColor: Colors.red);
              return isAlreadyFavourite;
            }
          }
        } else {
          showToast('Lỗi máy chủ: ${response.statusCode}', backgroundColor: Colors.red);
          return isAlreadyFavourite;
        }
      }
    } catch (e) {
      print('Lỗi: $e');
      showToast('Lỗi xử lý dữ liệu từ máy chủ', backgroundColor: Colors.red);
      return isAlreadyFavourite;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchWishlistItems({
    required String? userId,
    String? password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = await AuthService.isLoggedIn();

      if (isLoggedIn && userId != null && password != null) {
        // Trường hợp đã đăng nhập
        final md5Password = AuthService.generateMd5(password);
        final uri = Uri.parse('$baseUrl/ww1/member.1/Quanlydanhmucquantam.asp?userid=$userId&pass=$md5Password');
        print('Fetch wishlist items URL (logged in): $uri');

        final response = await http.get(uri, headers: {
          'Accept': 'application/json',
        }).timeout(Duration(seconds: 5));

        print('Fetch wishlist items response status: ${response.statusCode}');
        print('Fetch wishlist items response body: ${response.body}');

        if (response.statusCode == 200) {
          final List<dynamic> jsonResponse = json.decode(response.body);
          if (jsonResponse.isNotEmpty && jsonResponse[0] is Map && jsonResponse[0].containsKey('data')) {
            final List<dynamic> data = jsonResponse[0]['data'];

            // Lưu trữ hinhdaidien vào SharedPreferences
            final cachedImages = prefs.getString('wishlist_images') ?? '{}';
            final imageCache = json.decode(cachedImages) as Map<String, dynamic>;

            List<Map<String, dynamic>> items = [];
            for (var item in data) {
              final productId = item['id']?.toString() ?? '';
              String? hinhdaidien = imageCache[productId];

              // Nếu không có ảnh trong cache, gọi API chi tiết sản phẩm
              if (hinhdaidien == null || hinhdaidien.isEmpty) {
                final productDetail = await APIService.fetchProductDetail(
                  baseUrl,
                  'sanpham',
                  productId,
                      (_) => [], // Truyền hàm rỗng vì không cần danh sách hình
                );
                hinhdaidien = productDetail != null && productDetail['hinhdaidien'] != null
                    ? '$baseUrl${productDetail['hinhdaidien']}'
                    : 'https://via.placeholder.com/150';

                // Lưu ảnh vào cache
                imageCache[productId] = hinhdaidien;
                await prefs.setString('wishlist_images', json.encode(imageCache));
              }

              items.add({
                'id': productId,
                'tieude': item['tieude']?.toString() ?? '',
                'gia': double.tryParse(item['gia']?.toString() ?? '0') ?? 0,
                'hinhdaidien': hinhdaidien,
                'moduleType': 'sanpham',
              });
            }

            return items;
          } else {
            print("❌ API trả về dữ liệu không hợp lệ (logged in)");
            return [];
          }
        } else {
          print("❌ Lỗi máy chủ: ${response.statusCode}");
          return [];
        }
      } else {
        // Trường hợp chưa đăng nhập
        String? wishlistCookie = prefs.getString('wishlistCookie') ?? '';
        if (wishlistCookie.isEmpty) {
          final cookies = await AuthService.fetchCookies();
          wishlistCookie = cookies['WishlistMabaogia'];
          if (wishlistCookie == null) {
            print('❌ Không thể lấy cookie yêu thích');
            return [];
          }
          await prefs.setString('wishlistCookie', wishlistCookie);
        }

        final uri = Uri.parse('$baseUrl/ww1/wishlisthientai.asp');
        print('Fetch wishlist items URL (not logged in): $uri');
        print('Wishlist cookie: $wishlistCookie');

        final response = await http.get(uri, headers: {
          'Accept': 'application/json',
          'Cookie': 'WishlistMabaogia=$wishlistCookie',
        }).timeout(Duration(seconds: 5));

        print('Fetch wishlist items response status: ${response.statusCode}');
        print('Fetch wishlist items response body: ${response.body}');

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);

          if (jsonResponse is Map && jsonResponse.containsKey('items') && jsonResponse['items'] is List) {
            final List<dynamic> data = jsonResponse['items'];

            List<Map<String, dynamic>> items = data.map((item) {
              return {
                'id': item['id']?.toString() ?? '',
                'tieude': item['partName']?.toString() ?? '',
                'gia': double.tryParse(item['price']?.toString() ?? '0') ?? 0,
                'hinhdaidien': item['image'] != null
                    ? '$baseUrl${item['image']}'
                    : 'https://via.placeholder.com/150',
                'moduleType': 'sanpham',
              };
            }).toList();

            return items;
          } else {
            print("❌ API trả về dữ liệu không hợp lệ (not logged in)");
            return [];
          }
        } else {
          print("❌ Lỗi máy chủ: ${response.statusCode}");
          return [];
        }
      }
    } catch (e) {
      print("❌ Lỗi kết nối hoặc parse JSON: $e");
      return [];
    }
  }
}