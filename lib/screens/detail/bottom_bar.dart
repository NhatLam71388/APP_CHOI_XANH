import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/services/cart_service.dart';
import 'package:flutter_application_1/widgets/until.dart';

import '../../Controller/home.dart';

class BottomActionBar extends StatelessWidget {
  final int productId;
  final String userId;
  final String passwordHash;
  final String tieude;
  final String gia;
  final String hinhdaidien;
  final ValueNotifier<int> cartitemCount;
  final String moduleType;
  final void Function(int?) gotoCart;

  const BottomActionBar({
    super.key,
    required this.productId,
    required this.userId,
    required this.passwordHash,
    required this.tieude,
    required this.gia,
    required this.hinhdaidien,
    required this.cartitemCount,
    required this.moduleType,
    required this.gotoCart,
  });

  @override
  Widget build(BuildContext context) {
    // Màu xanh lá chủ đạo
    const Color primaryGreen = Color(0xFF2E7D32);
    const Color lightGreen = Color(0xFF4CAF50);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 10,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, -5),
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Thêm vào giỏ hàng button (chỉ icon)
                Container(
                  width: 60,
                  height: 48,
                  decoration: BoxDecoration(
                    color: lightGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      print('emailaddress: ${Global.email}');
                      final result = await APICartService.addToCart(
                        context: context,
                        moduleType: moduleType,
                        emailAddress: Global.email,
                        password: passwordHash,
                        productId: productId,
                        cartitemCount: cartitemCount,
                        quantity: 1,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: primaryGreen,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 24,
                      color: primaryGreen,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Mua ngay button
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryGreen,
                          lightGreen,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        await APICartService.addToCart(
                          context: context,
                          moduleType: moduleType,
                          emailAddress: userId,
                          password: Global.pass,
                          productId: productId as int,
                          cartitemCount: cartitemCount,
                          quantity: 1,
                        );
                        gotoCart(productId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.flash_on,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Mua ngay',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}