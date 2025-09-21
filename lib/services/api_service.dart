import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/product_model.dart';
import 'package:flutter_application_1/widgets/until.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class APIService {
  // static const String baseUrl = 'https://nhipcautamgiao.net';
  // static const String baseUrl = 'https://choixanh.net';
  static const String baseUrl = 'https://demodienmay.125.atoz.vn';
  static const String loginUrl = '$baseUrl/ww1/userlogin.asp';

  /// Làm sạch JSON response để xử lý các lỗi cú pháp từ server
  static String cleanJsonResponse(String jsonString) {
    String cleaned = jsonString;
    
    // Xử lý trường hợp đặc biệt: "baiviet": \n\t\t"kieu": "ht1103",\n\t\t[
    // Cần chuyển thành: "baiviet": [\n\t\t"kieu": "ht1103"
    cleaned = cleaned.replaceAll(RegExp(r'"baiviet":\s*\n\s*"kieu":\s*"ht1103",\s*\n\s*\['), '"baiviet": [\n\t\t"kieu": "ht1103"');
    
    // Xử lý trường hợp: "baiviet": \n\t\t"kieu": "ht1103"\n\t\t[
    cleaned = cleaned.replaceAll(RegExp(r'"baiviet":\s*\n\s*"kieu":\s*"ht1103"\s*\n\s*\['), '"baiviet": [\n\t\t"kieu": "ht1103"');
    
    // Xử lý trường hợp: "baiviet": \n\t\t"kieu": "ht1103",
    cleaned = cleaned.replaceAll(RegExp(r'"baiviet":\s*\n\s*"kieu":\s*"ht1103",'), '"baiviet": [],\n\t\t"kieu": "ht1103"');
    
    // Xử lý trường hợp: "baiviet": \n\t\t"kieu": "ht1103"
    cleaned = cleaned.replaceAll(RegExp(r'"baiviet":\s*\n\s*"kieu":\s*"ht1103"(?!\s*[,\[])'), '"baiviet": [],\n\t\t"kieu": "ht1103"');
    
    // Sửa lỗi dấu phẩy thừa
    cleaned = cleaned.replaceAll(RegExp(r',\s*\n\s*\['), '\n\t\t[');
    
    // Sửa lỗi dấu phẩy cuối object trước array
    cleaned = cleaned.replaceAll(RegExp(r'}\s*\n\s*\['), '},\n\t\t[');
    
    // Sửa lỗi dấu phẩy thừa ở cuối
    cleaned = cleaned.replaceAll(RegExp(r',\s*$'), '');
    cleaned = cleaned.replaceAll(RegExp(r',\s*\}'), '}');
    cleaned = cleaned.replaceAll(RegExp(r',\s*\]'), ']');
    
    // Sửa lỗi dấu phẩy liên tiếp
    cleaned = cleaned.replaceAll(RegExp(r',\s*,\s*'), ',');
    
    return cleaned;
  }

  /// Sửa lỗi JSON thủ công cho các trường hợp phức tạp
  static String _manualJsonFix(String jsonString) {
    String fixed = jsonString;
    
    print('Original JSON for manual fix: $fixed');
    
    // Xử lý trường hợp đặc biệt: "baiviet": \n\t\t"kieu": "ht1103",\n\t\t[
    // Cần chuyển thành: "baiviet": [\n\t\t"kieu": "ht1103"
    fixed = fixed.replaceAll(RegExp(r'"baiviet":\s*\n\s*"kieu":\s*"ht1103",\s*\n\s*\['), '"baiviet": [\n\t\t"kieu": "ht1103"');
    
    // Xử lý trường hợp: "baiviet": \n\t\t"kieu": "ht1103"\n\t\t[
    fixed = fixed.replaceAll(RegExp(r'"baiviet":\s*\n\s*"kieu":\s*"ht1103"\s*\n\s*\['), '"baiviet": [\n\t\t"kieu": "ht1103"');
    
    // Xử lý trường hợp: "baiviet": \n\t\t"kieu": "ht1103",
    fixed = fixed.replaceAll(RegExp(r'"baiviet":\s*\n\s*"kieu":\s*"ht1103",'), '"baiviet": [],\n\t\t"kieu": "ht1103"');
    
    // Xử lý trường hợp: "baiviet": \n\t\t"kieu": "ht1103"
    fixed = fixed.replaceAll(RegExp(r'"baiviet":\s*\n\s*"kieu":\s*"ht1103"(?!\s*[,\[])'), '"baiviet": [],\n\t\t"kieu": "ht1103"');
    
    // Xử lý trường hợp đặc biệt: "kieu": "ht1103"\n\t\t[
    fixed = fixed.replaceAll(RegExp(r'"kieu":\s*"ht1103"\s*\n\s*\['), '"kieu": "ht1103"');
    
    // Xử lý trường hợp: "kieu": "ht1103",\n\t\t[
    fixed = fixed.replaceAll(RegExp(r'"kieu":\s*"ht1103",\s*\n\s*\['), '"kieu": "ht1103"');
    
    // Xử lý trường hợp: "kieu": "ht1103"\n\t\t{
    fixed = fixed.replaceAll(RegExp(r'"kieu":\s*"ht1103"\s*\n\s*\{'), '"kieu": "ht1103"');
    
    // Xử lý trường hợp: "kieu": "ht1103",\n\t\t{
    fixed = fixed.replaceAll(RegExp(r'"kieu":\s*"ht1103",\s*\n\s*\{'), '"kieu": "ht1103"');
    
    print('Manually fixed JSON: $fixed');
    
    return fixed;
  }

  /// Xử lý trường hợp JSON đặc biệt với "baiviet" và "kieu"
  static String _fixSpecialJsonCase(String jsonString) {
    try {
      print('Fixing special JSON case: $jsonString');
      
      // Tìm vị trí của "baiviet" và "kieu"
      final baivietIndex = jsonString.indexOf('"baiviet":');
      final kieuIndex = jsonString.indexOf('"kieu": "ht1103"');
      
      if (baivietIndex == -1 || kieuIndex == -1) {
        return jsonString;
      }
      
      // Tách JSON thành 3 phần: trước baiviet, giữa baiviet và kieu, sau kieu
      final beforeBaiviet = jsonString.substring(0, baivietIndex);
      final afterKieu = jsonString.substring(kieuIndex + '"kieu": "ht1103"'.length);
      
      // Tìm vị trí bắt đầu của array articles
      final arrayStartIndex = jsonString.indexOf('[', kieuIndex);
      if (arrayStartIndex == -1) {
        return jsonString;
      }
      
      // Lấy phần articles (từ [ đến hết)
      final articlesPart = jsonString.substring(arrayStartIndex);
      
      // Xây dựng lại JSON
      final fixedJson = '$beforeBaiviet"baiviet": $articlesPart';
      
      print('Fixed special case JSON: $fixedJson');
      return fixedJson;
      
    } catch (e) {
      print('Error fixing special JSON case: $e');
      return jsonString;
    }
  }

  /// Xây dựng lại JSON hoàn toàn từ dữ liệu bị lỗi
  static String _reconstructJson(String jsonString) {
    try {
      print('Reconstructing JSON from: $jsonString');
      
      // Tách thành các dòng và xử lý
      final lines = jsonString.split('\n');
      final List<Map<String, dynamic>> articles = [];
      Map<String, dynamic>? headerObject;
      
      bool inArticle = false;
      Map<String, dynamic>? currentArticle;
      
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i].trim();
        
        // Bỏ qua dòng rỗng
        if (line.isEmpty) continue;
        
        // Bắt đầu object mới
        if (line.startsWith('{')) {
          if (headerObject == null) {
            headerObject = {};
            inArticle = false;
          } else {
            currentArticle = {};
            inArticle = true;
          }
        }
        // Kết thúc object
        else if (line.startsWith('}')) {
          if (inArticle && currentArticle != null) {
            articles.add(currentArticle);
            currentArticle = null;
            inArticle = false;
          }
        }
        // Xử lý key-value pairs
        else if (line.contains(':')) {
          final colonIndex = line.indexOf(':');
          final key = line.substring(0, colonIndex).trim().replaceAll('"', '');
          final value = line.substring(colonIndex + 1).trim().replaceAll('"', '').replaceAll(',', '');
          
          if (inArticle && currentArticle != null) {
            currentArticle[key] = value;
          } else if (headerObject != null) {
            headerObject[key] = value;
          }
        }
        // Xử lý array bắt đầu
        else if (line.startsWith('[')) {
          // Bỏ qua dòng này, array sẽ được xử lý bởi các object bên trong
        }
      }
      
      // Xây dựng kết quả cuối cùng
      final result = <Map<String, dynamic>>[];
      
      if (headerObject != null) {
        headerObject['baiviet'] = articles;
        result.add(headerObject);
      }
      
      final reconstructedJson = json.encode(result);
      print('Successfully reconstructed JSON: $reconstructedJson');
      return reconstructedJson;
      
    } catch (e) {
      print('Error reconstructing JSON: $e');
      // Fallback: trả về JSON rỗng
      return '[]';
    }
  }

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


  static Future<List<Map<String, dynamic>>> fetchHomeModules() async {
    final uri = Uri.parse('$baseUrl/ww2/web.trangchu.module.content.asp');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        }
      }
      print('Lỗi khi gọi API home modules: ${response.statusCode}');
      return [];
    } catch (e) {
      print('Lỗi kết nối API home modules: $e');
      return [];
    }
  }

  static Future<int?> getCategoryIdByTitle(String title) async {
    try {
      final homeModules = await fetchHomeModules();
      final result = homeModules.where(
        (module) => module['tieude'] == title,
      ).toList();
      
      if (result.isNotEmpty) {
        return int.tryParse(result.first['idpart']?.toString() ?? '');
      }
      
      return null;
    } catch (e) {
      print('Không tìm thấy categoryId cho tieude: $title');
      return null;
    }
  }

  static Future<Map<String, dynamic>> fetchModule({
    required int categoryId,
    required String module,
    int pageId = 1,
    int sl = 10,
  }) async {
    final url = '$baseUrl/ww2/module.$module.asp?id=$categoryId&pageid=$pageId&sl=$sl';

    print('Query params: {id: $categoryId, pageid: $pageId, sl: $sl}');
    print('Fetching products from: $url');

    try {
      final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 5));

      print('response.statusCode: ${response.statusCode}');
      print('response.body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is List && decoded.isNotEmpty && decoded[0] is Map) {
          final firstItem = decoded[0];
          if (firstItem.containsKey('data')) {
            return {
              'tieude': '', // Sẽ được lấy từ home modules
              'idcatalog': categoryId.toString(),
              'data': firstItem['data'] ?? [],
            };
          } else {
            print('Phản hồi không chứa key "data"');
            return {
              'tieude': '',
              'idcatalog': categoryId.toString(),
              'data': [],
            };
          }
        } else {
          print('Phản hồi không hợp lệ');
          return {
            'tieude': '',
            'idcatalog': categoryId.toString(),
            'data': [],
          };
        }
      } else {
        print('Lỗi server: ${response.statusCode}');
        return {
          'tieude': '',
          'idcatalog': categoryId.toString(),
          'data': [],
        };
      }
    } catch (e) {
      print('Lỗi kết nối hoặc xử lý API: $e');
      return {
        'tieude': '',
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

      print('API sản phẩm/tin tức liên quan: $uri');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        try {
          // Làm sạch JSON response để xử lý các lỗi cú pháp
          String cleanedBody = cleanJsonResponse(response.body);
          
          print('Cleaned JSON body: $cleanedBody');
          
          // Thử xử lý đặc biệt cho trường hợp JSON bị lỗi hoàn toàn
          if (cleanedBody.contains('"baiviet":') && cleanedBody.contains('"kieu": "ht1103"')) {
            cleanedBody = _fixSpecialJsonCase(cleanedBody);
            print('Special case fixed JSON: $cleanedBody');
          }
          
          // Thử parse JSON với xử lý lỗi đặc biệt
          dynamic decoded;
          try {
            decoded = json.decode(cleanedBody);
          } catch (e) {
            print('JSON parse failed, trying manual fix: $e');
            // Thử sửa lỗi thủ công
            cleanedBody = _manualJsonFix(cleanedBody);
            print('Manually fixed JSON: $cleanedBody');
            try {
              decoded = json.decode(cleanedBody);
            } catch (e2) {
              print('Manual fix failed, trying complete reconstruction: $e2');
              // Thử xây dựng lại JSON hoàn toàn
              cleanedBody = _reconstructJson(cleanedBody);
              print('Reconstructed JSON: $cleanedBody');
              try {
                decoded = json.decode(cleanedBody);
              } catch (e3) {
                print('Reconstruction failed, using fallback: $e3');
                // Fallback cuối cùng: trả về danh sách rỗng
                decoded = [];
              }
            }
          }

          if (decoded is List && decoded.isNotEmpty) {
            print('🔍 API Response sections: ${decoded.map((s) => s['tieude']).toList()}');
            
            // Xử lý cho tin tức (tintuc)
            if (modelType == 'tintuc') {
              print('📰 Xử lý tin tức liên quan...');
              
              // Tìm section "TIN LIÊN QUAN" hoặc "TIN CŨ HƠN"
              Map<String, dynamic>? relatedSection;
              for (var section in decoded) {
                if (section is Map<String, dynamic>) {
                  final tieude = section['tieude']?.toString() ?? '';
                  if (tieude == 'TIN LIÊN QUAN' || tieude == 'TIN CŨ HƠN') {
                    relatedSection = section;
                    break;
                  }
                }
              }
              
              if (relatedSection != null) {
                final relatedNews = relatedSection['baiviet'] ?? [];
                print('📰 Tin tức liên quan tìm thấy: ${relatedNews.length} items');
                return relatedNews;
              } else {
                // Nếu không tìm thấy section, lấy tất cả items từ tất cả sections
                List<dynamic> allNews = [];
                for (var section in decoded) {
                  if (section is Map<String, dynamic> && section['baiviet'] is List) {
                    allNews.addAll(section['baiviet'] as List);
                  }
                }
                print('📰 Lấy tất cả tin tức từ các section: ${allNews.length} items');
                return allNews;
              }
            } else {
              print('🛍️ Xử lý sản phẩm liên quan...');
              // Xử lý cho sản phẩm (sanpham)
              final relatedSection = decoded.firstWhere(
                (section) => section['tieude'] == 'SẢN PHẨM LIÊN QUAN',
                orElse: () => {'baiviet': []},
              );
              final relatedProducts = relatedSection['baiviet'] ?? [];
              print('🛍️ Sản phẩm liên quan tìm thấy: ${relatedProducts.length} items');
              return relatedProducts;
            }
          } else {
            print('Phản hồi không phải List hoặc List rỗng.');
            return [];
          }
        } catch (jsonError) {
          print('Lỗi parse JSON: $jsonError');
          print('Raw response body: ${response.body}');
          return [];
        }
      } else {
        print('Lỗi server: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Lỗi khi gọi API sản phẩm/tin tức liên quan: $e');
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
          
          // Lấy categoryId mặc định từ tieude "Trang chủ"
          final defaultCategoryId = await getCategoryIdByTitle('Trang chủ') ?? 1;
          
          return data.map<Map<String, dynamic>>((item) {
            return {
              'id': item['id'].toString(),
              'name': item['tieude'] ?? '',
              'price': double.tryParse(item['gia']?.toString() ?? '0') ?? 0,
              'kieuhienthi': item['module'] == 'Tintuc' ? 'tintuc' : 'sanpham',
              'image': item['hinhdaidien'] ?? '',
              'quantity': 1,
              'isSelect': false,
              'categoryId': int.tryParse(item['categoryId']?.toString() ?? '0') ?? defaultCategoryId,
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
        String responseBody = cleanJsonResponse(response.body);
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