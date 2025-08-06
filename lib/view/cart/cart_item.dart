import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/product_model.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/services/cart_service.dart';
import 'package:flutter_application_1/view/home/homepage.dart';
import 'package:flutter_application_1/view/until/until.dart';

class ItemCart extends StatefulWidget {
  final bool isSelected;
  final CartItemModel item;
  final VoidCallback? onTap;
  final ValueChanged<bool?>? onSelectedChanged;
  final ValueNotifier<int> cartitemCount;
  final String userId;
  final VoidCallback? OnChanged;

  const ItemCart({
    super.key,
    required this.isSelected,
    required this.item,
    this.onTap,
    this.onSelectedChanged,
    required this.cartitemCount,
    required this.userId,
    this.OnChanged,
    required Future<Null> Function() onDecrease,
    required Future<Null> Function() onIncrease,
  });

  @override
  State<ItemCart> createState() => _ItemCartState();
}

class _ItemCartState extends State<ItemCart> {
  Future<void> _updateQuantity(int newQuantity) async {
    final success = await APICartService.updateCartItemQuantity(
      emailAddress: widget.userId,
      productId: int.tryParse(widget.item.id.toString()) ?? 0,
      newQuantity: newQuantity,
    );

    if (success) {
      setState(() {
        widget.item.quantity = newQuantity;
      });
      showToast('Cập nhật số lượng thành công', backgroundColor: Colors.green);
    } else {
      showToast('Cập nhật số lượng thất bại', backgroundColor: Colors.red);
    }

    if (widget.OnChanged != null) widget.OnChanged!();

    final total = await APICartService.getCartItemCountFromApi(Global.email);
    widget.cartitemCount.value = total;
  }

  Future<void> _removeItem() async {
    final success = await APICartService.removeCartItem(
      cartitemCount: widget.cartitemCount,
      emailAddress: widget.userId,
      productId: widget.item.id.toString(),
    );

    if (success) {
      showToast('Đã xóa sản phẩm khỏi giỏ hàng', backgroundColor: Colors.green);
      if (widget.OnChanged != null) widget.OnChanged!();
    } else {
      showToast('Xóa sản phẩm thất bại', backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Material(
          elevation: 0,
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: widget.isSelected,
                  onChanged: widget.onSelectedChanged,
                  activeColor: const Color(0xff0066FF),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12, width: 0.5),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.item.image,
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TIÊU ĐỀ
                      Text(
                        widget.item.name ?? 'Không có tên',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // GIÁ + NÚT TĂNG GIẢM
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${formatCurrency(widget.item.price)}₫',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            height: 26,
                            width: 90,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                InkWell(
                                  onTap: () {
                                    if (widget.item.quantity > 1) {
                                      _updateQuantity(widget.item.quantity - 1);
                                    }
                                  },
                                  child: const Icon(Icons.remove, size: 20, color: Colors.black54),
                                ),
                                Text(
                                  '${widget.item.quantity}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                InkWell(
                                  onTap: () {
                                    _updateQuantity(widget.item.quantity + 1);
                                  },
                                  child: const Icon(Icons.add, size: 20, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // NÚT XÓA SẢN PHẨM
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _removeItem,
                          child: const Text(
                            'Xóa sản phẩm',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13.5,
                            ),
                          ),
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
    );
  }
}