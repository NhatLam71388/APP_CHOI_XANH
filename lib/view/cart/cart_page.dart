import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/product_model.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/services/cart_service.dart';
import 'package:flutter_application_1/view/allpage.dart';
import 'package:flutter_application_1/view/cart/bottom_bar.dart';
import 'package:flutter_application_1/view/cart/cart_item.dart';
import 'package:flutter_application_1/view/cart/formorder.dart';
import 'package:flutter_application_1/view/home/homepage.dart';
import 'package:flutter_application_1/view/until/cart_ulti.dart';
import 'package:flutter_application_1/view/until/until.dart';
import 'package:flutter_application_1/widgets/cart_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PageCart extends StatefulWidget {
  final Function(CartItemModel product) onProductTap;
  final ValueNotifier<int> cartitemCount;
  const PageCart(
      {super.key, required this.onProductTap, required this.cartitemCount});

  @override
  State<PageCart> createState() => PageCartState();
}

class PageCartState extends State<PageCart> {
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

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await loadCartItems();
    emailController.text = Global.email;
    fullnameController.text = Global.name;
  }

  Future<void> loadCartItems() async {
    try {
      final selectedIds = cartItems
          .where((item) => item.isSelect)
          .map((e) => e.id.toString())
          .toSet();

      final items = await APICartService.fetchCartItemsById(
        emailAddress: Global.email,
        cartitemCount: widget.cartitemCount, // Thêm cartitemCount
        password: Global.pass
      );

      setState(() {
        cartItems = items.map((e) {
          e.isSelect = selectedIds.contains(e.id.toString());
          return e;
        }).toList();

        isSelectAll = cartItems.isNotEmpty && cartItems.every((item) => item.isSelect);
        isLoading = false;
      });
    } catch (e) {
      print('❌ Lỗi khi load cart items: $e');
      setState(() {
        cartItems = [];
        isSelectAll = false;
        isLoading = false;
        widget.cartitemCount.value = 0;
      });
      showToast('Không thể tải giỏ hàng, vui lòng thử lại', backgroundColor: Colors.red);
    }
  }

  Future<void> chonNhieuVaMoBottomSheet(List<int> productIdsVuaThem) async {
    await loadCartItems();
    await Future.delayed(Duration(milliseconds: 100));

    if (productIdsVuaThem.isNotEmpty) {
      setState(() {
        for (var item in cartItems) {
          int? itemId = int.tryParse(item.id.toString());
          item.isSelect = itemId != null && productIdsVuaThem.contains(itemId);
        }
        isSelectAll = cartItems.every((item) => item.isSelect);
      });

      if (mounted && hasSelectedItems) {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (BuildContext context) {
            return OrderConfirmationSheet(
              parentContext: context,
              addressController: addressController,
              fullnameController: fullnameController,
              phoneController: phoneController,
              emailController: emailController,
              tongThanhToan: tongThanhToan,
              onConfirm: () async {
                await showDialog(
                  context: rootContext,
                  barrierDismissible: false,
                  builder: (dialogContext) {
                    Future.delayed(Duration.zero, () async {
                      try {
                        await handleDatHang(
                          moduletype: cartItems
                              .firstWhere((item) => item.isSelect)
                              .moduleType,
                          totalPrice: tongThanhToan,
                          address: addressController.text,
                          cartitemCount: widget.cartitemCount,
                          context: context,
                          userId: Global.email,
                          customerName: fullnameController.text,
                          email: emailController.text,
                          tel: phoneController.text,
                          cartItems: cartItems,
                          onCartReload: loadCartItems,
                        );
                      } catch (e) {
                        showToast('Lỗi khi đặt hàng: $e', backgroundColor: Colors.red);
                      }
                      if (mounted) {
                        Navigator.of(dialogContext, rootNavigator: true).pop();
                      }
                    });

                    return const Dialog(
                      backgroundColor: Colors.black87,
                      insetPadding: EdgeInsets.all(80),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Color(0xff0066FF)),
                            SizedBox(height: 16),
                            Text(
                              "Đang xử lý đơn hàng...",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      }
    }
  }

  void toggleSelectAll(bool? value) {
    setState(() {
      isSelectAll = value ?? false;
      for (var item in cartItems) {
        item.isSelect = isSelectAll;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    rootContext = context;
    if (isLoading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(
              color: Color(0xff0066FF),
            )),
      );
    }

    return Scaffold(
        backgroundColor: Colors.grey[100],
        body: RefreshIndicator(
          color: Color(0xff0066FF),
          onRefresh: loadCartItems,
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    if (cartItems.isNotEmpty)
                      CheckboxListTile(
                        title: const Text('Chọn tất cả'),
                        value: isSelectAll,
                        onChanged: toggleSelectAll,
                        activeColor: const Color(0xff0066FF),
                      ),
                    Expanded(
                      child: cartItems.isEmpty
                          ? const Center(child: Text("Giỏ hàng trống"))
                          : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 70),
                          itemCount: cartItems.length + 1,
                          itemBuilder: (context, index) {
                            if (index == cartItems.length) {
                              return Container(
                                margin:
                                const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.all(16),
                                color: Colors.white,
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    if (hasSelectedItems) ...[
                                      buildInfoRow(
                                          "Tiền đơn hàng",
                                          formatCurrency(
                                              calculateTotalPrice(
                                                  cartItems)
                                                  .toStringAsFixed(0)) +
                                              "₫"),
                                      const SizedBox(height: 8),
                                      buildInfoRow("Phí vận chuyển",
                                          '${formatCurrency(phiVanChuyen)}₫'),
                                      const Divider(
                                          height: 20,
                                          color: Colors.black12),
                                      buildInfoRow("Tổng thanh toán",
                                          '${formatCurrency(tongThanhToan)}₫',
                                          isTotal: true),
                                    ]
                                  ],
                                ),
                              );
                            } else {
                              final item = cartItems[index];
                              return ItemCart(
                                cartitemCount: widget.cartitemCount,
                                userId: Global.email,
                                item: item,
                                isSelected: item.isSelect,
                                onTap: () {
                                  widget.onProductTap(item);
                                },
                                onSelectedChanged: (value) {
                                  setState(() {
                                    item.isSelect = value ?? false;
                                    isSelectAll = cartItems
                                        .every((item) => item.isSelect);
                                  });
                                },
                                onIncrease: () async {
                                  int productId =
                                      int.tryParse(item.id.toString()) ?? 0;
                                  if (productId != 0) {
                                    item.quantity++;
                                    final success = await APICartService
                                        .updateCartItemQuantity(
                                      emailAddress: Global.email,
                                      productId: productId,
                                      newQuantity: item.quantity,
                                    );
                                    if (success) {
                                      setState(() {});
                                    } else {
                                      item.quantity--;
                                      showToast('Cập nhật số lượng thất bại',
                                          backgroundColor: Colors.red);
                                    }
                                  }
                                },
                                onDecrease: () async {
                                  if (item.quantity > 1) {
                                    int productId =
                                        int.tryParse(item.id.toString()) ??
                                            0;
                                    if (productId != 0) {
                                      item.quantity--;
                                      final success = await APICartService
                                          .updateCartItemQuantity(
                                        emailAddress: Global.email,
                                        productId: productId,
                                        newQuantity: item.quantity,
                                      );
                                      if (success) {
                                        setState(() {});
                                      } else {
                                        item.quantity++;
                                        showToast(
                                            'Cập nhật số lượng thất bại',
                                            backgroundColor: Colors.red);
                                      }
                                    }
                                  }
                                },
                                OnChanged: () async {
                                  await loadCartItems();
                                },
                              );
                            }
                          }),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CartBottomBar(
                    isOrderEnabled: hasSelectedItems,
                    tongThanhToan: tongThanhToan,
                    onOrderPressed: () async {
                      showModalBottomSheet(
                        isScrollControlled: true,
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (BuildContext context) {
                          return OrderConfirmationSheet(
                            parentContext: rootContext,
                            addressController: addressController,
                            fullnameController: fullnameController,
                            phoneController: phoneController,
                            emailController: emailController,
                            tongThanhToan: tongThanhToan,
                            onConfirm: () async {
                              await showDialog(
                                context: rootContext,
                                barrierDismissible: false,
                                builder: (dialogContext) {
                                  Future.delayed(Duration.zero, () async {
                                    try {
                                      await handleDatHang(
                                        moduletype: cartItems
                                            .firstWhere((item) => item.isSelect)
                                            .moduleType,
                                        totalPrice: tongThanhToan,
                                        address: addressController.text,
                                        cartitemCount: widget.cartitemCount,
                                        context: context,
                                        userId: Global.email,
                                        customerName: fullnameController.text,
                                        email: emailController.text,
                                        tel: phoneController.text,
                                        cartItems: cartItems,
                                        onCartReload: loadCartItems,
                                      );
                                    } catch (e) {
                                      showToast('Lỗi khi đặt hàng: $e',
                                          backgroundColor: Colors.red);
                                    }
                                    if (mounted) {
                                      Navigator.of(dialogContext,
                                          rootNavigator: true)
                                          .pop();
                                    }
                                  });
                                  return const Dialog(
                                    backgroundColor: Colors.black87,
                                    insetPadding: EdgeInsets.all(80),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(
                                              color: Color(0xff0066FF)),
                                          SizedBox(height: 16),
                                          Text(
                                            "Đang xử lý đơn hàng...",
                                            style:
                                            TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}