import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/order_history_model.dart';
import 'package:flutter_application_1/services/cart_service.dart';
import 'package:flutter_application_1/services/favourite_service.dart';
import 'package:flutter_application_1/screens/cart/cart_history.dart';
import 'package:flutter_application_1/screens/profile/notification_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_model.dart';
import '../screens/detail/detail_page.dart';
import '../screens/favourite/favourite_page.dart';
import '../screens/profile/personal_info.dart';
import '../screens/register/register_view.dart';
import 'home.dart';
import '../screens/cart/cart_page.dart';
import '../screens/home/home_page.dart';
import '../screens/profile/profile_page.dart';
import '../services/api_service.dart';

class AllPageController extends ChangeNotifier {
  int _currentIndex = 0;
  final ValueNotifier<int> categoryNotifier = ValueNotifier(35001); // Sẽ được cập nhật từ tieude
  final ValueNotifier<int> filterNotifier = ValueNotifier(0);

  final GlobalKey<favouritePageState> favouritePageKey = GlobalKey<favouritePageState>();
  final GlobalKey<PageCartState> cartPageKey = GlobalKey<PageCartState>();
  final GlobalKey<CarthistoryPageState> carthistoryPageKey = GlobalKey<CarthistoryPageState>();
  final GlobalKey<HomePageState> homePageKey = GlobalKey<HomePageState>();
  final GlobalKey<PersonalInfoPageState> personalInfoPageKey = GlobalKey<PersonalInfoPageState>();
  final GlobalKey<NotificationPageState> notificationPageKey = GlobalKey<NotificationPageState>();

  final ValueNotifier<int> cartItemCountNotifier = ValueNotifier(0);
  final ValueNotifier<int> wishlistItemCountNotifier = ValueNotifier(0);
  final List<dynamic> _productDetailStack = [];
  final TextEditingController searchController = TextEditingController();

  String _currentPage = 'home';
  String _previousPage = 'home';

  Future<void> initializeDefaultCategory() async {
    try {
      final categoryId = await APIService.getCategoryIdByTitle('Trang chủ');
      if (categoryId != null) {
        categoryNotifier.value = categoryId;
      }
    } catch (e) {
      print('Không thể khởi tạo categoryId mặc định: $e');
    }
  }

  dynamic selectedProduct;

  late final HomePage _homePage;
  late final PageCart _cartPage;
  late final FavouritePage _favouritePage;
  late final Register _registerPage;
  late final ProfilePage _profilePage;
  late final PersonalInfoPage _personalInfoPage;
  late final NotificationPage _notificationPage;

  DetailPage? _detailPage;
  CarthistoryPage? _carthistoryPage;

  // Getters
  int get currentIndex => _currentIndex;
  String get currentPage => _currentPage;
  String get previousPage => _previousPage;
  dynamic get detailPage => _detailPage;
  CarthistoryPage? get carthistoryPage => _carthistoryPage;
  HomePage get homePage => _homePage;
  PageCart get cartPage => _cartPage;
  FavouritePage get favouritePage => _favouritePage;
  Register get registerPage => _registerPage;
  ProfilePage get profilePage => _profilePage;
  PersonalInfoPage get personalInfoPage => _personalInfoPage;
  NotificationPage get notificationPage => _notificationPage;

  void initializePages({
    required Function(dynamic) onProductTap,
    required Function() onTapCartHistory,
    required Function() onTapPersonalInfo,
    required Function() onTapNotification,
    required Function() onTapFavourite,
    required Function() onTapCart,
    required Function() onLogout,
    required Function(List<int>?) onGotoCart,
  }) {
    _homePage = HomePage(
      key: homePageKey,
      categoryNotifier: categoryNotifier,
      filterNotifier: filterNotifier,
      onProductTap: (product) {
        goToDetail(product, 'home');
      },
    );

    _cartPage = PageCart(
      cartitemCount: cartItemCountNotifier,
      key: cartPageKey,
      onProductTap: (product) {
        goToDetail(product, 'cart');
      },
    );

    _favouritePage = FavouritePage(
      onProductTap: (product) {
        goToDetail(product, 'favourite');
      },
      key: favouritePageKey,
      onFavouriteToggle: () {
        loadCounts();
      },
    );

    _registerPage = Register();
    _profilePage = ProfilePage(
      onTapCartHistory: onTapCartHistory,
      onTapPersonalInfo: onTapPersonalInfo,
      onTapNotification: onTapNotification,
      onTapFavourite: onTapFavourite,
      onTapCart: onTapCart,
      onLogout: onLogout,
    );

    _carthistoryPage = CarthistoryPage(
      gotoCart: onGotoCart,
      cartitemCount: cartItemCountNotifier,
      onProductTap: (product) {
        goToDetail(product, 'carthistory');
      },
      key: carthistoryPageKey,
    );

    _personalInfoPage = PersonalInfoPage(
      key: personalInfoPageKey,
    );

    _notificationPage = NotificationPage(
      key: notificationPageKey,
    );
  }

