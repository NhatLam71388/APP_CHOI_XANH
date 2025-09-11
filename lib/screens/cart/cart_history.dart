import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/order_history_model.dart';
import 'package:flutter_application_1/models/product_model.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/services/cart_service.dart';
import 'package:flutter_application_1/services/carthistory_service.dart';
import 'package:flutter_application_1/widgets/until.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Controller/home.dart';
import 'cart_history_item.dart';

class CarthistoryPage extends StatefulWidget {
  final Function(dynamic product) onProductTap;
  final void Function(List<int>? productIds) gotoCart;
  final ValueNotifier<int> cartitemCount;

  const CarthistoryPage({
    super.key,
    required this.onProductTap,
    required this.cartitemCount,
    required this.gotoCart,
  });

  @override
  State<CarthistoryPage> createState() => CarthistoryPageState();
}

class CarthistoryPageState extends State<CarthistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<OrderModel> orderHistory = [];

  bool _isCanceling = false;
  void _startLoading() => setState(() => _isCanceling = true);
  void _stopLoading() => setState(() => _isCanceling = false);

  final List<String> _statusLabels = [
    'Chờ xác nhận',
    'Đã xác nhận',
    'Đang vận chuyển',
    'Đã giao',
  ];

  final List<String> _statusKeys = [
    '0',
    '1',
    '2',
    '3',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusLabels.length, vsync: this);

    // Gọi load data ban đầu
    loadOrderHistory();

    // Gọi lại load mỗi khi đổi tab
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // cho rebuild lại theo tab mới
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadOrderHistory() async {
    // try {
    //   final result =
    //       await APICarthistoryService.fetchOrderHistory(Global.email);
    //   setState(() {
    //     orderHistory = result;
    //   });
    // } catch (e) {
    //   print('❌ Lỗi load lịch sử: $e');
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // TabBar chính
            Material(
              color: Colors.white,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  labelColor: Color(0xff0066FF),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(0xff0066FF),
                  labelStyle: TextStyle(fontWeight: FontWeight.w600),
                  tabs: _statusLabels.map((label) => Tab(text: label)).toList(),
                ),
              ),
            ),

            // Nội dung có thể vuốt
            Expanded(
              child: FutureBuilder<List<OrderModel>>(
                future: Future.value(orderHistory),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final orders = snapshot.data ?? [];

                  final pendingOrders = orders
                      .where((order) => (order.status ?? '') == '0')
                      .toList();
                  final confirmedOrders = orders
                      .where((order) => (order.status ?? '') == '1')
                      .toList();
                  final shippingOrders = orders
                      .where((order) => (order.status ?? '') == '2')
                      .toList();
                  final deliveredOrders = orders
                      .where((order) => (order.status ?? '') == '3')
                      .toList();

                  return TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildOrderList(
                          pendingOrders, Colors.amber, 'Chờ xác nhận'),
                      _buildOrderList(
                          confirmedOrders, Colors.green, 'Đã xác nhận'),
                      _buildOrderList(
                          shippingOrders, Colors.blue, 'Đang vận chuyển'),
                      _buildOrderList(deliveredOrders, Colors.teal, 'Đã giao'),
                    ],
                  );
                },
              ),
            ),

            // Loading overlay
            if (_isCanceling)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xff0066FF),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders, Color color, String title) {
    return RefreshIndicator(
        onRefresh: loadOrderHistory,
        color: Colors.blue,
        backgroundColor: Colors.white,
        child: orders.isNotEmpty
            ? ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return HistoryCard(
                    startLoading: _startLoading,
                    stopLoading: _stopLoading,
                    status: order.status,
                    orderId: order.id.toString(),
                    date: order.date,
                    totalPrice: order.totalPrice,
                    items: order.items,
                    onTap: (item) => widget.onProductTap(item),
                    onReorder: (List<CartItemModel> items) async {
                      bool success = true; // Thêm biến để trả về trạng thái
                      String? errorMessage;

                      if (order.status == '3') {
                        _startLoading();
                        List<int> productIds = []; // Lưu danh sách productId
                        for (var item in items) {
                          final productId = int.tryParse(item.id) ?? 0;
                          if (productId == 0) {
                            success = false;
                            errorMessage =
                                'ID sản phẩm không hợp lệ: ${item.id}';
                            break;
                          }
                          final error = await APICartService.addToCart(
                            context: context,
                            moduleType: 'sanpham',
                            emailAddress: Global.email,
                            password: Global.pass,
                            productId: productId,
                            cartitemCount: widget.cartitemCount,
                            quantity: item.quantity ?? 1,
                          );

                          if (error != null) {
                            success = false;
                            errorMessage = error as String?;
                            break;
                          }

                          productIds.add(productId);
                        }

                        _stopLoading();

                        if (success) {
                          widget.gotoCart(
                            productIds.isNotEmpty ? productIds : null,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(errorMessage ??
                                    'Lỗi khi thêm vào giỏ hàng')),
                          );
                        }
                      } else {
                        _startLoading();
                        final error = await APICartService.cancelOrder(
                          emailAddress: Global.email,
                          orderId: order.id,
                        );
                        _stopLoading();

                        if (error == null) {
                          loadOrderHistory();
                        } else {
                          success = false;
                          errorMessage = error;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error)),
                          );
                        }
                      }

                      return success;
                    },
                  );
                },
              )
            : Center(
                child: Text(
                  "Không có đơn hàng nào!",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ));
  }
}
