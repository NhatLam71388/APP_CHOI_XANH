import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/custom_snackbar.dart';
import 'package:flutter_application_1/widgets/until.dart';
import 'package:animate_do/animate_do.dart'; // Thư viện animation

class CartBottomBar extends StatelessWidget {
  final double tongThanhToan;
  final VoidCallback onOrderPressed;
  final bool isOrderEnabled;

  const CartBottomBar({
    super.key,
    required this.tongThanhToan,
    required this.onOrderPressed,
    this.isOrderEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
        child: Row(
          children: [
            // Tổng tiền hàng section
            Expanded(
              flex: 3,
              child: FadeInLeft(
                duration: const Duration(milliseconds: 500),
                                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xff0066FF).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isOrderEnabled
                          ? const Color(0xff0066FF).withOpacity(0.3)
                          : const Color(0xff99bbff).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 16,
                            color: isOrderEnabled
                                ? const Color(0xff0066FF)
                                : const Color(0xff99bbff),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tổng tiền hàng',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOrderEnabled
                                  ? const Color(0xff0066FF)
                                  : const Color(0xff99bbff),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                                             const SizedBox(height: 4),
                      Text(
                        '${formatCurrency(tongThanhToan)}đ',
                        style: TextStyle(
                          fontSize: 18,
                          color: isOrderEnabled ? Colors.red[700] : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Đặt hàng button
            Expanded(
              flex: 2,
              child: BounceInRight(
                duration: const Duration(milliseconds: 500),
                                 child: Container(
                   height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: isOrderEnabled
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xff0066FF),
                              Color(0xff0052CC),
                            ],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xff99bbff),
                              const Color(0xff99bbff).withOpacity(0.7),
                            ],
                          ),
                    boxShadow: isOrderEnabled
                        ? [
                            BoxShadow(
                              color: const Color(0xff0066FF).withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (isOrderEnabled) {
                        onOrderPressed();
                      } else {
                        CustomSnackBar.showWarning(context, message: 'Vui lòng chọn ít nhất 1 sản phẩm');
                      }
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
                          child: Icon(
                            isOrderEnabled ? Icons.shopping_cart_checkout : Icons.shopping_cart_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isOrderEnabled ? 1.0 : 0.8,
                          child: Text(
                            'Đặt hàng',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
