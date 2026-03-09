import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/product_model.dart';
import 'package:flutter_application_1/widgets/custom_snackbar.dart';
import 'package:flutter_application_1/widgets/until.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:cookie_jar/cookie_jar.dart';

class APICartService {
  static Future<String?> addToCart({
    required BuildContext context,
    required String moduleType,
    required String? emailAddress,
    required String? password,
    required int productId,
    required ValueNotifier<int> cartitemCount,
    required int quantity,
    String? idbg, // Thêm idbg để gửi trong cookie DathangMabaogia
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = await AuthService.isLoggedIn();
    String? cartCookie = prefs.getString('cartCookie') ?? '';
    String? wishlistCookie = prefs.getString('wishlistCookie') ?? '';

    print('isLoggedIn: $isLoggedIn, emailAddress: $emailAddress, password: $password, productId: $productId, idbg: $idbg');

    try {
      if (!isLoggedIn || emailAddress == null || password == null) {
        // Handle unauthenticated user
        final cartItemsJson = prefs.getString('local_cart_items') ?? '[]';
        List<dynamic> cartItems = json.decode(cartItemsJson);
        final existingItemIndex = cartItems.indexWhere((item) => item['productId'] == productId);

        if (existingItemIndex != -1) {
          // Update quantity if item already exists
          cartItems[existingItemIndex]['quantity'] = quantity;
        } else {
          // Add new item
          cartItems.add({
            'productId': productId,
            'quantity': quantity,
            'moduleType': moduleType,
          });
        }

        await prefs.setString('local_cart_items', json.encode(cartItems));
        cartitemCount.value = cartItems.length;
        CustomSnackBar.showSuccess(context, message: 'Đã thêm vào giỏ hàng');
        return null;
      }

      // Lấy cookie DathangMabaogia nếu chưa có
      if (cartCookie.isEmpty) {
        final cookies = await AuthService.fetchCookies();
        cartCookie = cookies['DathangMabaogia'];
        if (cartCookie == null) {
          print('❌ Không thể lấy cookie DathangMabaogia');
          showToast('Không thể thêm sản phẩm vào giỏ hàng', backgroundColor: Colors.red);
          return 'Không thể lấy cookie giỏ hàng';
        }
        await prefs.setString('cartCookie', cartCookie);
      }

      // Lấy cookie WishlistMabaogia nếu chưa có
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

      final md5Password = AuthService.generateMd5(password);
      final uri = Uri.parse(
        '${APIService.baseUrl}/ww1/save.addcart.asp?userid=$emailAddress&pass=$md5Password&id=$productId',
      );

      final cookies = await AuthService.cookieJar.loadForRequest(uri);
      // Loại bỏ cookie DathangMabaogia và WishlistMabaogia hiện có
      final filteredCookies = cookies
          .where((c) => c.name != 'DathangMabaogia' && c.name != 'WishlistMabaogia')
          .toList();
      // Thêm cookie DathangMabaogia và WishlistMabaogia
      filteredCookies.add(Cookie('DathangMabaogia', idbg ?? cartCookie));
      filteredCookies.add(Cookie('WishlistMabaogia', wishlistCookie));
      final headers = {
        'Accept': 'application/json',
        'Cookie': filteredCookies.map((c) => '${c.name}=${c.value}').join('; '),
      };

      print('Add to cart URL: $uri');
      print('Headers: $headers');
      print('Using idbg: ${idbg ?? cartCookie} for DathangMabaogia cookie');
      print('Using wishlistCookie: $wishlistCookie for WishlistMabaogia cookie');

      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 5));

      print('Add to cart response status: ${response.statusCode}');
      print('Add to cart response body: ${response.body}');

      // Lưu cookie mới chỉ nếu không phải DathangMabaogia hoặc WishlistMabaogia
      if (response.headers.containsKey('set-cookie')) {
        final cookie = Cookie.fromSetCookieValue(response.headers['set-cookie']!.split(';')[0]);
        if (cookie.name != 'DathangMabaogia' && cookie.name != 'WishlistMabaogia') {
          await AuthService.cookieJar.saveFromResponse(uri, [cookie]);
        }
      }

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse.isNotEmpty && jsonResponse[0] is Map && jsonResponse[0].containsKey('ThongBao')) {
          final responseData = jsonResponse[0];
          final thongbao = responseData['ThongBao']?.toString() ?? '';
          final maloi = responseData['maloi']?.toString() ?? '0';

          if (maloi == '1' && thongbao.contains('Đưa công việc vào danh sách chờ nộp đơn')) {
            final cartItems = await fetchCartItemsById(
              emailAddress: emailAddress,
              cartitemCount: cartitemCount,
              password: password,
            );
            cartitemCount.value = cartItems.length;
            CustomSnackBar.showSuccess(context, message: 'Đã thêm vào giỏ hàng');
            return null;
          } else {
            showToast('Thao tác thất bại', backgroundColor: Colors.red);
          }
        } else {
          showToast('Dữ liệu phản hồi không hợp lệ', backgroundColor: Colors.red);
          return 'Dữ liệu phản hồi không hợp lệ';
        }
      } else {
        showToast('Lỗi máy chủ: ${response.statusCode}', backgroundColor: Colors.red);
        return 'Lỗi máy chủ: ${response.statusCode}';
      }
    } catch (e) {
      print('Exception in addToCart: $e');
      showToast('Lỗi xử lý dữ liệu từ máy chủ', backgroundColor: Colors.red);
      return 'Lỗi xử lý dữ liệu từ máy chủ';
    }
  }

  static Future<List<CartItemModel>> fetchCartItemsById({
    required String? emailAddress,
    ValueNotifier<int>? cartitemCount,
    String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = await AuthService.isLoggedIn();
    print('isLoggedIn: $isLoggedIn, emailAddress: $emailAddress, password: $password');

    if (!isLoggedIn || emailAddress == null || password == null) {
      // Handle unauthenticated user
      final cartItemsJson = prefs.getString('local_cart_items') ?? '[]';
      final List<dynamic> cartItems = json.decode(cartItemsJson);
      final cachedImages = prefs.getString('cart_images') ?? '{}';
      final imageCache = json.decode(cachedImages) as Map<String, dynamic>;

      List<CartItemModel> items = [];
      for (var item in cartItems) {
        final id = item['productId'].toString();
        final quantity = item['quantity'] ?? 1;
        final moduleType = item['moduleType'] ?? 'sanpham';

        String? image = imageCache[id];
        String productName = 'Sản phẩm $id'; // Default name
        double productPrice = 0.0; // Default price
        
        // Fetch product details to get real name and price
        try {
          final productDetail = await APIService.fetchProductDetail(
            APIService.baseUrl,
            moduleType,
            id,
            (_) => [],
          );
          
          if (productDetail != null) {
            // Get real product name
            if (productDetail['tieude'] != null) {
              productName = productDetail['tieude'].toString();
            }
            
            // Get real product price
            if (productDetail['gia'] != null) {
              productPrice = double.tryParse(productDetail['gia'].toString()) ?? 0.0;
            }
            
            // Get product image
            if (productDetail['hinhdaidien'] != null) {
              image = '${APIService.baseUrl}${productDetail['hinhdaidien']}';
            }
          }
        } catch (e) {
          print('❌ Lỗi khi lấy thông tin sản phẩm $id: $e');
          // Keep default values if API call fails
        }

        if (image == null || image.isEmpty) {
          image = 'https://via.placeholder.com/150';
        }

        // Cache the image
        imageCache[id] = image;
        await prefs.setString('cart_images', json.encode(imageCache));

        print('🛒 SP (Local): $productName | ID: $id | SL: $quantity | Price: $productPrice | Image: $image');

        items.add(CartItemModel(
          id: id,
          idbg: '',
          name: productName, // Use real product name instead of placeholder
          price: productPrice, // Use real product price instead of placeholder
          moduleType: moduleType,
          image: image,
          quantity: quantity,
          isSelect: false,
          categoryId: 0,
        ));
      }

      if (cartitemCount != null) {
        cartitemCount.value = items.length;
      }
      return items;
    }

    try {
      final md5Password = AuthService.generateMd5(password);
      final uri = Uri.parse(
        '${APIService.baseUrl}/ww1/member.1/Quanlydanhmucsanphamgiohang.asp?userid=$emailAddress&pass=$md5Password&pageid=all',
      );

      final cookies = await AuthService.cookieJar.loadForRequest(uri);
      final headers = {
        'Accept': 'application/json',
        if (cookies.isNotEmpty) 'Cookie': cookies.map((c) => '${c.name}=${c.value}').join('; '),
      };

      print('Fetch cart items URL: $uri');
      print('Headers: $headers');

      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 5));

      print('Fetch cart items response status: ${response.statusCode}');
      print('Fetch cart items response body: ${response.body}');

      // Lưu cookie mới chỉ nếu không phải DathangMabaogia
      if (response.headers.containsKey('set-cookie')) {
        final cookie = Cookie.fromSetCookieValue(response.headers['set-cookie']!.split(';')[0]);
        if (cookie.name != 'DathangMabaogia') {
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

        final List<dynamic> jsonResponse;
        try {
          jsonResponse = json.decode(cleanedResponse);
        } catch (e) {
          print('❌ Lỗi phân tích JSON: $e');
          showToast('Lỗi dữ liệu giỏ hàng, vui lòng thử lại', backgroundColor: Colors.red);
          if (cartitemCount != null) {
            cartitemCount.value = 0;
          }
          return [];
        }

        if (jsonResponse.isNotEmpty && jsonResponse[0] is Map && jsonResponse[0].containsKey('data')) {
          final List<dynamic> data = jsonResponse[0]['data'];

          final cachedImages = prefs.getString('cart_images') ?? '{}';
          final imageCache = json.decode(cachedImages) as Map<String, dynamic>;

          List<CartItemModel> items = [];
          for (var item in data) {
            final id = item['id']?.toString() ?? '';
            final idbg = item['idbg']?.toString() ?? '';
            final name = item['tieude']?.toString() ?? '';
            final price = double.tryParse(item['gia']?.toString() ?? '0') ?? 0;
            final quantity = int.tryParse(item['soluong']?.toString() ?? '1') ?? 1;
            final moduleType = 'sanpham';

            String? image = imageCache[id];
            if (image == null || image.isEmpty) {
              final productDetail = await APIService.fetchProductDetail(
                APIService.baseUrl,
                'sanpham',
                id,
                    (_) => [],
              );
              image = productDetail != null && productDetail['hinhdaidien'] != null
                  ? '${APIService.baseUrl}${productDetail['hinhdaidien']}'
                  : 'https://via.placeholder.com/150';

              imageCache[id] = image;
              await prefs.setString('cart_images', json.encode(imageCache));
            }

            print('🛒 SP: $name | ID: $id | IDBG: $idbg | SL: $quantity | Image: $image');

            items.add(CartItemModel(
              id: id,
              idbg: idbg,
              name: name,
              price: price,
              moduleType: moduleType,
              image: image,
              quantity: quantity,
              isSelect: false,
              categoryId: 0,
            ));
          }

          if (cartitemCount != null) {
            cartitemCount.value = items.length;
          }

          return items;
        } else {
          print('❌ API trả về dữ liệu không hợp lệ');
          if (cartitemCount != null) {
            cartitemCount.value = 0;
          }
          return [];
        }
      } else {
        print('❌ Lỗi máy chủ: ${response.statusCode}');
        showToast('Lỗi máy chủ: ${response.statusCode}', backgroundColor: Colors.red);
        if (cartitemCount != null) {
          cartitemCount.value = 0;
        }
        return [];
      }
    } catch (e) {
      print('❌ Lỗi kết nối hoặc parse JSON: $e');
      showToast('Lỗi xử lý dữ liệu giỏ hàng', backgroundColor: Colors.red);
      if (cartitemCount != null) {
        cartitemCount.value = 0;
      }
      return [];
    }
  }

  static Future<bool> removeCartItem({
    required BuildContext context,
    required String emailAddress,
    required String productId,
    required ValueNotifier<int> cartitemCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = await AuthService.isLoggedIn();

    if (!isLoggedIn) {
      // Handle unauthenticated user
      final cartItemsJson = prefs.getString('local_cart_items') ?? '[]';
      List<dynamic> cartItems = json.decode(cartItemsJson);
      cartItems.removeWhere((item) => item['productId'].toString() == productId);
      await prefs.setString('local_cart_items', json.encode(cartItems));
      cartitemCount.value = cartItems.length;
      CustomSnackBar.showSuccess(context, message: 'Đã xóa sản phẩm khỏi giỏ hàng');
      return true;
    }

    try {
      final cartItems = await fetchCartItemsById(
        emailAddress: emailAddress,
        cartitemCount: cartitemCount,
        password: await AuthService.getPassword(),
      );

      final cartItem = cartItems.firstWhere(
            (item) => item.id == productId,
        orElse: () => CartItemModel(
          id: '',
          idbg: '',
          name: '',
          price: 0,
          moduleType: '',
          image: '',
          quantity: 0,
          isSelect: false,
          categoryId: 0,
        ),
      );

      if (cartItem.idbg.isEmpty) {
        print('Không tìm thấy idbg cho sản phẩm: $productId');
        showToast('Không tìm thấy sản phẩm trong giỏ hàng', backgroundColor: Colors.red);
        return false;
      }

      final password = await AuthService.getPassword();
      final md5Password = AuthService.generateMd5(password);
      print('Password used: $password, MD5: $md5Password');

      final queryParameters = {
        'userid': emailAddress,
        'pass': md5Password,
        'id': productId,
      };

      final uri = Uri.parse('${APIService.baseUrl}/ww1/remove.listcart.asp').replace(
        queryParameters: queryParameters,
      );

      final cookies = await AuthService.cookieJar.loadForRequest(uri);
      final headers = {
        'Accept': 'application/json',
        'Cookie': 'DathangMabaogia=${cartItem.idbg}; ${cookies.map((c) => '${c.name}=${c.value}').join('; ')}',
      };

      print('Remove cart item URL: $uri');
      print('Headers: $headers');

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 5));

      print('Remove cart item response status: ${response.statusCode}');
      print('Remove cart item response body: ${response.body}');

      // Không lưu cookie DathangMabaogia từ phản hồi để giữ cookie ban đầu
      if (response.headers.containsKey('set-cookie')) {
        final cookie = Cookie.fromSetCookieValue(response.headers['set-cookie']!.split(';')[0]);
        if (cookie.name != 'DathangMabaogia') {
          await AuthService.cookieJar.saveFromResponse(uri, [cookie]);
        }
      }

      if (response.statusCode == 200) {
        try {
          final jsonResponse = json.decode(response.body);
          if (jsonResponse is List && jsonResponse.isNotEmpty && jsonResponse[0] is Map && jsonResponse[0].containsKey('ThongBao')) {
            final thongbao = jsonResponse[0]['ThongBao']?.toString() ?? '';
            final maloi = jsonResponse[0]['maloi']?.toString() ?? '0';
            if (maloi == '1' || thongbao.contains('xóa khỏi danh mục cart')) {
              cartitemCount.value = (cartitemCount.value > 0) ? cartitemCount.value - 1 : 0;
              print('Xóa sản phẩm thành công: $productId');
              CustomSnackBar.showSuccess(context, message: 'Đã xóa sản phẩm khỏi giỏ hàng');
              return true;
            } else {
              print('API trả về thông báo không mong đợi: $thongbao');
              showToast(thongbao.isNotEmpty ? thongbao : 'Xóa sản phẩm thất bại', backgroundColor: Colors.red);
              return false;
            }
          } else {
            print('Dữ liệu phản hồi không hợp lệ: ${response.body}');
            showToast('Dữ liệu phản hồi không hợp lệ', backgroundColor: Colors.red);
            return false;
          }
        } catch (e) {
          print('Lỗi phân tích JSON: $e');
          showToast('Lỗi xử lý dữ liệu', backgroundColor: Colors.red);
          return false;
        }
      } else {
        print('Lỗi HTTP: ${response.statusCode}');
        showToast('Lỗi máy chủ: ${response.statusCode}', backgroundColor: Colors.red);
        return false;
      }
    } catch (e) {
      print('Lỗi kết nối khi xóa sản phẩm: $e');
      showToast('Lỗi kết nối khi xóa sản phẩm', backgroundColor: Colors.red);
      return false;
    }
  }

  

  static Future<void> datHang({
    required String moduletype,
    required String customerName,
    required String email,
    required String tel,
    required String address,
    required double totalPrice,
    required List<CartItemModel> items,
    String? password,
  }) async {
    try {
      final idParts = items.map((item) => item.id.toString()).join(',');
      final quantities = items.map((item) => item.quantity.toString()).join(',');

      final queryParameters = {
        'CustomerName': customerName,
        'Address': address,
        'EmailAddress': email,
        'Tel': tel,
        'maxacnhan': '5169',
        'IDPart': idParts,
        'sl': quantities,
      };

      final uri = Uri.parse('${APIService.baseUrl}/cart/save.asp').replace(
        queryParameters: queryParameters,
      );

      print('Order URL: $uri');

      final cookies = await AuthService.cookieJar.loadForRequest(uri);
      final headers = {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Content-Type': 'application/x-www-form-urlencoded',
        if (cookies.isNotEmpty) 'Cookie': cookies.map((c) => '${c.name}=${c.value}').join('; '),
      };

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 5));

      print('Order response status: ${response.statusCode}');
      print('Order response body: ${response.body}');

      // Lưu cookie mới chỉ nếu không phải DathangMabaogia
      if (response.headers.containsKey('set-cookie')) {
        final cookie = Cookie.fromSetCookieValue(response.headers['set-cookie']!.split(';')[0]);
        if (cookie.name != 'DathangMabaogia') {
          await AuthService.cookieJar.saveFromResponse(uri, [cookie]);
        }
      }

      if (response.statusCode == 200) {
        if (response.body.contains('Cám ơn đã đặt hàng!')) {
          print('Đặt hàng thành công!');
          // Clear local cart after successful order
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('local_cart_items', '[]');
          return;
        } else {
          print('API trả về phản hồi không mong đợi: ${response.body}');
          throw Exception('Phản hồi API không chứa thông báo thành công');
        }
      } else {
        print('Lỗi máy chủ: ${response.statusCode}');
        throw Exception('Đặt hàng thất bại: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi đặt hàng: $e');
      throw Exception('Không thể kết nối máy chủ: $e');
    }
  }

  static Future<String?> cancelOrder({required String emailAddress, required String orderId}) async {
    final uri = Uri.parse('${APIService.baseUrl}/api/cancel.order.php');
    final prefs = await SharedPreferences.getInstance();

    final bodyData = {
      'IDBG': orderId,
      'email': emailAddress,
    };

    try {
      final cookies = await AuthService.cookieJar.loadForRequest(uri);
      final headers = {
        'Content-Type': 'application/json',
        if (cookies.isNotEmpty) 'Cookie': cookies.map((c) => '${c.name}=${c.value}').join('; '),
      };

      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(bodyData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          print('Hủy đơn thành công');
          return null;
        } else {
          print('API trả về lỗi: ${responseData['message']}');
          return responseData['message'] ?? 'Hủy đơn hàng thất bại';
        }
      } else {
        print('Lỗi máy chủ: ${response.statusCode}');
        return 'Lỗi hệ thống: ${response.statusCode}';
      }
    } catch (e) {
      print('Lỗi: $e');
      return 'Không thể kết nối máy chủ';
    }
  }

  static Future<int> getCartItemCountFromApi(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = await AuthService.isLoggedIn();

    if (!isLoggedIn || email.isEmpty) {
      final cartItemsJson = prefs.getString('local_cart_items') ?? '[]';
      final List<dynamic> cartItems = json.decode(cartItemsJson);
      return cartItems.length;
    }

    final md5Password = AuthService.generateMd5(prefs.getString('passWord') ?? '');
    final uri = Uri.parse(
      '${APIService.baseUrl}/ww1/member.1/Quanlydanhmucsanphamgiohang.asp?userid=$email&pass=$md5Password&pageid=all',
    );

    final cookies = await AuthService.cookieJar.loadForRequest(uri);
    final headers = {
      'Accept': 'application/json',
      if (cookies.isNotEmpty) 'Cookie': cookies.map((c) => '${c.name}=${c.value}').join('; '),
    };

    print('Get cart count URL: $uri');
    print('Headers: $headers');

    try {
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 5));

      print('Get cart count response status: ${response.statusCode}');
      print('Get cart count response body: ${response.body}');

      // Lưu cookie mới chỉ nếu không phải DathangMabaogia
      if (response.headers.containsKey('set-cookie')) {
        final cookie = Cookie.fromSetCookieValue(response.headers['set-cookie']!.split(';')[0]);
        if (cookie.name != 'DathangMabaogia') {
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
        print('Không thể lấy số lượng sản phẩm: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      print('Lỗi kết nối khi lấy số lượng: $e');
      return 0;
    }
  }
}