  Future<void> loadCounts() async {
    if (Global.email.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      Global.email = prefs.getString('emailAddress') ?? '';
      Global.name = prefs.getString('customerName') ?? '';
      Global.pass = prefs.getString('passWord') ?? '';
    }

    final cartCount = await APICartService.getCartItemCountFromApi(Global.email);
    final wishlistCount = await APIFavouriteService.getWishlistItemCountFromApi(Global.email);
    cartItemCountNotifier.value = cartCount;
    wishlistItemCountNotifier.value = wishlistCount;
    notifyListeners();
  }

  void goToCartHistory() {
    _currentPage = 'carthistory';
    carthistoryPageKey.currentState?.loadOrderHistory();
    notifyListeners();
  }

  void goToPersonalInfo() {
    _currentPage = 'personalinfo';
    notifyListeners();
  }

  void goToNotification() {
    _currentPage = 'notification';
    notifyListeners();
  }

  void goToFavourite() {
    _currentPage = 'favourite';
    _currentIndex = 1;
    favouritePageKey.currentState?.reloadFavourites();
    notifyListeners();
  }

  void goToCart() {
    _currentPage = 'cart';
    _currentIndex = 2;
    cartPageKey.currentState?.loadCartItems();
    notifyListeners();
  }

  void goHome({int? newCategoryId}) {
    _currentPage = 'home';
    _detailPage = null;
    selectedProduct = null;
    _previousPage = 'home';
    _productDetailStack.clear();
    if (newCategoryId != null) {
      categoryNotifier.value = newCategoryId;
    }
    notifyListeners();
  }

  void goToDetail(dynamic product, String fromPage, {bool isBack = false}) {
    String? currentId;
    String? newId;

    if (selectedProduct != null) {
      if (selectedProduct is CartItemModel) {
        currentId = selectedProduct.id;
      } else if (selectedProduct is Map) {
        currentId = selectedProduct['id'].toString();
      }
    }

    if (product is CartItemModel) {
      newId = product.id;
    } else if (product is Map<String, dynamic>) {
      newId = product['id']?.toString();
    } else if (product is OrderModel) {
      if (product.items.isNotEmpty) {
        newId = product.items.first.id;
      }
    }

    if (!isBack && fromPage != 'detail') {
      _previousPage = fromPage;
    }
    if (!isBack && _currentPage == 'detail' && currentId != null && newId != null && currentId != newId) {
      _productDetailStack.add(selectedProduct);
    }

    selectedProduct = product;
    _currentPage = 'detail';
    _detailPage = null;

    final productId = newId ?? '0';
    _detailPage = DetailPage(
      gotoCart: (int? productIdVuaThem) {
        _currentPage = 'cart';
        _currentIndex = 2;
        if (productIdVuaThem != null)
          cartPageKey.currentState?.chonNhieuVaMoBottomSheet([productIdVuaThem]);
        notifyListeners();
      },
      modelType: product is CartItemModel
          ? product.moduleType
          : (product is Map<String, dynamic> ? product['moduleType'] ?? '' : ''),
      cartitemCount: cartItemCountNotifier,
      productId: productId,
      categoryNotifier: categoryNotifier,
      onBack: () {
        if (_productDetailStack.isNotEmpty) {
          final previousProduct = _productDetailStack.removeLast();
          goToDetail(previousProduct, 'detail', isBack: true);
        } else {
          _currentPage = _previousPage;
          _detailPage = null;
          selectedProduct = null;
          _previousPage = 'home';
          _productDetailStack.clear();
          notifyListeners();
        }
      },
      onProductTap: (newProduct) {
        goToDetail(newProduct, 'detail');
      },
      wishlistItemCountNotifier: wishlistItemCountNotifier,
    );

    notifyListeners();
  }

  int getPageIndex() {
    switch (_currentPage) {
      case 'home':
        return 0;
      case 'favourite':
        return 1;
      case 'cart':
        return 2;
      case 'register':
        return 3;
      case 'profile':
        return 4;
      case 'detail':
        return 5;
      case 'carthistory':
        return 6;
      case 'personalinfo':
        return 7;
      case 'notification':
        return 8;
      default:
        return 0;
    }
  }

  void onTabTapped(int index) {
    _currentIndex = index;
    switch (index) {
      case 0:
        _currentPage = 'home';
        // Khởi tạo categoryId từ tieude "Trang chủ"
        initializeDefaultCategory();
        homePageKey.currentState?.fetchProducts();
        break;
      case 1:
        _currentPage = 'favourite';
        favouritePageKey.currentState?.reloadFavourites();
        break;
      case 2:
        _currentPage = 'cart';
        cartPageKey.currentState?.loadCartItems();
        break;
      case 3:
        _currentPage = 'profile';
        break;
    }
    notifyListeners();
  }

  void onCategorySelected(int id) {
    _currentPage = 'home';
    _currentIndex = 0;
    categoryNotifier.value = id;
    searchController.clear();
    notifyListeners();
  }

  void onSearch(String keyword) {
    _currentIndex = 0;
    _currentPage = 'home';
    filterNotifier.value++;
    homePageKey.currentState?.runSearch(keyword);
    notifyListeners();
  }

  void resetToHome() {
    _currentPage = 'home';
    _currentIndex = 0;
    cartItemCountNotifier.value = 0;
    wishlistItemCountNotifier.value = 0;
    notifyListeners();
  }
}
