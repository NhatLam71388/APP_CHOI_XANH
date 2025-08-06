import 'dart:convert';
import 'package:flutter_application_1/models/order_history_model.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class APICarthistoryService {
  static Future<List<OrderModel>> fetchOrderHistory(String email) async {
    final url = Uri.parse('${APIService.baseUrl}/api/order.history.php');

    try {
      final response = await http.post(
        url,
        headers: {'Accept': 'application/json'},
        body: {'email': email},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> orders = data['orders'];
        return orders.map((e) => OrderModel.fromJson(e)).toList();
      } else {
        print('Lỗi phản hồi: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Lỗi khi lấy lịch sử: $e');
      return [];
    }
  }

  static Future<void> clearOrderHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'favourite_items_$userId';
    await prefs.remove(key);
    print('da xoa fv');
  }
}
