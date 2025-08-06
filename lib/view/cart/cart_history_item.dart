import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/product_model.dart';
import 'package:flutter_application_1/view/until/until.dart';
import 'package:intl/intl.dart';

class HistoryCard extends StatefulWidget {
  final String orderId;
  final String date;
  final double totalPrice;
  final String status;
  final List<CartItemModel> items;
  final Function(List<CartItemModel> items) onReorder;
  final Function(CartItemModel item) onTap;
  final VoidCallback startLoading;
  final VoidCallback stopLoading;

  const HistoryCard(
      {super.key,
      required this.orderId,
      required this.date,
      required this.totalPrice,
      required this.status,
      required this.items,
      required this.onReorder,
      required this.onTap,
      required this.startLoading,
      required this.stopLoading});

  @override
  State<HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<HistoryCard> {
  String _formatDate(String rawDate) {
    try {
      final parsed = DateTime.parse(rawDate);
      return DateFormat('M/d/y h:mm:ss').format(parsed);
    } catch (e) {
      return rawDate;
    }
  }

  void _confirmCancel(BuildContext context, List<CartItemModel> items) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 4, // Thêm đổ bóng nhẹ
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors
                      .amber.shade700, // Thay đỏ bằng vàng để tạo điểm nhấn
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bạn chắc chắn muốn hủy đơn?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Roboto', // Font hiện đại
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sau khi hủy, đơn hàng này sẽ không thể khôi phục.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Không',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          widget.startLoading();
                          final success = await widget.onReorder(items);
                          widget.stopLoading();

                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    const Text('Hủy đơn không thành công.'),
                                backgroundColor: Colors.red, // Đồng nhất màu
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shadowColor: Colors.black26, // Thêm đổ bóng
                          elevation: 2,
                        ),
                        child: const Text(
                          'Hủy đơn',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mã đơn: #${widget.orderId}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Ngày đặt: ${_formatDate(widget.date)}',
                    style: const TextStyle(fontSize: 13, color: Colors.black38),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const SizedBox(height: 10),
              ...widget.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: InkWell(
                    onTap: () => widget.onTap?.call(item),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.black12, width: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                item.image,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${formatCurrency(item.price)}₫',
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 14),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Row(
                                children: [
                                  Text(
                                    'x${item.quantity}',
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.black45),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ))),
              Row(
                children: [
                  Spacer(),
                  Text(
                    'Tổng: ${formatCurrency(widget.totalPrice)}₫',
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Row(
                children: [
                  Spacer(),
                  widget.status == '3'
                      ? TextButton(
                          onPressed: () => widget.onReorder(widget.items),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xff0066FF),
                            minimumSize: const Size(70, 28),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 8),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(
                                  color: Color(0xff0055dd), width: 0.5),
                            ),
                          ),
                          child: const Text(
                            'Mua lại',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        )
                      : TextButton(
                          onPressed: (widget.status == '1' ||
                                  widget.status == '2')
                              ? null 
                              : () => _confirmCancel(context, widget.items),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            minimumSize: const Size(70, 28),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 8),
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(
                                  color: Colors.black38, width: 0.5),
                            ),
                          ),
                          child: const Text(
                            'Hủy đơn hàng',
                            style: TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w500),
                          ),
                        ),
                ],
              )
            ],
          ),
        ));
  }
}
