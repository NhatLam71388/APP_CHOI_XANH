import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/view/until/until.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:cookie_jar/cookie_jar.dart';

class APIFavouriteService {
  static Future<bool>? get isAlreadyFavourite => null;

  static Future<Object?> toggleFavourite({
    required BuildContext? context,
    required String? userId,
    required int id,
    required String idbg,
    required String tieude,
    required String gia,
    required String hinhdaidien,
    required String moduleType,
    String? password,
    ValueNotifier<int>? wishlistItemCountNotifier, // Thêm tham số để cập nhật số lượng
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = await AuthService.isLoggedIn();
    String? cartCookie = prefs.getString('cartCookie') ?? '';
    String? wishlistCookie = prefs.getString('wishlistCookie') ?? '';

    // Hình ảnh dự phòng cục bộ
    const defaultImage = 'assets/images/placeholder.png';

    // Kiểm tra và lấy hinhdaidien từ API nếu chưa đăng nhập
    String effectiveHinhDaiDien = defaultImage;
    if (!isLoggedIn || userId == null || password == null) {
      final productDetail = await APIService.fetchProductDetail(
        APIService.baseUrl,
        moduleType,
        id.toString(),
            (_) => [],
      );
      effectiveHinhDaiDien = productDetail != null && productDetail['hinhdaidien'] != null
          ? '${APIService.baseUrl}${productDetail['hinhdaidien']}'
          : defaultImage;
    } else {
      effectiveHinhDaiDien = hinhdaidien.isNotEmpty && Uri.tryParse(hinhdaidien)?.hasAbsolutePath == true
          ? hinhdaidien
          : defaultImage;
    }
    print('toggleFavourite - Input hinhdaidien: $hinhdaidien, effectiveHinhDaiDien: $effectiveHinhDaiDien');

    try {
      if (cartCookie.isEmpty) {
        final cookies = await AuthService.fetchCookies();
        cartCookie = cookies['DathangMabaogia'];
        if (cartCookie == null) {
          print('❌ Không thể lấy cookie DathangMabaogia');
          cartCookie = '';
        } else {
          await prefs.setString('cartCookie', cartCookie);
        }
      }

      if (wishlistCookie.isEmpty) {
        final cookies = await AuthService.fetchCookies();
        wishlistCookie = cookies['WishlistMabaogia'];
        if (wishlistCookie == null) {
          print('❌ Không thể lấy cookie WishlistMabaogia');
          wishlistCookie = '';
        } else {
          await prefs.setString('wishlistCookie', wishlistCookie);
        }
      }

      final effectiveIdbg = idbg.isNotEmpty ? idbg : wishlistCookie;
      if (effectiveIdbg.isEmpty) {
        print('❌ Lỗi: idbg và wishlistCookie đều rỗng');
        showToast('Không thể thêm/xóa yêu thích: Cookie Wishlist không hợp lệ', backgroundColor: Colors.red);
        return false;
      }

      final wishlist = await fetchWishlistItems(userId: userId, password: password);
      bool isAlreadyFavourite = wishlist.any((item) => item['id'].toString() == id.toString());
      print('isLoggedIn: $isLoggedIn, userId: $userId, password: $password, id: $id, idbg: $effectiveIdbg, isAlreadyFavourite: $isAlreadyFavourite');

      if (!isLoggedIn || userId == null || password == null) {
        final wishlistItemsJson = prefs.getString('local_wishlist_items') ?? '[]';
        List<dynamic> wishlistItems = json.decode(wishlistItemsJson);

        if (isAlreadyFavourite) {
          wishlistItems.removeWhere((item) => item['id'].toString() == id.toString());
          await prefs.setString('local_wishlist_items', json.encode(wishlistItems));
          showToast('Đã xóa $tieude khỏi yêu thích (chưa đăng nhập)', backgroundColor: Colors.green);
          print('Wishlist after removal: $wishlistItems');
          // Cập nhật số lượng yêu thích
          if (wishlistItemCountNotifier != null) {
            wishlistItemCountNotifier.value = wishlistItems.length;
          }
          return false;
        } else {
          wishlistItems.add({
            'id': id,
            'idbg': effectiveIdbg,
            'tieude': tieude,
            'gia': gia,
            'hinhdaidien': effectiveHinhDaiDien,
            'moduleType': moduleType,
          });
          await prefs.setString('local_wishlist_items', json.encode(wishlistItems));
          showToast('Đã thêm $tieude vào yêu thích (chưa đăng nhập)', backgroundColor: Colors.green);
          print('Wishlist after addition: $wishlistItems');
          // Cập nhật số lượng yêu thích
          if (wishlistItemCountNotifier != null) {
            wishlistItemCountNotifier.value = wishlistItems.length;
          }
          return true;
        }
      }

      final md5Password = AuthService.generateMd5(password);
      final uri = isAlreadyFavourite
          ? Uri.parse('${APIService.baseUrl}/ww1/remove.listwishlist.asp?userid=$userId&pass=$md5Password&id=$id')
          : Uri.parse('${APIService.baseUrl}/ww1/save.wishlist.asp?userid=$userId&pass=$md5Password&id=$id');

      final cookies = await AuthService.cookieJar.loadForRequest(uri);
      final filteredCookies = cookies
          .where((c) => c.name != 'DathangMabaogia' && c.name != 'WishlistMabaogia')
          .toList();
      filteredCookies.add(Cookie('DathangMabaogia', cartCookie));
      filteredCookies.add(Cookie('WishlistMabaogia', effectiveIdbg));
      final headers = {
        'Accept': 'application/json',
        'Cookie': filteredCookies.map((c) => '${c.name}=${c.value}').join('; '),
      };

      print('Toggle favourite URL (logged in): $uri');
      print('Headers: $headers');
      print('Using cartCookie: $cartCookie for DathangMabaogia cookie');
      print('Using idbg: $effectiveIdbg for WishlistMabaogia cookie');

      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 5));

      print('Toggle favourite response status: ${response.statusCode}');
      print('Toggle favourite response body: ${response.body}');

      if (response.headers.containsKey('set-cookie')) {
        final cookie = Cookie.fromSetCookieValue(response.headers['set-cookie']!.split(';')[0]);
        if (cookie.name != 'DathangMabaogia' && cookie.name != 'WishlistMabaogia') {
          await AuthService.cookieJar.saveFromResponse(uri, [cookie]);
        }
      }

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse;
        try {
          jsonResponse = json.decode(response.body);
        } catch (e) {
          print('Lỗi phân tích JSON: $e');
          showToast('Dữ liệu phản hồi không hợp lệ', backgroundColor: Colors.red);
          return isAlreadyFavourite;
        }

        if (jsonResponse.isNotEmpty && jsonResponse[0] is Map && jsonResponse[0].containsKey('ThongBao')) {
          final responseData = jsonResponse[0];
          final thongbao = responseData['ThongBao']?.toString() ?? '';
          final maloi = responseData['maloi']?.toString() ?? '0';
          final cleanMessage = thongbao.replaceAll(RegExp(r'<[^>]+>'), '').trim();

          if (maloi == '1') {
            if (isAlreadyFavourite && thongbao.contains('xóa khỏi danh mục wishlist')) {
              showToast(cleanMessage.isNotEmpty ? cleanMessage : 'Đã xóa $tieude khỏi yêu thích', backgroundColor: Colors.green);
              // Cập nhật số lượng yêu thích
              if (wishlistItemCountNotifier != null && userId != null) {
                final count = await getWishlistItemCountFromApi(userId);
                wishlistItemCountNotifier.value = count;
              }
              return false;
            } else if (!isAlreadyFavourite && thongbao.contains('Đưa vào wishlist')) {
              showToast(cleanMessage.isNotEmpty ? cleanMessage : 'Đã thêm $tieude vào yêu thích', backgroundColor: Colors.green);
              // Cập nhật số lượng yêu thích
              if (wishlistItemCountNotifier != null && userId != null) {
                final count = await getWishlistItemCountFromApi(userId);
                wishlistItemCountNotifier.value = count;
              }
              return true;
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
    } catch (e) {
      print('Lỗi: $e');
      showToast('Lỗi xử lý dữ liệu từ máy chủ', backgroundColor: Colors.red);
      return isAlreadyFavourite;
    }
  }

  static Future<bool> syncLocalWishlistToServer({
    required String userId,
    required String password,
    ValueNotifier<int>? wishlistItemCountNotifier, // Thêm tham số để cập nhật số lượng
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final wishlistItemsJson = prefs.getString('local_wishlist_items') ?? '[]';
    final List<dynamic> localWishlistItems = json.decode(wishlistItemsJson);

    if (localWishlistItems.isEmpty) {
      return true;
    }

    bool allSuccess = true;
    for (var item in localWishlistItems) {
      final result = await toggleFavourite(
        context: null,
        userId: userId,
        id: item['id'],
        idbg: item['idbg'],
        tieude: item['tieude'],
        gia: item['gia'],
        hinhdaidien: item['hinhdaidien'],
        moduleType: item['moduleType'],
        password: password,
        wishlistItemCountNotifier: wishlistItemCountNotifier, // Truyền notifier vào
      );
      if (result == false) {
        allSuccess = false;
      }
    }

    if (allSuccess) {
      await prefs.setString('local_wishlist_items', '[]');
      showToast('Đã đồng bộ danh sách yêu thích lên server', backgroundColor: Colors.green);
      // Cập nhật số lượng yêu thích sau khi đồng bộ
      if (wishlistItemCountNotifier != null) {
        final count = await getWishlistItemCountFromApi(userId);
        wishlistItemCountNotifier.value = count;
      }
    } else {
      showToast('Có lỗi khi đồng bộ một số sản phẩm yêu thích', backgroundColor: Colors.red);
    }

    return allSuccess;
  }

  static Future<List<Map<String, dynamic>>> fetchWishlistItems({
    required String? userId,
    String? password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = await AuthService.isLoggedIn();
      String? cartCookie = prefs.getString('cartCookie') ?? '';
      String? wishlistCookie = prefs.getString('wishlistCookie') ?? '';

      if (cartCookie.isEmpty) {
        final cookies = await AuthService.fetchCookies();
        cartCookie = cookies['DathangMabaogia'];
        if (cartCookie == null) {
          print('❌ Không thể lấy cookie DathangMabaogia');
          cartCookie = '';
        } else {
          await prefs.setString('cartCookie', cartCookie);
        }
      }

      if (wishlistCookie.isEmpty) {
        final cookies = await AuthService.fetchCookies();
        wishlistCookie = cookies['WishlistMabaogia'];
        if (wishlistCookie == null) {
          print('❌ Không thể lấy cookie WishlistMabaogia');
          wishlistCookie = '';
        } else {
          await prefs.setString('wishlistCookie', wishlistCookie);
        }
      }

      if (!isLoggedIn || userId == null || password == null) {
        final wishlistItemsJson = prefs.getString('local_wishlist_items') ?? '[]';
        final List<dynamic> wishlistItems = json.decode(wishlistItemsJson);
        print('Fetched wishlist (not logged in): $wishlistItems');
        // Kiểm tra và cập nhật hinhdaidien nếu cần
        List<Map<String, dynamic>> updatedItems = [];
        for (var item in wishlistItems) {
          final productId = item['id'].toString();
          String hinhdaidien = item['hinhdaidien'];
          if (hinhdaidien.isEmpty || !Uri.tryParse(hinhdaidien)!.hasAbsolutePath == true) {
            final productDetail = await APIService.fetchProductDetail(
              APIService.baseUrl,
              item['moduleType'],
              productId,
                  (_) => [],
            );
            hinhdaidien = productDetail != null && productDetail['hinhdaidien'] != null
                ? '${APIService.baseUrl}${productDetail['hinhdaidien']}'
                : 'assets/images/placeholder.png';
            item['hinhdaidien'] = hinhdaidien;
          }
          updatedItems.add(Map<String, dynamic>.from(item));
        }
        await prefs.setString('local_wishlist_items', json.encode(updatedItems));
        return updatedItems;
      }

      final md5Password = AuthService.generateMd5(password);
      final uri = Uri.parse('${APIService.baseUrl}/ww1/member.1/Quanlydanhmucquantam.asp?userid=$userId&pass=$md5Password');

      final cookies = await AuthService.cookieJar.loadForRequest(uri);
      final filteredCookies = cookies
          .where((c) => c.name != 'DathangMabaogia' && c.name != 'WishlistMabaogia')
          .toList();
      filteredCookies.add(Cookie('DathangMabaogia', cartCookie));
      filteredCookies.add(Cookie('WishlistMabaogia', wishlistCookie));
      final headers = {
        'Accept': 'application/json',
        'Cookie': filteredCookies.map((c) => '${c.name}=${c.value}').join('; '),
      };

      print('Fetch wishlist items URL (logged in): $uri');
      print('Headers: $headers');
      print('Using cartCookie: $cartCookie for DathangMabaogia cookie');
      print('Using wishlistCookie: $wishlistCookie for WishlistMabaogia cookie');

      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 5));

      print('Fetch wishlist items response status: ${response.statusCode}');
      print('Fetch wishlist items response body: ${response.body}');

      if (response.headers.containsKey('set-cookie')) {
        final cookie = Cookie.fromSetCookieValue(response.headers['set-cookie']!.split(';')[0]);
        if (cookie.name != 'DathangMabaogia' && cookie.name != 'WishlistMabaogia') {
          await AuthService.cookieJar.saveFromResponse(uri, [cookie]);
        }
      }

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse;
        try {
          jsonResponse = json.decode(response.body);
        } catch (e) {
          print('❌ Lỗi phân tích JSON: $e');
          return [];
        }

        if (jsonResponse.isNotEmpty && jsonResponse[0] is Map && jsonResponse[0].containsKey('data')) {
          final List<dynamic> data = jsonResponse[0]['data'];
          final cachedImages = prefs.getString('wishlist_images') ?? '{}';
          final imageCache = json.decode(cachedImages) as Map<String, dynamic>;

          List<Map<String, dynamic>> items = [];
          for (var item in data) {
            final productId = item['id']?.toString() ?? '';
            final idbg = item['idbg']?.toString() ?? wishlistCookie;
            String? hinhdaidien = imageCache[productId];

            if (hinhdaidien == null || hinhdaidien.isEmpty) {
              final productDetail = await APIService.fetchProductDetail(
                APIService.baseUrl,
                'sanpham',
                productId,
                    (_) => [],
              );
              hinhdaidien = productDetail != null && productDetail['hinhdaidien'] != null
                  ? '${APIService.baseUrl}${productDetail['hinhdaidien']}'
                  : 'assets/images/placeholder.png';

              imageCache[productId] = hinhdaidien;
              await prefs.setString('wishlist_images', json.encode(imageCache));
            }

            items.add({
              'id': productId,
              'idbg': idbg,
              'tieude': item['tieude']?.toString() ?? '',
              'gia': double.tryParse(item['gia']?.toString() ?? '0') ?? 0,
              'hinhdaidien': hinhdaidien,
              'moduleType': 'sanpham',
            });
          }

          print('Fetched wishlist items (logged in): $items');
          return items;
        } else {
          print('❌ API trả về dữ liệu không hợp lệ (logged in)');
          return [];
        }
      } else {
        print('❌ Lỗi máy chủ: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Lỗi kết nối hoặc parse JSON: $e');
      return [];
    }
  }

  static Future<int> getWishlistItemCountFromApi(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = await AuthService.isLoggedIn();
    String? cartCookie = prefs.getString('cartCookie') ?? '';
    String? wishlistCookie = prefs.getString('wishlistCookie') ?? '';

    if (cartCookie.isEmpty) {
      final cookies = await AuthService.fetchCookies();
      cartCookie = cookies['DathangMabaogia'];
      if (cartCookie == null) {
        print('❌ Không thể lấy cookie DathangMabaogia');
        cartCookie = '';
      } else {
        await prefs.setString('cartCookie', cartCookie);
      }
    }

    if (wishlistCookie.isEmpty) {
      final cookies = await AuthService.fetchCookies();
      wishlistCookie = cookies['WishlistMabaogia'];
      if (wishlistCookie == null) {
        print('❌ Không thể lấy cookie WishlistMabaogia');
        wishlistCookie = '';
      } else {
        await prefs.setString('wishlistCookie', wishlistCookie);
      }
    }

    if (!isLoggedIn || email.isEmpty) {
      final wishlistItemsJson = prefs.getString('local_wishlist_items') ?? '[]';
      final List<dynamic> wishlistItems = json.decode(wishlistItemsJson);
      return wishlistItems.length;
    }

    final md5Password = AuthService.generateMd5(prefs.getString('passWord') ?? '');
    final uri = Uri.parse(
      '${APIService.baseUrl}/ww1/member.1/Quanlydanhmucquantam.asp?userid=$email&pass=$md5Password',
    );

    final cookies = await AuthService.cookieJar.loadForRequest(uri);
    final filteredCookies = cookies
        .where((c) => c.name != 'DathangMabaogia' && c.name != 'WishlistMabaogia')
        .toList();
    filteredCookies.add(Cookie('DathangMabaogia', cartCookie));
    filteredCookies.add(Cookie('WishlistMabaogia', wishlistCookie));
    final headers = {
      'Accept': 'application/json',
      'Cookie': filteredCookies.map((c) => '${c.name}=${c.value}').join('; '),
    };

    print('Get wishlist count URL: $uri');
    print('Headers: $headers');
    print('Using cartCookie: $cartCookie for DathangMabaogia cookie');
    print('Using wishlistCookie: $wishlistCookie for WishlistMabaogia cookie');

    try {
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 5));

      print('Get wishlist count response status: ${response.statusCode}');
      print('Get wishlist count response body: ${response.body}');

      if (response.headers.containsKey('set-cookie')) {
        final cookie = Cookie.fromSetCookieValue(response.headers['set-cookie']!.split(';')[0]);
        if (cookie.name != 'DathangMabaogia' && cookie.name != 'WishlistMabaogia') {
          await AuthService.cookieJar.saveFromResponse(uri, [cookie]);
        }
      }

      if (response.statusCode == 200) {
        String cleanedResponse = response.body;
        cleanedResponse = cleanedResponse.replaceAllMapped(
          RegExp(r'(?<=tieude":\s*")[^"]*?(")(?=[^"]*?",)'),
              (match) => match.group(0)!.replaceAll('"', '\\"'),
        );

        print('Cleaned JSON response: $cleanedResponse');

        final List<dynamic> data;
        try {
          data = json.decode(cleanedResponse);
        } catch (e) {
          print('❌ Lỗi phân tích JSON: $e');
          return 0;
        }

        if (data.isNotEmpty && data[0] is Map && data[0].containsKey('recordsTotal')) {
          return data[0]['recordsTotal'] as int;
        }
        print('Dữ liệu tổng hợp không hợp lệ: $data');
        return 0;
      } else {
        print('Không thể lấy số lượng sản phẩm yêu thích: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      print('Lỗi kết nối khi lấy số lượng yêu thích: $e');
      return 0;
    }
  }
}