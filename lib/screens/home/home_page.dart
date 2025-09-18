import 'package:flutter/material.dart';
import 'package:flutter_application_1/Constant/app_colors.dart';
import 'package:flutter_application_1/Controller/home.dart';
import 'package:flutter_application_1/screens/home/components/news_card.dart';
import 'package:flutter_application_1/screens/home/components/product_card.dart';
import 'package:flutter_application_1/screens/home/components/filter_bottomsheet.dart';
import 'package:flutter_application_1/screens/home/components/technicalspec_item.dart';
import 'package:flutter_application_1/widgets/until.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../../models/category_model.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';
import '../contact/contact.dart';

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
  late HomeController homeController;
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    homeController = HomeController();
    homeController.init(widget.categoryNotifier);

    _listener = () async {
      if (!mounted) return;
      homeController.updateCategory(widget.categoryNotifier.value);
    };

    widget.categoryNotifier.addListener(_listener);
  }

  @override
  void dispose() {
    widget.categoryNotifier.removeListener(_listener);
    homeController.dispose();
    super.dispose();
  }

  // Method để tương thích với allpage.dart
  Future<void> fetchProducts() async {
    await homeController.fetchProducts();
  }

  // Method để tương thích với allpage.dart
  Future<void> runSearch(String keyword) async {
    await homeController.runSearch(keyword);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: homeController,
      child: Consumer<HomeController>(
        builder: (context, controller, child) {
          const List<int> singleColumnCategories = [35139, 35142, 35149];
          final crossAxisCount = singleColumnCategories.contains(controller.categoryId) ? 1 : 2;
          final modules = categoryModules[controller.categoryId];
          final isTinTuc = modules != null && modules[1] == 'tintuc';
          final labelWidth = 190.0;
          final screenWidth = MediaQuery.of(context).size.width;

          Widget bodyContent;

          if (controller.isLoading) {
            bodyContent = LoadingWidget();
          } else if (controller.categoryId == 35028) {
            bodyContent = ContactForm();
          } else if (controller.products.isEmpty) {
            bodyContent = RefreshIndicator(
              color: const Color(0xff0066FF),
              onRefresh: controller.refreshData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: EmptyStateWidget(
                      title: 'Mất kết nối',
                      subtitle: 'Vui lòng kiểm tra kết nối mạng\nvà thử lại sau',
                      icon: Icons.wifi_off,
                      color: Color(0xFF198754),
                    ),
                  ),
                ],
              ),
            );
          } else if (controller.categoryId == 0) {
            bodyContent = SafeArea(
              child: RefreshIndicator(
                color: const Color(0xff0066FF),
                onRefresh: () => Future.value(),
                child: controller.products.isEmpty
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
                                itemCount: controller.products.length,
                                itemBuilder: (context, index) {
                                  final product = controller.products[index];
                                  print('Product for card: $product');
                                  return NewsCard(
                                    product: product,
                                    categoryId: controller.categoryId,
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
          } else if (controller.categoryId == 35001) {
            final Map<int, List<dynamic>> groupedByCategory = {};
            for (var product in controller.products) {
              int catId = product['categoryId'] ?? 35001;
              groupedByCategory.putIfAbsent(catId, () => []).add(product);
            }

            bodyContent = RefreshIndicator(
              color: const Color(0xff0066FF),
              onRefresh: controller.refreshData,
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
                  controller.findCategoryNameById(controller.danhMucData, categoryId, parentOnly: true);

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
            final visibleProducts = controller.products.where((product) {
              return controller.categoryId == 35004 || hasValidImage(product);
            }).toList();

            bodyContent = RefreshIndicator(
              color: const Color(0xff0066FF),
              onRefresh: controller.refreshData,
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
                          return singleColumnCategories.contains(controller.categoryId)
                              ? NewsCard(
                                  product: product,
                                  categoryId: controller.categoryId,
                                  onTap: () => widget.onProductTap(product),
                                )
                              : ProductCard(
                                  product: product,
                                  categoryId: controller.categoryId,
                                  onTap: () => widget.onProductTap(product),
                                );
                        },
                      ),
                    ),
            );
          }

          return Scaffold(
            appBar: (controller.categoryId != 0 && controller.categoryId != 35001)
                ? AppBar(
                    backgroundColor: AppColors.backgroundColor,
                    titleSpacing: 8,
                    title: CustomPaint(
                      painter: CategoryLabelPainter(labelWidth: labelWidth),
                      child: Container(
                        height: 30,
                        width: screenWidth,
                        padding: const EdgeInsets.only(left: 8),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          !controller.isLoading ? controller.categoryName : 'Đang tải...',
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
                      if (!isTinTuc && controller.categoryId != 0 && controller.categoryId != 35001)
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
                                  idCatalog: controller.IdCatalogInitial,
                                  filterNotifier: widget.filterNotifier,
                                  onFilterSelected: (String idfilter) {
                                    controller.updateFilter(idfilter);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  )
                : null,
            backgroundColor: AppColors.backgroundColor,
            body: bodyContent,
          );
        },
      ),
    );
  }
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