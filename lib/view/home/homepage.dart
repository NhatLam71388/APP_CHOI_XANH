import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/category_model.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/view/components/news_card.dart';
import 'package:flutter_application_1/view/detail/comment_card.dart';
import 'package:flutter_application_1/view/components/product_card.dart';
import 'package:flutter_application_1/view/contact/contact.dart';
import 'package:flutter_application_1/view/detail/detail_page.dart';
import 'package:flutter_application_1/view/drawer/category_drawer.dart';
import 'package:flutter_application_1/view/drawer/filter_bottomsheet.dart';
import 'package:flutter_application_1/view/until/technicalspec_item.dart';
import 'package:flutter_application_1/view/until/until.dart';
import 'package:flutter_application_1/widgets/button_widget.dart';
import 'package:flutter_application_1/widgets/input_widget.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart' show parse;
import 'package:flutter/foundation.dart';

class HomePage extends StatefulWidget {
  final ValueNotifier<int> categoryNotifier;
  final ValueNotifier<int?> filterNotifier;
  final Function(dynamic product) onProductTap;

  const HomePage({
    super.key,
    required this.categoryNotifier,
    required this.filterNotifier,
    required this.onProductTap,
  });
  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _categoryId = 0;
  List<dynamic> products = [];
  bool isLoading = true;
  List<int> dynamicCategoryIds = [];
  String categoryName = '';
  String IdCatalogInitial = '';
  String selectedFilterString = '';

  late VoidCallback _listener;

  final ValueNotifier<int> filterNotifier = ValueNotifier(0);
  late Map<String, dynamic> danhMucData;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.categoryNotifier.value;

    _listener = () async {
      if (!mounted) return;
      setState(() {
        _categoryId = widget.categoryNotifier.value;
        selectedFilterString = '';
        isLoading = true;
      });
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('savedFilters_${Global.email}');
      fetchProducts();
    };

    widget.categoryNotifier.addListener(_listener);

