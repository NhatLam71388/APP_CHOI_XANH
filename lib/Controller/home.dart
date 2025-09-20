import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/category_model.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/services/home_cache_service.dart';
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
  List<Map<String, dynamic>> homeModules = [];

  // Getters
  int get categoryId => _categoryId;
  bool get hasProducts => products.isNotEmpty;
  int get productCount => products.length;

  Future<void> init(ValueNotifier<int> categoryNotifier) async {
    _categoryId = categoryNotifier.value;
    await loadLoginStatus();
    // Tải home modules từ API mới
    await fetchHomeModules();
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

  Future<void> fetchHomeModules() async {
    try {
      homeModules = await APIService.fetchHomeModules();
      print('Home modules loaded: ${homeModules.length} items');
    } catch (e) {
      print('Lỗi khi tải home modules: $e');
      homeModules = [];
    }
  }

  Map<String, dynamic>? getModuleInfoByCategoryId(int categoryId) {
    try {
      final result = homeModules.where(
        (module) => module['idpart'] == categoryId.toString(),
      ).toList();
      
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('Không tìm thấy module cho categoryId: $categoryId');
      return null;
    }
  }

  String getCategoryTitleByCategoryId(int categoryId) {
    try {
      // Tìm trong homeModules trước
      final moduleInfo = getModuleInfoByCategoryId(categoryId);
      if (moduleInfo != null && moduleInfo['tieude'] != null) {
        return moduleInfo['tieude'];
      }
      
      // Nếu không tìm thấy trong homeModules, tìm trong danhMucData
      return findCategoryNameById(danhMucData, categoryId, parentOnly: true);
    } catch (e) {
      print('Không tìm thấy tieude cho categoryId: $categoryId');
      return '';
    }
  }

  int? getCategoryIdByTitle(String title) {
    try {
      // Tìm trong homeModules
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

  Future<void> fetchDanhMucFromAPI() async {
    try {
      // Kiểm tra cache trước
      final cachedCategoryData = await HomeCacheService.getCachedCategoryData();
      if (cachedCategoryData != null) {
        print('🚀 Sử dụng cache cho dữ liệu danh mục');
        dynamicCategoryIds = List<int>.from(cachedCategoryData['dynamicCategoryIds']);
        danhMucData = Map<String, dynamic>.from(cachedCategoryData['categoryData']);
        return;
      }

      print('🌐 Tải dữ liệu danh mục từ API');
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
          
          // Cache dữ liệu danh mục
          await HomeCacheService.cacheCategoryData(danhMucData, dynamicCategoryIds);
          
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

  Future<void> fetchProducts({bool forceRefresh = false}) async {
    isLoading = true;
    notifyListeners();

    try {
      // Kiểm tra cache nếu không bắt buộc refresh
      if (!forceRefresh) {
        final cachedData = await HomeCacheService.getCachedProducts(_categoryId);
        if (cachedData != null) {
          print('🚀 Sử dụng cache cho categoryId: $_categoryId');
          products = List<dynamic>.from(cachedData['products']);
          categoryName = cachedData['categoryName'] ?? '';
          IdCatalogInitial = cachedData['IdCatalogInitial'] ?? '';
          isLoading = false;
          notifyListeners();
          return;
        }
      }

      print('🌐 Tải dữ liệu sản phẩm từ API cho categoryId: $_categoryId');
      
      // Xóa cache cũ nếu force refresh
      if (forceRefresh) {
        await HomeCacheService.clearCachedProducts(_categoryId);
      }

      products = []; // Xóa danh sách sản phẩm cũ
      notifyListeners();

      List<dynamic> allProducts = [];
      String newCategoryName = '';
      String newIdCatalog = '';

      final categoryTitle = getCategoryTitleByCategoryId(_categoryId);
      
      if (categoryTitle == 'Trang chủ') {
        // Kiểm tra dynamicCategoryIds có dữ liệu không
        if (dynamicCategoryIds.isEmpty) {
          print('⚠️ dynamicCategoryIds rỗng, đang tải lại dữ liệu danh mục...');
          await fetchDanhMucFromAPI();
          
          // Nếu vẫn rỗng sau khi tải lại
          if (dynamicCategoryIds.isEmpty) {
            print('❌ Không thể tải danh mục, hiển thị màn hình trống');
            products = [];
            isLoading = false;
            notifyListeners();
            return;
          }
        }
        
        // Tải lại toàn bộ sản phẩm từ tất cả danh mục
        for (int id in dynamicCategoryIds) {
          final moduleInfo = getModuleInfoByCategoryId(id);
          if (moduleInfo == null) continue;

          final String module = moduleInfo['module'] ?? 'sanpham';
          final String categoryTitle = moduleInfo['tieude'] ?? 'Không rõ tên danh mục';

          final Map<String, dynamic> response =
          await APIService.fetchModule(
              categoryId: id,
              module: module);

          final String GetIdCatalog = response['idcatalog']?.toString() ?? '';

          if (newCategoryName.isEmpty) newCategoryName = categoryTitle;
          if (newIdCatalog.isEmpty) newIdCatalog = GetIdCatalog;

          final List<dynamic> fetched = response['data'] ?? [];

          final enhanced = fetched.map<Map<String, dynamic>>((item) {
            return {
              ...item as Map<String, dynamic>,
              'moduleType': module,
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
        final moduleInfo = getModuleInfoByCategoryId(_categoryId);
        if (moduleInfo == null) {
          products = [];
          isLoading = false;
          notifyListeners();
          return;
        }

        final String module = moduleInfo['module'] ?? 'sanpham';
        final String categoryTitle = moduleInfo['tieude'] ?? 'Không rõ tên danh mục';

        final Map<String, dynamic> response =
        await APIService.fetchModule(
          categoryId: _categoryId,
          module: module,
        );

        final String getidcatalog = response['idcatalog'] ?? '';

        newCategoryName = categoryTitle;
        newIdCatalog = getidcatalog;

        final List<dynamic> fetched = response['data'] ?? [];

        allProducts = fetched.map<Map<String, dynamic>>((item) {
          return {
            ...item as Map<String, dynamic>,
            'moduleType': module,
            'categoryId': _categoryId,
            'categoryTitle': categoryTitle,
          };
        }).toList();

        products = allProducts;
        categoryName = newCategoryName;
        IdCatalogInitial = newIdCatalog;
      }

      // Cache dữ liệu sản phẩm
      final cacheData = {
        'products': products,
        'categoryName': categoryName,
        'IdCatalogInitial': IdCatalogInitial,
      };
      await HomeCacheService.cacheProducts(_categoryId, cacheData);

      isLoading = false;
      notifyListeners();
    } catch (e) {
      print("❌ Lỗi khi fetch sản phẩm: $e");
      print("❌ CategoryId: $_categoryId, DynamicCategoryIds: $dynamicCategoryIds");
      products = [];
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
    fetchProducts(forceRefresh: true); // Force refresh khi thay đổi filter
  }

  /// Refresh dữ liệu và xóa cache
  Future<void> refreshData() async {
    print('🔄 Làm mới dữ liệu và xóa cache');
    await fetchProducts(forceRefresh: true);
  }

  /// Xóa toàn bộ cache
  Future<void> clearAllCache() async {
    await HomeCacheService.clearAllCache();
    print('🗑️ Đã xóa toàn bộ cache');
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
