import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/services/cart_service.dart';
import 'package:flutter_application_1/view/until/until.dart';

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
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                // Thêm vào giỏ hàng button (chỉ icon)
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xff0066FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      print('emailaddress: ${Global.email}');
                      final result = await APICartService.addToCart(
                        moduleType: moduleType,
                        emailAddress: Global.email,
                        password: passwordHash,
                        productId: productId,
                        cartitemCount: cartitemCount,
                        quantity: 1,
                      );

                      if (result == null) {
                        showToast('Thêm vào giỏ hàng thành công!');
                      } else {
                        showToast(result as String, backgroundColor: Colors.red);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: const Color(0xff0066FF),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(45),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 32,
                      color: Color(0xff0066FF),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Mua ngay button
                Expanded(
                  child: Container(
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xff0066FF),
                          Color(0xff0052CC),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff0066FF).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        await APICartService.addToCart(
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
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.flash_on,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Mua ngay',
                            style: TextStyle(
                              fontSize: 16,
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
