import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/category_model.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/widgets/until.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart' show parse;
import 'package:flutter/foundation.dart';

class HomeController extends ChangeNotifier {
  int _categoryId = 0;
  List<dynamic> products = [];
  bool isLoading = true;
  List<int> dynamicCategoryIds = [];
  String categoryName = '';
  String IdCatalogInitial = '';
  String selectedFilterString = '';

  late Map<String, dynamic> danhMucData;

  // Getters
  int get categoryId => _categoryId;
  bool get hasProducts => products.isNotEmpty;
  int get productCount => products.length;

  Future<void> init(ValueNotifier<int> categoryNotifier) async {
    _categoryId = categoryNotifier.value;
    await loadLoginStatus();
    await fetchDanhMucFromAPI();
    await fetchProducts();
  }

  Future<void> loadLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    Global.name = prefs.getString('customerName') ?? '';
    Global.email = prefs.getString('emailAddress') ?? '';
    Global.pass = prefs.getString('passWord') ?? '';
    print('emailadresshome: ${Global.email}');
  }

  Future<void> fetchDanhMucFromAPI() async {
    try {
      final response = await http.get(
        Uri.parse('${APIService.baseUrl}/ww2/app.menu.dautrang.asp'),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        // Lọc các danh mục không mong muốn
        final List<dynamic> filteredList = json.where((item) => ![
          'Test 3 cấp',
          'Thành viên đăng nhập',
          'Tìm kiếm'
        ].contains(item['tieude'])).toList();
        final List<Map<String, dynamic>> data =
        filteredList.map((item) => Map<String, dynamic>.from(item)).toList();

        try {
          final result = await compute(processCategoryData, data);
          dynamicCategoryIds = List<int>.from(result['ids']);
          danhMucData = Map<String, dynamic>.from(result['danhMucData']);
          print('Dynamic Category IDs: $dynamicCategoryIds');
          print('DanhMuc Data: $danhMucData');
        } catch (e, stack) {
          print("🔥 Lỗi khi xử lý compute: $e");
          print("🔥 Stack trace: $stack");
        }
      } else {
        print("Lỗi API: ${response.statusCode}");
      }
    } catch (e) {
      print("Lỗi khi fetch danh mục: $e");
    }
  }

  Future<void> fetchProducts() async {
    isLoading = true;
    products = []; // Xóa danh sách sản phẩm cũ
    notifyListeners();

    try {
      List<dynamic> allProducts = [];
      String newCategoryName = '';
      String newIdCatalog = '';

      if (_categoryId == 35001) {
        // Tải lại toàn bộ sản phẩm từ tất cả danh mục
        for (int id in dynamicCategoryIds) {
          final modules = categoryModules[id];
          if (modules == null) continue;

          final Map<String, dynamic> response =
          await APIService.fetchProductsByCategory(
              ww2: modules[0],
              product: modules[1],
              extention: modules[2],
              categoryId: id,
              idfilter: '0');

          final String categoryTitle =
              response['tieude'] ?? 'Không rõ tên danh mục';
          final String GetIdCatalog = response['idcatalog']?.toString() ?? '';

          if (newCategoryName.isEmpty) newCategoryName = categoryTitle;
          if (newIdCatalog.isEmpty) newIdCatalog = GetIdCatalog;

          final List<dynamic> fetched = response['data'] ?? [];

          final enhanced = fetched.map<Map<String, dynamic>>((item) {
            return {
              ...item as Map<String, dynamic>,
              'moduleType': modules[1],
              'categoryId': id,
              'categoryTitle': categoryTitle,
            };
          }).toList();

          allProducts.addAll(enhanced);

          // Cập nhật UI sau mỗi lần tải danh mục
          products = List.from(allProducts);
          categoryName = newCategoryName;
          IdCatalogInitial = newIdCatalog;
          notifyListeners();
        }
      } else {
        final modules = categoryModules[_categoryId];
        if (modules == null) {
          products = [];
          isLoading = false;
          notifyListeners();
          return;
        }

        final Map<String, dynamic> response =
        await APIService.fetchProductsByCategory(
          ww2: modules[0],
          product: modules[1],
          extention: modules[2],
          categoryId: _categoryId,
          idfilter: selectedFilterString,
        );

        final String categoryTitle =
            response['tieude'] ?? 'Không rõ tên danh mục';
        final String getidcatalog =
            response['idcatalog'] ?? 'Không rõ tên danh mục';

        newCategoryName = categoryTitle;
        newIdCatalog = getidcatalog;

        final List<dynamic> fetched = response['data'] ?? [];

        allProducts = fetched.map<Map<String, dynamic>>((item) {
          return {
            ...item as Map<String, dynamic>,
            'moduleType': modules[1],
            'categoryId': _categoryId,
            'categoryTitle': categoryTitle,
          };
        }).toList();

        products = allProducts;
        categoryName = newCategoryName;
        IdCatalogInitial = newIdCatalog;
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      print("Lỗi khi fetch sản phẩm: $e");
      isLoading = false;
      notifyListeners();
    }
  }

  void updateCategory(int newCategoryId) {
    _categoryId = newCategoryId;
    selectedFilterString = '';
    isLoading = true;
    notifyListeners();
    fetchProducts();
  }

  void updateFilter(String filterId) {
    selectedFilterString = filterId;
    isLoading = true;
    notifyListeners();
    fetchProducts();
  }

  String findCategoryNameById(Map<String, dynamic> data, int id,
      {bool parentOnly = true}) {
    for (var entry in data.entries) {
      final value = entry.value;
      if (value is Map && value['id'] == id) {
        return entry.key;
      }
      if (value is Map && value.containsKey('children')) {
        final childData = value['children'] as Map<String, dynamic>;
        for (var childEntry in childData.entries) {
          final childValue = childEntry.value;
          if (childValue is Map && childValue['id'] == id) {
            return parentOnly ? entry.key : childEntry.key;
          }
        }
      }
    }
    return '';
  }

  String parseHtmlString(String htmlString) {
    final document = parse(htmlString);
    return parse(document.body?.text).documentElement?.text ?? '';
  }

  Future<void> runSearch(String keyword) async {
    isLoading = true;
    products = [];
    _categoryId = 0;
    notifyListeners();

    try {
      final result = await APIService.searchSanPham(keyword);

      products = result.map((item) {
        return {
          ...item,
          'categoryId': item['categoryId'] ?? 0,
          'hinhdaidien': item['image'] ?? '',
          'gia': item['price'] ?? 0.0,
          'tieude': item['name'] ?? 'Unknown',
          'moduleType': item['kieuhienthi'],
        };
      }).toList();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Lỗi khi tìm kiếm: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _categoryId = 0;
    products = [];
    notifyListeners();
  }
}

class Global {
  static String name = '';
  static String email = '';
  static String pass = '';
}

Map<String, dynamic> processCategoryData(List<dynamic> categories) {
  final List<Map<String, dynamic>> safeList =
  categories.map((item) => Map<String, dynamic>.from(item)).toList();

  List<int> getParentCategoryIds(List<Map<String, dynamic>> items) {
    return items.map((e) => int.parse(e['idpart'].toString())).toList();
  }

  Map<String, dynamic> convertToDanhMucData(List<Map<String, dynamic>> items) {
    Map<String, dynamic> result = {};
    for (var item in items) {
      final id = item['idpart'].toString();
      final tieude = item['tieude'] ?? 'Danh mục $id';
      result[tieude] = {
        'id': int.parse(id),
        if (item.containsKey('menucap1') && item['menucap1'] is List)
          'children': convertToDanhMucData(
              List<Map<String, dynamic>>.from(item['menucap1'])),
      };
    }
    return result;
  }

  return {
    'ids': getParentCategoryIds(safeList),
    'danhMucData': convertToDanhMucData(safeList),
  };
}
