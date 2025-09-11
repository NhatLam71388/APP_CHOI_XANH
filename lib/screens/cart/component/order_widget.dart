import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/custom_snackbar.dart';
import 'package:flutter_application_1/widgets/until.dart';

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
    // Màu xanh lá chủ đạo
    const Color primaryGreen = Color(0xFF2E7D32);
    const Color lightGreen = Color(0xFF4CAF50);
    const Color disabledGreen = Color(0xFF81C784); // Màu xanh nhạt khi không khả dụng

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        child: Row(
          children: [
            // Tổng tiền hàng section
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: lightGreen.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOrderEnabled
                        ? lightGreen.withOpacity(0.3)
                        : disabledGreen.withOpacity(0.3),
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
                          size: 14,
                          color: isOrderEnabled ? primaryGreen : disabledGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tổng tiền hàng',
                          style: TextStyle(
                            fontSize: 11,
                            color: isOrderEnabled ? primaryGreen : disabledGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatCurrency(tongThanhToan)}đ',
                      style: TextStyle(
                        fontSize: 16,
                        color: isOrderEnabled ? Colors.red[700] : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Đặt hàng button
            Expanded(
              flex: 2,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: isOrderEnabled
                      ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryGreen,
                      lightGreen,
                    ],
                  )
                      : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      disabledGreen,
                      disabledGreen.withOpacity(0.7),
                    ],
                  ),
                  boxShadow: isOrderEnabled
                      ? [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
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
                        child: Icon(
                          isOrderEnabled ? Icons.shopping_cart_checkout : Icons.shopping_cart_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Đặt hàng',
                        style: const TextStyle(
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
    );
  }
}