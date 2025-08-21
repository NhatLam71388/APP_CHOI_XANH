import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/product_model.dart';
import 'package:flutter_application_1/view/until/until.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class APIService {
  static const String baseUrl = 'https://demochung.125.atoz.vn';
  static const String loginUrl = '$baseUrl/ww1/userlogin.asp';

  static Future<List<String>> fetchProductImages(String productId) async {
    final uri = Uri.parse('$baseUrl/ww2/tinhnang.hinhanh.idpart.asp').replace(
      queryParameters: {'id': productId},
    );
    print('Fetching product images from: $uri');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List && decoded.isNotEmpty && decoded[0]['data'] != null) {
          final data = decoded[0]['data'] as List<dynamic>;
          return data.map((item) => item['hinhdaidien'] as String).toList();
        }
        print('No images found in response');
        return [];
      } else {
        print('Error fetching images: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('API error fetching images: $e');
      return [];
    }
  }

  static Future<String> _fetchCategoryTitle(int categoryId) async {
    final uri = Uri.parse('$baseUrl/ww2/app.menu.dautrang.asp');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          final category = decoded.firstWhere(
                (item) => item['idpart'] == categoryId.toString(),
            orElse: () => null,
          );
          return category != null && category['tieude'] != null
              ? category['tieude']
              : 'Danh mục sản phẩm';
        }
      }
      print('Lỗi khi gọi API menu: ${response.statusCode}');
      return 'Danh mục sản phẩm';
    } catch (e) {
      print('Lỗi kết nối API menu: $e');
      return 'Danh mục sản phẩm';
    }
  }

  static Future<Map<String, dynamic>> fetchProductsByCategory({
    required int categoryId,
    required String ww2,
    required String product,
    required String extention,
    required String idfilter,
  }) async {
    final id3 = idfilter.isEmpty ? '' : ',n$idfilter';
    final url = '$baseUrl/ww2/module.laytimkiem.banhang.asp?id=$categoryId&id2=&id3=${Uri.encodeQueryComponent(id3)}&pageid=1';

    print('Query params: {id: $categoryId, id2: , id3: $id3, pageid: 1}');
    print('Fetching products from: $url');

    try {
      final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 5));
      final String tieude = await _fetchCategoryTitle(categoryId);

      // print('response.statusCode: ${response.statusCode}');
      // print('response.body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is List && decoded.isNotEmpty && decoded[0] is Map) {
          final firstItem = decoded[0];
          if (firstItem.containsKey('data')) {
            return {
              'tieude': tieude,
              'idcatalog': categoryId.toString(),
              'data': firstItem['data'] ?? [],
            };
          } else {
            print('Phản hồi không chứa key "data"');
            return {
              'tieude': tieude,
              'idcatalog': categoryId.toString(),
              'data': [],
            };
          }
        } else {
          print('Phản hồi không hợp lệ');
          return {
            'tieude': tieude,
            'idcatalog': categoryId.toString(),
            'data': [],
          };
        }
      } else {
        print('Lỗi server: ${response.statusCode}');
        return {
          'tieude': tieude,
          'idcatalog': categoryId.toString(),
          'data': [],
        };
      }
    } catch (e) {
      print('Lỗi kết nối hoặc xử lý API: $e');
      final String tieude = await _fetchCategoryTitle(categoryId);
      return {
        'tieude': tieude,
        'idcatalog': categoryId.toString(),
        'data': [],
      };
    }
  }

  static Future<List<dynamic>> getProductRelated({
    required String id,
    required String modelType,
    int sl = 10,
    int pageId = 1,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/ww2/module.$modelType.chitiet.tinlienquan.asp',
      ).replace(
        queryParameters: {
          'id': id,
          'sl': sl.toString(),
          'pageid': pageId.toString(),
        },
      );

      print('API sản phẩm liên quan: $uri');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is List && decoded.isNotEmpty) {
          final relatedSection = decoded.firstWhere(
                (section) => section['tieude'] == 'SẢN PHẨM LIÊN QUAN',
            orElse: () => {'baiviet': []},
          );
          final relatedProducts = relatedSection['baiviet'] ?? [];
          return relatedProducts;
        } else {
          print('Phản hồi không phải List hoặc List rỗng.');
          return [];
        }
      } else {
        print('Lỗi server: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Lỗi khi gọi API sản phẩm liên quan: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> fetchComments({
    required String productId,
    required int page,
  }) async {
    final uri = Uri.parse('$baseUrl/ww2/binhluan.pc.asp?id=$productId&txtloai=desc&pageid=$page');
    try {
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
      }).timeout(Duration(seconds: 5));

      print('Fetch comments URL: $uri');
      print('Fetch comments response status: ${response.statusCode}');
      print('Fetch comments response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        
        // Xử lý cấu trúc JSON mới: [{"recordsTotal": 22, "recordsFiltered": 5, "data": [...]}]
        if (jsonResponse.isNotEmpty && jsonResponse[0] is Map) {
          final firstItem = jsonResponse[0] as Map<String, dynamic>;
          
          // Kiểm tra cấu trúc dữ liệu
          if (firstItem.containsKey('recordsTotal') && 
              firstItem.containsKey('recordsFiltered') && 
              firstItem.containsKey('data')) {
            
            // Đảm bảo data là một List
            if (firstItem['data'] is List) {
              print('✅ Dữ liệu bình luận hợp lệ: ${firstItem['recordsTotal']} tổng, ${firstItem['recordsFiltered']} hiển thị');
              return firstItem;
            } else {
              print('❌ Cấu trúc data không hợp lệ: ${firstItem['data']}');
              return {'recordsTotal': 0, 'recordsFiltered': 0, 'data': []};
            }
          } else {
            print('❌ Cấu trúc JSON không đúng định dạng mong đợi');
            return {'recordsTotal': 0, 'recordsFiltered': 0, 'data': []};
          }
        }
        
        print('❌ Dữ liệu bình luận không hợp lệ hoặc rỗng');
        return {'recordsTotal': 0, 'recordsFiltered': 0, 'data': []};
      } else {
        print('❌ Lỗi khi lấy bình luận: ${response.statusCode}');
        return {'recordsTotal': 0, 'recordsFiltered': 0, 'data': []};
      }
    } catch (e) {
      print('❌ Lỗi kết nối khi lấy bình luận: $e');
      return {'recordsTotal': 0, 'recordsFiltered': 0, 'data': []};
    }
  }

  static Future<bool> postComment({
    required String productId,
    required String userId,
    required String content,
    String rating = '100',
    String nguoidang = 'Khách',
  }) async {
    final uri = Uri.parse('$baseUrl/ww2/binhluan.pc.asp');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': productId,
          'noidungbinhluan': content,
          'nguoidang': userId.isNotEmpty ? userId : nguoidang,
          'rating': rating,
        }),
      ).timeout(Duration(seconds: 5));

      print('Post comment URL: $uri');
      print('Post comment request body: ${json.encode({
        'id': productId,
        'noidungbinhluan': content,
        'nguoidang': userId.isNotEmpty ? userId : nguoidang,
        'rating': rating,
      })}');
      print('Post comment response status: ${response.statusCode}');
      print('Post comment response body: ${response.body}');

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
      print('Lỗi kết nối khi gửi bình luận: $e');
      return false;
    }
  }

  static Future<List<dynamic>> loadComments(String id) async {
    final uri = Uri.parse('$baseUrl/ww2/module.tintuc.chitiet.lienquan.asp').replace(
      queryParameters: {
        'id': id,
        'sl': '30',
        'pageid': '1',
      },
    );

    print('Link related articles: $uri');
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is List && decoded.isNotEmpty && decoded[0]['data'] is List) {
          final dataList = decoded[0]['data'] as List<dynamic>;
          print('Số bài liên quan nhận được: ${dataList.length}');
          return dataList;
        }
        print('Không có dữ liệu bài liên quan');
        return [];
      } else {
        print('Lỗi server khi tải bài liên quan: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Lỗi khi gọi API loadComments: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> searchSanPham(String keyword) async {
    final uri = Uri.parse('$baseUrl/ww2/module.laytimkiem.banhang.asp').replace(
      queryParameters: {
        'id': '',
        'id2': keyword,
        'id3': '',
        'pageid': '1',
      },
    );
    print('Search API: $uri');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List && decoded.isNotEmpty && decoded[0]['data'] != null) {
          final data = decoded[0]['data'] as List<dynamic>;
          return data.map<Map<String, dynamic>>((item) {
            return {
              'id': item['id'].toString(),
              'name': item['tieude'] ?? '',
              'price': double.tryParse(item['gia']?.toString() ?? '0') ?? 0,
              'kieuhienthi': item['module'] == 'Tintuc' ? 'tintuc' : 'sanpham',
              'image': item['hinhdaidien'] ?? '',
              'quantity': 1,
              'isSelect': false,
              'categoryId': int.tryParse(item['categoryId']?.toString() ?? '0') ?? 35001,
            };
          }).toList();
        }
        print('No search results found');
        return [];
      } else {
        print('Error fetching search results: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('API error fetching search results: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getBoLocByCatalog(String idCatalog) async {
    final uri = Uri.parse('$baseUrl/ww2/crm.boloc.master.asp').replace(
      queryParameters: {'id': idCatalog},
    );
    print('Filter API: $uri');
    try {
      final response = await http.get(uri);
      print('Filter API response status: ${response.statusCode}');
      print('Filter API response body: ${response.body}');
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print('Filter API decoded: $decoded');
        if (decoded is List) {
          final filters = await Future.wait(decoded.map((item) async {
            final filterId = item['id']?.toString() ?? '';
            print('Fetching children for filter ID: $filterId');
            final children = await fetchBoLocChiTiet(filterId);
            print('Children for filter ID $filterId: $children');
            return {
              'name': item['tieude'] ?? 'Bộ lọc',
              'children': children,
            };
          }).toList());
          print('Processed filters: $filters');
          return {
            'status': 'success',
            'data': {
              'filters': filters,
            },
          };
        }
        print('Phản hồi không phải danh sách bộ lọc');
        return {
          'status': 'error',
          'message': 'Invalid response format: not a list',
        };
      } else {
        print('⚠️ Lỗi khi gọi API lọc: ${response.statusCode}');
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Lỗi kết nối API lọc: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
      };
    }
  }

  static Future<List<dynamic>> fetchBoLocChiTiet(String id) async {
    final url = Uri.parse('$baseUrl/ww2/crm.boloc.chitiet.asp').replace(
      queryParameters: {'id': id},
    );
    print('Filter detail API: $url');
    try {
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0',
      });
      print('Filter detail API response status: ${response.statusCode}');
      print('Filter API response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Filter detail API decoded: $data');
        if (data is List && data.isNotEmpty && data[0]['thamso'] is List) {
          final thamso = data[0]['thamso'] as List<dynamic>;
          return thamso.map((child) {
            return {
              'idfilter': child['ma']?.toString() ?? '',
              'name': child['tengoi'] ?? 'Chi tiết',
            };
          }).toList();
        }
        print('Không có thamso hoặc dữ liệu không hợp lệ');
        return [];
      } else {
        print('Lỗi khi lấy bộ lọc chi tiết: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Lỗi kết nối API bộ lọc chi tiết: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> fetchProductDetail(
      String baseUrl,
      String danhmuc,
      String productId,
      Function(List<String>) getDanhSachHinh) async {
    final String url =
        '$baseUrl/ww2/module.$danhmuc.chitiet.asp?id=$productId';
    print('Fetching product details from: $url');
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        String responseBody = response.body;
        responseBody = responseBody.replaceAll(RegExp(r',\s*,\s*'), ',');
        responseBody =
            responseBody.replaceAll(RegExp(r',\s*(?=\s*[\}\]])'), '');
        responseBody = responseBody.replaceAll(RegExp(r',\s*$'), '');
        final data = json.decode(responseBody);
        if (data is List && data.isNotEmpty) {
          final detail = data.first;
          return detail;
        } else {
          print('No data or data is not a list');
          return null;
        }
      } else {
        throw Exception('Error loading product details: ${response.statusCode}');
      }
    } catch (e) {
      print('API error: $e');
      return null;
    }
  }

  static Future<String?> fetchHtmlContent(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        return "<p>Không thể tải nội dung chi tiết.</p>";
      }
    } catch (e) {
      return "<p>Lỗi tải nội dung: $e</p>";
    }
  }
}