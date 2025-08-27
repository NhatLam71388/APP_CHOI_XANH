import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/product_model.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/services/cart_service.dart';
import 'package:flutter_application_1/screens/cart/component/order_widget.dart';
import 'package:flutter_application_1/screens/cart/component/cart_item.dart';
import 'package:flutter_application_1/screens/cart/component/form_order.dart';
import 'package:flutter_application_1/screens/cart/component/cart_ulti.dart';
import 'package:flutter_application_1/widgets/until.dart';
import 'package:flutter_application_1/widgets/cart_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/Controller/cart.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../Constant/app_colors.dart';
import '../../Controller/home.dart';
import '../../widgets/empty_state_widget.dart';

class PageCart extends StatefulWidget {
  final Function(CartItemModel product) onProductTap;
  final ValueNotifier<int> cartitemCount;
  const PageCart(
      {super.key, required this.onProductTap, required this.cartitemCount});

  @override
  State<PageCart> createState() => PageCartState();
}

class PageCartState extends State<PageCart> {
  late CartController cartController;

  @override
  void initState() {
    super.initState();
    cartController = CartController();
    cartController.init(widget.cartitemCount);
  }

  @override
  void dispose() {
    cartController.dispose();
    super.dispose();
  }

  // Method để tương thích với allpage.dart
  Future<void> chonNhieuVaMoBottomSheet(List<int> productIdsVuaThem) async {
    await cartController.chonNhieuVaMoBottomSheet(productIdsVuaThem, widget.cartitemCount);
  }

  // Method để tương thích với layout_controller.dart
  Future<void> loadCartItems() async {
    await cartController.loadCartItems(widget.cartitemCount);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: cartController,
      child: Consumer<CartController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Scaffold(
              body: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xff0066FF),
                  )),
            );
          }

          return Scaffold(
              backgroundColor: AppColors.backgroundColor,
              body: RefreshIndicator(
                color: Color(0xff0066FF),
                onRefresh: () => controller.loadCartItems(widget.cartitemCount),
                child: SafeArea(
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          if (controller.cartItems.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.all(20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF198754),
                                    const Color(0xFF20C997),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF198754).withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => controller.toggleSelectAll(!controller.isSelectAll),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Icon(
                                          controller.isSelectAll 
                                            ? Icons.check_box 
                                            : Icons.check_box_outline_blank,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              controller.isSelectAll ? 'Đã chọn tất cả' : 'Chọn tất cả',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${controller.cartItems.length} sản phẩm trong giỏ hàng',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.white.withOpacity(0.9),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          Expanded(
                            child: controller.cartItems.isEmpty
                                ? const EmptyStateWidget(
                              title: 'Giỏ hàng trống',
                              subtitle: 'Hãy thêm sản phẩm vào giỏ hàng \nđể xem chúng ở đây',
                              icon: Icons.shopping_cart_outlined,
                              color: Color(0xFF198754),
                            )
                                : AnimationLimiter(
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10).copyWith(bottom: 70),
                                      itemCount: controller.cartItems.length + 1,
                                      itemBuilder: (context, index) {
                                        if (index == controller.cartItems.length) {
                                          return AnimationConfiguration.staggeredList(
                                            position: index,
                                            duration: const Duration(milliseconds: 600),
                                            child: SlideAnimation(
                                              verticalOffset: 50.0,
                                              child: FadeInAnimation(
                                                child: Container(
                                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                                  padding: const EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(20),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(0xFF198754).withOpacity(0.08),
                                                        blurRadius: 20,
                                                        offset: const Offset(0, 4),
                                                        spreadRadius: 0,
                                                      ),
                                                    ],
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      if (controller.hasSelectedItems) ...[
                                                        buildInfoRow(
                                                            "Tiền đơn hàng",
                                                            formatCurrency(calculateTotalPrice(controller.cartItems).toStringAsFixed(0)) + "₫"),
                                                        const SizedBox(height: 8),
                                                        buildInfoRow("Phí vận chuyển", '${formatCurrency(controller.phiVanChuyen)}₫'),
                                                        const Divider(height: 20, color: Colors.black12),
                                                        buildInfoRow("Tổng thanh toán", '${formatCurrency(controller.tongThanhToan)}₫', isTotal: true),
                                                      ]
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        } else {
                                          final item = controller.cartItems[index];
                                          return AnimationConfiguration.staggeredList(
                                            position: index,
                                            duration: const Duration(milliseconds: 600),
                                            child: SlideAnimation(
                                              verticalOffset: 50.0,
                                              child: FadeInAnimation(
                                                child: ItemCart(
                                                  cartitemCount: widget.cartitemCount,
                                                  userId: Global.email,
                                                  item: item,
                                                  isSelected: item.isSelect,
                                                  onTap: () {
                                                    widget.onProductTap(item);
                                                  },
                                                  onSelectedChanged: (value) {
                                                    controller.updateItemSelection(item, value);
                                                  },
                                                  onIncrease: () async {
                                                    // Chỉ cập nhật local state, không reload giỏ hàng
                                                    item.quantity++;
                                                    controller.notifyListeners();
                                                  },
                                                  onDecrease: () async {
                                                    if (item.quantity > 1) {
                                                      // Chỉ cập nhật local state, không reload giỏ hàng
                                                      item.quantity--;
                                                      controller.notifyListeners();
                                                    }
                                                  },
                                                  OnChanged: () async {
                                                    // Không cần reload giỏ hàng khi chỉ thay đổi số lượng
                                                    // await controller.loadCartItems(widget.cartitemCount);
                                                  },
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: CartBottomBar(
                          isOrderEnabled: controller.hasSelectedItems,
                          tongThanhToan: controller.tongThanhToan,
                          onOrderPressed: () async {
                            showModalBottomSheet(
                              isScrollControlled: true,
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (BuildContext context) {
                                return OrderConfirmationSheet(
                                  parentContext: context,
                                  addressController: controller.addressController,
                                  fullnameController: controller.fullnameController,
                                  phoneController: controller.phoneController,
                                  emailController: controller.emailController,
                                  tongThanhToan: controller.tongThanhToan,
                                  onConfirm: () async {
                                    await showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (dialogContext) {
                                        Future.delayed(Duration.zero, () async {
                                          try {
                                            await handleDatHang(
                                              moduletype: controller.cartItems
                                                  .firstWhere((item) => item.isSelect)
                                                  .moduleType,
                                              totalPrice: controller.tongThanhToan,
                                              address: controller.addressController.text,
                                              cartitemCount: widget.cartitemCount,
                                              context: context,
                                              userId: Global.email,
                                              customerName: controller.fullnameController.text,
                                              email: controller.emailController.text,
                                              tel: controller.phoneController.text,
                                              cartItems: controller.cartItems,
                                              onCartReload: () => controller.loadCartItems(widget.cartitemCount),
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
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ));
        },
      ),
    );
  }
}