import 'package:flutter_application_1/models/product_model.dart';

class OrderModel {
  final String id;
  final String customerName;
  final String email;
  final String tel;
  final String address;
  final String? note;
  final double totalPrice;
  final String date;
  final List<CartItemModel> items;
  final String status;

  OrderModel({
    required this.id,
    required this.customerName,
    required this.email,
    required this.tel,
    required this.address,
    this.note,
    required this.totalPrice,
    required this.date,
    required this.items,
    this.status = ''
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'].toString(),
      customerName: json['customer_name'] ?? '',
      email: json['email'] ?? '',
      tel: json['tel'] ?? '',
      address: json['address'] ?? '',
      status: json['status'] ?? '',
      note: json['note'],
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0,
      date: json['date'] ?? '',
      items: (json['items'] as List<dynamic>)
          .map((e) => CartItemModel.fromJson(e))
          .toList(),
    );
  }
}
