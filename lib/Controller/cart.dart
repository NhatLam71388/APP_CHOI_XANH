import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/product_model.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/services/cart_service.dart';
import 'package:flutter_application_1/screens/cart/component/cart_ulti.dart';
import 'package:flutter_application_1/widgets/until.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';

class CartController extends ChangeNotifier {
  List<CartItemModel> cartItems = [];
  bool isSelectAll = false;
  bool isLoading = true;
  bool isOrdering = false;
  late BuildContext rootContext;

  final addressController = TextEditingController();
  final fullnameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  bool get hasSelectedItems => cartItems.any((item) => item.isSelect);
  int get phiVanChuyen => hasSelectedItems ? 30000 : 0;

  double get tongThanhToan {
    final totalPrice = calculateTotalPrice(cartItems) + phiVanChuyen;
    return totalPrice.toDouble();
  }

  Future<void> init(ValueNotifier<int> cartitemCount) async {
    await loadCartItems(cartitemCount);
    emailController.text = Global.email;
    fullnameController.text = Global.name;
  }

  Future<void> loadCartItems(ValueNotifier<int> cartitemCount) async {
    try {
      final selectedIds = cartItems
          .where((item) => item.isSelect)
          .map((e) => e.id.toString())
          .toSet();

      final items = await APICartService.fetchCartItemsById(
        emailAddress: Global.email,
        cartitemCount: cartitemCount,
        password: Global.pass
      );

      cartItems = items.map((e) {
        e.isSelect = selectedIds.contains(e.id.toString());
        return e;
      }).toList();

      isSelectAll = cartItems.isNotEmpty && cartItems.every((item) => item.isSelect);
      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Lỗi khi load cart items: $e');
      cartItems = [];
      isSelectAll = false;
      isLoading = false;
      cartitemCount.value = 0;
      notifyListeners();
      showToast('Không thể tải giỏ hàng, vui lòng thử lại', backgroundColor: Colors.red);
    }
  }

  Future<void> chonNhieuVaMoBottomSheet(List<int> productIdsVuaThem, ValueNotifier<int> cartitemCount) async {
    await loadCartItems(cartitemCount);
    await Future.delayed(Duration(milliseconds: 100));

    if (productIdsVuaThem.isNotEmpty) {
      for (var item in cartItems) {
        int? itemId = int.tryParse(item.id.toString());
        item.isSelect = itemId != null && productIdsVuaThem.contains(itemId);
      }
      isSelectAll = cartItems.every((item) => item.isSelect);
      notifyListeners();
    }
  }

  void toggleSelectAll(bool? value) {
    isSelectAll = value ?? false;
    for (var item in cartItems) {
      item.isSelect = isSelectAll;
    }
    notifyListeners();
  }

  Future<bool> updateItemQuantity(CartItemModel item, int newQuantity, ValueNotifier<int> cartitemCount) async {
    int productId = int.tryParse(item.id.toString()) ?? 0;
    if (productId == 0) return false;

      item.quantity = newQuantity;
      notifyListeners();
      return true;
  }

  Future<void> increaseQuantity(CartItemModel item, ValueNotifier<int> cartitemCount) async {
    final success = await updateItemQuantity(item, item.quantity + 1, cartitemCount);
    if (!success) {
      // Rollback if failed
      item.quantity = item.quantity;
    }
  }

  Future<void> decreaseQuantity(CartItemModel item, ValueNotifier<int> cartitemCount) async {
    if (item.quantity > 1) {
      final success = await updateItemQuantity(item, item.quantity - 1, cartitemCount);
      if (!success) {
        // Rollback if failed
        item.quantity = item.quantity;
      }
    }
  }

  void updateItemSelection(CartItemModel item, bool? value) {
    item.isSelect = value ?? false;
    isSelectAll = cartItems.every((item) => item.isSelect);
    notifyListeners();
  }

  @override
  void dispose() {
    addressController.dispose();
    fullnameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }
}
