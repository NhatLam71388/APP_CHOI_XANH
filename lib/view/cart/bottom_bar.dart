import 'package:flutter/material.dart';
import 'package:flutter_application_1/view/until/until.dart';

class CartBottomBar extends StatelessWidget {
  final double tongThanhToan;
  final VoidCallback onOrderPressed;
  final bool isOrderEnabled;

  const CartBottomBar(
      {super.key,
      required this.tongThanhToan,
      required this.onOrderPressed,
      this.isOrderEnabled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: isOrderEnabled
                            ? const Color(0xff0066FF)
                            : const Color(0xff99bbff),
                        width: 12)),
                color: Colors.white,
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
                      fontSize: 15,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30)),
                  ),
              child: ElevatedButton(
                onPressed: () {
                  if (isOrderEnabled) {
                    onOrderPressed();
                  } else {
                    showToast(
                        'Vui lòng chọn ít nhất 1 sản phẩm',backgroundColor: Colors.red);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOrderEnabled
                      ? const Color(0xff0066FF)
                      : const Color(0xff99bbff), // xanh nhạt khi disable
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero),
                  elevation: 0,
                ),
                child: const Center(
                  child: Text(
                    'Đặt hàng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
