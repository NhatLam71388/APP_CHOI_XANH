import 'package:flutter/material.dart';
import 'package:flutter_application_1/view/until/until.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: FadeInLeft(
              duration: const Duration(milliseconds: 500),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isOrderEnabled
                          ? const Color(0xff0066FF)
                          : const Color(0xff99bbff),
                      width: 6,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Tổng tiền hàng',
                      style: TextStyle(fontSize: 12, color: Color(0xff0066FF)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatCurrency(tongThanhToan)}đ',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: BounceInRight(
              duration: const Duration(milliseconds: 500),
              child: ElevatedButton(
                onPressed: () {
                  if (isOrderEnabled) {
                    onOrderPressed();
                  } else {
                    showToast(
                      'Vui lòng chọn ít nhất 1 sản phẩm',
                      backgroundColor: Colors.red,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOrderEnabled
                      ? const Color(0xff0066FF)
                      : const Color(0xff99bbff),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: isOrderEnabled ? 4 : 0,
                  shadowColor: isOrderEnabled
                      ? const Color(0xff0066FF).withOpacity(0.4)
                      : Colors.transparent,
                ),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isOrderEnabled ? 1.0 : 0.7,
                  child: const Text(
                    'Đặt hàng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
