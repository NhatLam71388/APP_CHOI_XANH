import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/product_model.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/services/cart_service.dart';
import 'package:flutter_application_1/services/carthistory_service.dart';
import 'package:flutter_application_1/view/home/homepage.dart';
import 'package:flutter_application_1/view/until/until.dart';

double calculateTotalPrice(List<CartItemModel> cartItems) {
  double total = 0;
  for (var item in cartItems) {
    if (item.isSelect) {
      total += item.price * item.quantity;
    }
  }
  return total;
}

Future<void> handleDatHang({
  required BuildContext context,
  required String userId,
  required String customerName,
  required String email,
  required String tel,
  required String address,
  required double totalPrice,
  String note = '',
  required List<CartItemModel> cartItems,
  required Future<void> Function() onCartReload,
  required ValueNotifier<int> cartitemCount,
  required String moduletype,
}) async {
  try {
    final selectedItems = cartItems.where((item) => item.isSelect).toList();

    if (selectedItems.isEmpty) {
      showToast('Vui lòng chọn ít nhất 1 sản phẩm để đặt hàng',
          backgroundColor: Colors.orange);
      return;
    }

    print('Đặt hàng với thông tin:');
    print('CustomerName: $customerName');
    print('Email: $email');
    print('Tel: $tel');
    print('Address: $address');
    print('TotalPrice: $totalPrice');
    print('Selected Items: ${selectedItems.map((item) => 'ID: ${item.id}, Quantity: ${item.quantity}').toList()}');

    // Gọi API đặt hàng
    await APICartService.datHang(
      customerName: customerName,
      email: email,
      tel: tel,
      address: address,
      totalPrice: totalPrice,
      items: selectedItems,
      moduletype: moduletype,
    );

    // Xóa từng item khỏi giỏ
    for (var item in selectedItems) {
      await APICartService.removeCartItem(
        cartitemCount: cartitemCount,
        emailAddress: userId,
        productId: item.id.toString(),
      );
    }
    final total = await APICartService.getCartItemCountFromApi(Global.email);
    cartitemCount.value = total;

    await onCartReload();
    Navigator.pop(context);
    showToast('Cám ơn bạn đã đặt hàng!', backgroundColor: Colors.green);
  } catch (e) {
    print("❌ Lỗi khi đặt hàng: $e");
    showToast('Đặt hàng thất bại: $e', backgroundColor: Colors.red);
  }
}