import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:http/http.dart' as http;

import '../view/until/until.dart';

class APICartService {
  static const String baseUrl = 'https://demochung.125.atoz.vn';

  // Hàm lấy cookie từ API
  static Future<Map<String, String>> fetchCookies() async {
    final uri = Uri.parse('$baseUrl/ww1/cookie.mabaogia.asp');
    try {
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
      }).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        Map<String, String> cookies = {};
        for (var item in jsonResponse) {
          if (item is Map) {
            item.forEach((key, value) {
              cookies[key] = value.toString();
            });
          }
        }
        print('Cookies fetched: $cookies');
        return cookies;
      } else {
        print('❌ Lỗi khi lấy cookie: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('❌ Lỗi kết nối khi lấy cookie: $e');
      return {};
    }
  }

  static Future<String?> addToCart({
    required String moduleType,
    required String? emailAddress,
    required String? password,
    required int productId,
    required ValueNotifier<int> cartitemCount,
    required int quantity,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = await AuthService.isLoggedIn();

    try {
      print('emailaddress: $emailAddress');

      if (isLoggedIn && emailAddress != null && password != null) {
        final md5Password = AuthService.generateMd5(password);
        final uri = Uri.parse(
          '$baseUrl/ww1/save.addwishlist.asp?userid=$emailAddress&pass=$md5Password&id=$productId',
        );

        print('Add to cart URL (logged in): $uri');
        final response = await http.get(uri, headers: {
          'Accept': 'application/json',
        }).timeout(Duration(seconds: 5));

        print('Add to cart response status: ${response.statusCode}');
        print('Add to cart response body: ${response.body}');

        if (response.statusCode == 200) {
          final List<dynamic> jsonResponse = json.decode(response.body);
          if (jsonResponse.isNotEmpty && jsonResponse[0] is Map && jsonResponse[0].containsKey('ThongBao')) {
            final responseData = jsonResponse[0];
            final thongbao = responseData['ThongBao']?.toString() ?? '';
            final maloi = responseData['maloi']?.toString() ?? '0';
            final cleanMessage = thongbao.replaceAll(RegExp(r'<[^>]+>'), '').trim();

            if (maloi == '1' && thongbao.contains('Đưa công việc vào danh sách chờ nộp đơn')) {
              // Cập nhật số lượng giỏ hàng
              final cartItems = await fetchCartItemsById(emailAddress: emailAddress, cartitemCount: cartitemCount);
              cartitemCount.value = cartItems.length;
              showToast(cleanMessage.isNotEmpty ? cleanMessage : 'Đã thêm vào giỏ hàng');
              return null;
            } else {
              return cleanMessage.isNotEmpty ? cleanMessage : 'Thao tác thất bại';
            }
          } else {
            return 'Dữ liệu phản hồi không hợp lệ';
          }
        } else {
          return 'Lỗi máy chủ: ${response.statusCode}';
        }
      } else {
        String? cartCookie = prefs.getString('cartCookie') ?? '';
        if (cartCookie.isEmpty) {
          final cookies = await fetchCookies();
          cartCookie = cookies['DathangMabaogia'];
          if (cartCookie == null) {
            return 'Không thể lấy cookie giỏ hàng';
          }
          await prefs.setString('cartCookie', cartCookie);
        }

        final uri = Uri.parse(
          '$baseUrl/ww1/addgiohang.asp?IDPart=$productId&id=$cartCookie&sl=$quantity',
        );

        print('Add to cart URL (not logged in): $uri');
        final response = await http.get(uri, headers: {
          'Accept': 'application/json',
          'Cookie': 'DathangMabaogia=$cartCookie',
        }).timeout(Duration(seconds: 5));

        print('Add to cart response status: ${response.statusCode}');
        print('Add to cart response body: ${response.body}');

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData is Map && responseData.containsKey('thongbao')) {
            final thongbao = responseData['thongbao']?.toString() ?? '';
            final cleanMessage = thongbao.replaceAll(RegExp(r'<[^>]+>'), '').trim();

            if (thongbao.contains('Đã đưa') && thongbao.contains('vào giỏ hàng')) {
              if (responseData.containsKey('sl')) {
                cartitemCount.value = responseData['sl'] as int;
              }
              showToast(cleanMessage.isNotEmpty ? cleanMessage : 'Đã thêm vào giỏ hàng');
              return null;
            } else {
              return cleanMessage.isNotEmpty ? cleanMessage : 'Thao tác thất bại';
            }
          } else {
            return 'Dữ liệu phản hồi không hợp lệ';
          }
        } else {
          return 'Lỗi máy chủ: ${response.statusCode}';
        }
      }
    } catch (e) {
      print('Exception: $e');
      return 'Lỗi xử lý dữ liệu từ máy chủ';
    }
  }

  static Future<List<CartItemModel>> fetchCartItemsById({
    required String? emailAddress,
    ValueNotifier<int>? cartitemCount,
    String? password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = await AuthService.isLoggedIn();

      if (isLoggedIn && emailAddress != null && password != null) {
        // Trường hợp đã đăng nhập
        final md5Password = AuthService.generateMd5(password);
        final uri = Uri.parse(
          '$baseUrl/ww1/member.1/Quanlydanhmucsanphamgiohang.asp?userid=$emailAddress&pass=$md5Password&pageid=all',
        );

        print('Fetch cart items URL (logged in): $uri');
        final response = await http.get(uri, headers: {
          'Accept': 'application/json',
        }).timeout(Duration(seconds: 5));

        print('Fetch cart items response status: ${response.statusCode}');
        print('Fetch cart items response body: ${response.body}');

        if (response.statusCode == 200) {
          // Làm sạch JSON trước khi parse
          String cleanedResponse = response.body;
          // Escape tất cả dấu nháy kép trong chuỗi tieude, ngoại trừ các dấu nháy kép hợp lệ của JSON
          cleanedResponse = cleanedResponse.replaceAllMapped(
            RegExp(r'(?<=tieude":\s*")[^"]*?(")(?=[^"]*?",)'),
                (match) => match.group(0)!.replaceAll('"', '\\"'),
          );

          print('Cleaned JSON response: $cleanedResponse');

          final List<dynamic> jsonResponse;
          try {
            jsonResponse = json.decode(cleanedResponse);
          } catch (e) {
            print('❌ Lỗi phân tích JSON sau khi làm sạch: $e');
            showToast('Lỗi dữ liệu giỏ hàng, vui lòng thử lại', backgroundColor: Colors.red);
            if (cartitemCount != null) {
              cartitemCount.value = 0;
            }
            return [];
          }

          if (jsonResponse.isNotEmpty && jsonResponse[0] is Map && jsonResponse[0].containsKey('data')) {
            final List<dynamic> data = jsonResponse[0]['data'];

            // Lưu trữ hinhdaidien vào SharedPreferences
            final cachedImages = prefs.getString('cart_images') ?? '{}';
            final imageCache = json.decode(cachedImages) as Map<String, dynamic>;

            List<CartItemModel> items = [];
            for (var item in data) {
              final id = item['id']?.toString() ?? '';
              final name = item['tieude']?.toString() ?? '';
              final price = double.tryParse(item['gia']?.toString() ?? '0') ?? 0;
              final quantity = int.tryParse(item['soluong']?.toString() ?? '1') ?? 1;
              final moduleType = 'sanpham';

              String? image = imageCache[id];
              // Nếu không có ảnh trong cache, gọi API chi tiết sản phẩm
              if (image == null || image.isEmpty) {
                final productDetail = await APIService.fetchProductDetail(
                  baseUrl,
                  'sanpham',
                  id,
                      (_) => [], // Truyền hàm rỗng vì không cần danh sách hình
                );
                image = productDetail != null && productDetail['hinhdaidien'] != null
                    ? '$baseUrl${productDetail['hinhdaidien']}'
                    : 'https://via.placeholder.com/150';

                // Lưu ảnh vào cache
                imageCache[id] = image;
                await prefs.setString('cart_images', json.encode(imageCache));
              }

              print('🛒 SP: $name | ID: $id | SL: $quantity | Image: $image');

              items.add(CartItemModel(
                id: id,
                name: name,
                price: price,
                moduleType: moduleType,
                image: image,
                quantity: quantity,
                categoryId: 0,
              ));
            }

            if (cartitemCount != null) {
              cartitemCount.value = items.length;
            }

            return items;
          } else {
            print('❌ API trả về dữ liệu không hợp lệ (logged in)');
            showToast('Dữ liệu giỏ hàng không hợp lệ', backgroundColor: Colors.red);
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
      } else {
        // Trường hợp chưa đăng nhập
        String? cartCookie = prefs.getString('cartCookie') ?? '';
        if (cartCookie.isEmpty) {
          final cookies = await fetchCookies();
          cartCookie = cookies['DathangMabaogia'];
          if (cartCookie == null) {
            print('❌ Không thể lấy cookie giỏ hàng');
            showToast('Không thể lấy cookie giỏ hàng', backgroundColor: Colors.red);
            if (cartitemCount != null) {
              cartitemCount.value = 0;
            }
            return [];
          }
          await prefs.setString('cartCookie', cartCookie);
        }

        final uri = Uri.parse('$baseUrl/ww1/giohanghientai.asp');
        print('Fetch cart items URL (not logged in): $uri');
        print('Cart cookie: $cartCookie');

        final response = await http.get(uri, headers: {
          'Accept': 'application/json',
          'Cookie': 'DathangMabaogia=$cartCookie',
        }).timeout(Duration(seconds: 5));

        print('Fetch cart items response status: ${response.statusCode}');
        print('Fetch cart items response body: ${response.body}');

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);

          if (jsonResponse is Map && jsonResponse.containsKey('items') && jsonResponse['items'] is List) {
            final List<dynamic> data = jsonResponse['items'];

            List<CartItemModel> items = data.map((item) {
              final id = item['id']?.toString() ?? '';
              final name = item['partName']?.toString() ?? '';
              final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
              final moduleType = 'sanpham';
              final image = item['image'] != null
                  ? '$baseUrl${item['image']}'
                  : 'https://via.placeholder.com/150';
              final quantity = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;

              print('🛒 SP: $name | ID: $id | SL: $quantity | Image: $image');

              return CartItemModel(
                id: id,
                name: name,
                price: price,
                moduleType: moduleType,
                image: image,
                quantity: quantity,
                categoryId: 0,
              );
            }).toList();

            if (cartitemCount != null) {
              cartitemCount.value = items.length;
            }

            return items;
          } else {
            print('❌ API trả về dữ liệu không hợp lệ');
            showToast('Dữ liệu giỏ hàng không hợp lệ', backgroundColor: Colors.red);
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

  static Future<bool> updateCartItemQuantity({
    required String emailAddress,
    required int productId,
    required int newQuantity,
  }) async {
    final uri = Uri.parse(
      '${APIService.baseUrl}/api/update.quantity.php',
    );

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ProductID': productId,
          'EmailAddress': emailAddress,
          'Quantity': newQuantity,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return true;
        } else {
          print('API trả về lỗi: ${jsonResponse['message']}');
          return false;
        }
      } else {
        print('Lỗi HTTP: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Lỗi kết nối khi cập nhật số lượng: $e');
      return false;
    }
  }

  static Future<bool> removeCartItem({
    required String emailAddress,
    required String productId,
    required ValueNotifier<int> cartitemCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = await AuthService.isLoggedIn();

    try {
      final queryParameters = {
        'choixanh': 'xoasanpham',
        'idpart': productId,
      };

      final uri = Uri.parse('$baseUrl/cart/xoa.asp').replace(
        queryParameters: queryParameters,
      );

      print('Remove cart item URL: $uri');

      final headers = {
        'Accept': 'application/json',
      };

      // Thêm cookie nếu chưa đăng nhập
      if (!isLoggedIn) {
        String? cartCookie = prefs.getString('cartCookie') ?? '';
        if (cartCookie.isEmpty) {
          final cookies = await fetchCookies();
          cartCookie = cookies['DathangMabaogia'];
          if (cartCookie == null) {
            print('❌ Không thể lấy cookie giỏ hàng');
            return false;
          }
          await prefs.setString('cartCookie', cartCookie);
        }
        headers['Cookie'] = 'DathangMabaogia=$cartCookie';
      }

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(Duration(seconds: 5));

      print('Remove cart item response status: ${response.statusCode}');
      print('Remove cart item response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          // Loại bỏ tiền tố "var info = " và sửa JSON không chuẩn
          String cleanedResponse = response.body.replaceFirst('var info = ', '');
          // Thêm dấu nháy kép quanh tên thuộc tính
          cleanedResponse = cleanedResponse.replaceAllMapped(
              RegExp(r'(\w+):'), (match) => '"${match[1]}":');
          // Thay dấu nháy đơn thành dấu nháy kép cho giá trị chuỗi
          cleanedResponse = cleanedResponse.replaceAll("'", '"');
          // Loại bỏ dấu ; ở cuối nếu có
          cleanedResponse = cleanedResponse.replaceAll(';', '');
          print('Cleaned response: $cleanedResponse');

          final jsonResponse = json.decode(cleanedResponse);
          if (jsonResponse is Map && jsonResponse.containsKey('thongbao')) {
            final thongbao = jsonResponse['thongbao']?.toString() ?? '';
            if (thongbao.contains('Đã xóa')) {
              cartitemCount.value = (cartitemCount.value > 0) ? cartitemCount.value - 1 : 0;
              print('Xóa sản phẩm thành công: $productId');
              return true;
            } else {
              print('API trả về thông báo không mong đợi: $thongbao');
              return false;
            }
          } else {
            print('Dữ liệu phản hồi không hợp lệ: $cleanedResponse');
            return false;
          }
        } catch (e) {
          print('Lỗi phân tích JSON: $e');
          return false;
        }
      } else {
        print('Lỗi HTTP: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Lỗi kết nối khi xóa sản phẩm: $e');
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
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = await AuthService.isLoggedIn();

      // Tạo danh sách ID sản phẩm và số lượng
      final idParts = items.map((item) => item.id.toString()).join(',');
      final quantities = items.map((item) => item.quantity.toString()).join(',');

      // Tạo URL với các tham số query
      final queryParameters = {
        'CustomerName': customerName,
        'Address': address,
        'EmailAddress': email,
        'Tel': tel,
        'maxacnhan': '5169',
        'IDPart': idParts,
        'sl': quantities,
      };

      final uri = Uri.parse('$baseUrl/cart/save.asp').replace(
        queryParameters: queryParameters,
      );

      print('Order URL: $uri');

      final headers = {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      // Thêm cookie nếu chưa đăng nhập
      if (!isLoggedIn) {
        String? cartCookie = prefs.getString('cartCookie') ?? '';
        if (cartCookie.isEmpty) {
          final cookies = await fetchCookies();
          cartCookie = cookies['DathangMabaogia'];
          if (cartCookie == null) {
            throw Exception('Không thể lấy cookie giỏ hàng');
          }
          await prefs.setString('cartCookie', cartCookie);
        }
        headers['Cookie'] = 'DathangMabaogia=$cartCookie';
      }

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(Duration(seconds: 5));

      print('Order response status: ${response.statusCode}');
      print('Order response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.contains('Cám ơn đã đặt hàng!')) {
          print('Đặt hàng thành công!');
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
    final uri = Uri.parse('$baseUrl/api/cancel.order.php');
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('emailAddress') ?? '';

    final bodyData = {
      'IDBG': orderId,
      'email': emailAddress,
    };

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
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

    if (isLoggedIn && email.isNotEmpty) {
      final md5Password = AuthService.generateMd5(prefs.getString('password') ?? '');
      final uri = Uri.parse(
        '$baseUrl/ww1/member.1/Quanlydanhmucsanphamgiohang.asp?userid=$email&pass=$md5Password&pageid=all',
      );

      print('Get cart count URL (logged in): $uri');

      try {
        final response = await http.get(
          uri,
          headers: {'Accept': 'application/json'},
        ).timeout(Duration(seconds: 5));

        print('Get cart count response status: ${response.statusCode}');
        print('Get cart count response body: ${response.body}');

        if (response.statusCode == 200) {
          // Làm sạch JSON trước khi parse
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
            print('❌ Lỗi phân tích JSON sau khi làm sạch: $e');
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
    } else {
      String? cartCookie = prefs.getString('cartCookie') ?? '';
      if (cartCookie.isEmpty) {
        final cookies = await fetchCookies();
        cartCookie = cookies['DathangMabaogia'];
        if (cartCookie == null) {
          print('❌ Không thể lấy cookie giỏ hàng');
          return 0;
        }
        await prefs.setString('cartCookie', cartCookie);
      }

      final uri = Uri.parse('$baseUrl/ww1/giohanghientai.asp');
      try {
        final response = await http.get(
          uri,
          headers: {
            'Accept': 'application/json',
            'Cookie': 'DathangMabaogia=$cartCookie',
          },
        ).timeout(Duration(seconds: 5));

        print('Get cart count URL (not logged in): $uri');
        print('Cart cookie: $cartCookie');
        print('Get cart count response status: ${response.statusCode}');
        print('Get cart count response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data is Map && data.containsKey('items') && data['items'] is List) {
            return data['items'].length;
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
}