    loadLoginStatus();
    fetchDanhMucFromAPI().then((_) => fetchProducts());
  }

  @override
  void dispose() {
    widget.categoryNotifier.removeListener(_listener);
    super.dispose();
  }

  Future<void> fetchDanhMucFromAPI() async {
    try {
      final response = await http.get(
        Uri.parse('https://demochung.125.atoz.vn/ww2/app.menu.dautrang.asp'),
      );
      // print('DanhMuc API response status: ${response.statusCode}');
      // print('DanhMuc API response body: ${response.body}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        // print('DanhMuc API decoded: $json');
        final List<dynamic> rawList = json; // JSON mới là danh sách trực tiếp
        final List<Map<String, dynamic>> data =
        rawList.map((item) => Map<String, dynamic>.from(item)).toList();

        try {
          final result = await compute(processCategoryData, data);
          if (!mounted) return;
          setState(() {
            dynamicCategoryIds = List<int>.from(result['ids']);
            danhMucData = Map<String, dynamic>.from(result['danhMucData']);
          });
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

  Future<void> loadLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      Global.name = prefs.getString('customerName') ?? '';
      Global.email = prefs.getString('emailAddress') ?? '';
      Global.pass = prefs.getString('passWord') ?? '';
      print('emailadresshome: ${Global.email}');
    });
  }

  Future<void> fetchProducts() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      List<dynamic> allProducts = [];
      String newCategoryName = '';
      String newIdCatalog = '';

      if (_categoryId == 35001) {
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

          // Update UI incrementally after each category is fetched
          if (mounted) {
            setState(() {
              products = List.from(allProducts); // Update products incrementally
              categoryName = newCategoryName;
              IdCatalogInitial = newIdCatalog;
              isLoading = false; // Keep isLoading false to avoid showing loading indicator
            });
          }
        }
      } else {
        final modules = categoryModules[_categoryId];
        if (modules == null) {
          setState(() {
            products = [];
            isLoading = false;
          });
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

        if (!mounted) return;

        setState(() {
          products = allProducts;
          categoryName = newCategoryName;
          IdCatalogInitial = newIdCatalog;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi khi fetch sản phẩm: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String findCategoryNameById(Map<String, dynamic> data, int id,
      {bool parentOnly = true}) {
    for (var entry in data.entries) {
      final value = entry.value;
      if (value is Map && value['id'] == id) {
        return entry.key; // Trả về tên danh mục hiện tại (cha hoặc chính nó)
      }
      if (value is Map && value.containsKey('children')) {
        // Kiểm tra danh mục con
        final childData = value['children'] as Map<String, dynamic>;
        for (var childEntry in childData.entries) {
          final childValue = childEntry.value;
          if (childValue is Map && childValue['id'] == id) {
            return parentOnly
                ? entry.key
                : childEntry.key; // Trả về tên cha nếu parentOnly = true
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
    if (!mounted) return;
    setState(() {
      isLoading = true;
      products = [];
      _categoryId = 0;
    });

    try {
      final result = await APIService.searchSanPham(keyword);

      if (!mounted) return;
      setState(() {
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
      });
    } catch (e) {
      print('Lỗi khi tìm kiếm: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Danh sách các categoryId cần hiển thị 1 cột với NewsCard
    const List<int> singleColumnCategories = [35139, 35142, 35149];
    final crossAxisCount = singleColumnCategories.contains(_categoryId) ? 1 : 2;
    final modules = categoryModules[_categoryId];
    final isTinTuc = modules != null && modules[1] == 'tintuc';
    final labelWidth = 190.0;
    final screenWidth = MediaQuery.of(context).size.width;

    // Xác định nội dung body dựa trên các điều kiện
    Widget bodyContent;

    if (isLoading) {
      bodyContent = const Center(
        child: CircularProgressIndicator(
          color: Color(0xff0066FF),
        ),
      );
    } else if (_categoryId == 35028) {
      bodyContent = ContactForm();
    } else if (products.isEmpty) {
      bodyContent = const Center(
        child: Text(
          'Không có dữ liệu',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    } else if (_categoryId == 0) {
      bodyContent = SafeArea(
        child: RefreshIndicator(
          color: const Color(0xff0066FF),
          onRefresh: () => Future.value(),
          child: products.isEmpty
              ? ListView(
            children: const [
              SizedBox(height: 200),
              Center(
                child: Text(
                  'Không có dữ liệu',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            ],
          )
              : Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.search_outlined,
                          color: Color(0xff0066FF), size: 24),
                      Text(
                        'Kết quả tìm kiếm',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: MasonryGridView.count(
                    crossAxisCount: 1,
                    mainAxisSpacing: 1,
                    crossAxisSpacing: 1,
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      print('Product for card: $product');
                      return NewsCard(
                        product: product,
                        categoryId: _categoryId,
                        onTap: () => widget.onProductTap(product),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (_categoryId == 35001) {
      final Map<int, List<dynamic>> groupedByCategory = {};
      for (var product in products) {
        int catId = product['categoryId'] ?? 35001;
        groupedByCategory.putIfAbsent(catId, () => []).add(product);
      }

      bodyContent = RefreshIndicator(
        color: const Color(0xff0066FF),
        onRefresh: fetchProducts,
        child: ListView(
          padding: const EdgeInsets.all(8.0),
          children: groupedByCategory.entries.map((entry) {
            final categoryId = entry.key;
            if (categoryId == 35149) return const SizedBox.shrink();

            final productList = entry.value.where((p) {
              return categoryId == 35004 || hasValidImage(p);
            }).toList();

            if (productList.isEmpty) return const SizedBox.shrink();

            final categoryName =
            findCategoryNameById(danhMucData, categoryId, parentOnly: true);

            return SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomPaint(
                    painter: CategoryLabelPainter(labelWidth: labelWidth),
                    child: Container(
                      height: 30,
                      width: screenWidth,
                      padding: const EdgeInsets.only(left: 12),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        categoryName.isNotEmpty ? categoryName : 'Danh mục',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  MasonryGridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount:
                    singleColumnCategories.contains(categoryId) ? 1 : 2,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    itemCount: productList.length,
                    itemBuilder: (context, index) {
                      final product = productList[index];
                      return singleColumnCategories.contains(categoryId)
                          ? NewsCard(
                        product: product,
                        categoryId: categoryId,
                        onTap: () => widget.onProductTap(product),
                      )
                          : ProductCard(
                        product: product,
                        categoryId: categoryId,
                        onTap: () => widget.onProductTap(product),
                      );
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    } else {
      final visibleProducts = products.where((product) {
        return _categoryId == 35004 || hasValidImage(product);
      }).toList();

      bodyContent = RefreshIndicator(
        color: const Color(0xff0066FF),
        onRefresh: fetchProducts,
        child: visibleProducts.isEmpty
            ? ListView(
          children: const [
            SizedBox(height: 200),
            Center(
              child: Text(
                'Không có dữ liệu',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          ],
        )
            : Padding(
          padding: const EdgeInsets.all(8.0),
          child: MasonryGridView.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 1,
            crossAxisSpacing: 1,
            itemCount: visibleProducts.length,
            itemBuilder: (context, index) {
              final product = visibleProducts[index];
              return singleColumnCategories.contains(_categoryId)
                  ? NewsCard(
                product: product,
                categoryId: _categoryId,
                onTap: () => widget.onProductTap(product),
              )
                  : ProductCard(
                product: product,
                categoryId: _categoryId,
                onTap: () => widget.onProductTap(product),
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      appBar: (_categoryId != 0 && _categoryId != 35001)
          ? AppBar(
        backgroundColor: Colors.white,
        titleSpacing: 8,
        title: CustomPaint(
          painter: CategoryLabelPainter(labelWidth: labelWidth),
          child: Container(
            height: 30,
            width: screenWidth,
            padding: const EdgeInsets.only(left: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              !isLoading ? categoryName : 'Đang tải...',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (!isTinTuc && _categoryId != 0 && _categoryId != 35001)
            Container(
              margin: const EdgeInsets.only(right: 8, left: 0),
              width: 35,
              height: 35,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 25,
                icon: const Icon(Icons.filter_alt, color: Colors.white),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => BoLocBottomSheet(
                      idCatalog: IdCatalogInitial,
                      filterNotifier: filterNotifier,
                      onFilterSelected: (String idfilter) {
                        setState(() {
                          selectedFilterString = idfilter;
                          isLoading = true;
                        });
                        fetchProducts();
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      )
          : null, // hoặc để trống nếu không cần AppBar
      backgroundColor: Colors.grey[100],
      body: bodyContent,
    );
  }
}

class Global {
  static String name = '';
  static String email = '';
  static String pass = '';
}

class CategoryLabelPainter extends CustomPainter {
  final double labelWidth;
  final double notchHeight;

  CategoryLabelPainter({
    required this.labelWidth,
    this.notchHeight = 26,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF198754)
      ..style = PaintingStyle.fill;

    final path = Path();

    path.moveTo(0, 0);
    path.lineTo(labelWidth - 25, 0);
    path.lineTo(labelWidth, notchHeight);
    path.lineTo(labelWidth, size.height);
    path.lineTo(0, size.height);
    path.close();

    final rect = Rect.fromLTWH(labelWidth, notchHeight, size.width - labelWidth,
        size.height - notchHeight);
    canvas.drawRect(rect, paint);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
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