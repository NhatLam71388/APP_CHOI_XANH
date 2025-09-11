import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/screens/layout/components/bottom_appbar.dart';
import 'package:flutter_application_1/screens/layout/components/search_appbar.dart';
import 'package:flutter_application_1/screens/layout/components/category_drawer.dart';
import '../../Controller/layout_controller.dart';

class AllPageView extends StatefulWidget {
  const AllPageView({super.key});

  @override
  State<AllPageView> createState() => _AllPageViewState();
}

class _AllPageViewState extends State<AllPageView> {
  late final AllPageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AllPageController();
    
    // Initialize pages with callbacks
    _controller.initializePages(
      onProductTap: (product) {
        _controller.goToDetail(product, 'home');
      },
      onTapCartHistory: () {
        // _controller.goToCartHistory();
      },
      onTapPersonalInfo: () {
        _controller.goToPersonalInfo();
      },
      onTapNotification: () {
        _controller.goToNotification();
      },
      onTapFavourite: () {
        _controller.goToFavourite();
      },
      onTapCart: () {
        _controller.goToCart();
      },
      onLogout: () async {
        await AuthService.handleLogout(context);
        _controller.resetToHome();
      },
      onGotoCart: (List<int>? productIdsVuaThem) {
        _controller.goToCart();
        _controller.cartPageKey.currentState?.chonNhieuVaMoBottomSheet(productIdsVuaThem ?? []);
      },
    );

    // Load initial counts
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print("Đang gọi hàm lấy số lượng giỏ hàng và yêu thích...");
      await _controller.loadCounts();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            drawer: DanhMucDrawer(
              onCategorySelected: (int id) async {
                await Navigator.of(context).maybePop();
                _controller.onCategorySelected(id);
              },
            ),
            body: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: kToolbarHeight,
                    bottom: kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
                  ),
                  child: IndexedStack(
                    index: _controller.getPageIndex(),
                    children: [
                      _controller.homePage,
                      _controller.favouritePage,
                      _controller.cartPage,
                      _controller.registerPage,
                      _controller.profilePage,
                      _controller.detailPage ?? Container(),
                      _controller.carthistoryPage ?? Container(),
                      _controller.personalInfoPage,
                      _controller.notificationPage,
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SearchAppBar(
                    controller: _controller.searchController,
                    onSearch: (String keyword) {
                      _controller.onSearch(keyword);
                    },
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    top: false,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      child: ValueListenableBuilder<int>(
                        valueListenable: _controller.cartItemCountNotifier,
                        builder: (context, cartCount, _) {
                          return ValueListenableBuilder<int>(
                            valueListenable: _controller.wishlistItemCountNotifier,
                            builder: (context, wishlistCount, _) {
                              return CustomBottomNavBar(
                                cartitemCount: cartCount,
                                wishlistItemCount: wishlistCount,
                                currentIndex: _controller.currentIndex,
                                onTap: _controller.onTabTapped,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
