import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/notification_model.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/widgets/empty_state_widget.dart';
import 'package:flutter_application_1/widgets/until.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/api_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => NotificationPageState();
}

class NotificationPageState extends State<NotificationPage> {
  NotificationModel? notificationData;
  bool isLoading = true;
  bool isError = false;
  String errorMessage = '';
  int currentPage = 1;
  bool hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        setState(() {
          isLoading = true;
          isError = false;
          currentPage = 1;
          hasMoreData = true;
        });
      }

      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('emailAddress') ?? '';
      final password = prefs.getString('passWord') ?? '';

      if (email.isEmpty || password.isEmpty) {
        throw Exception('Thông tin đăng nhập không đầy đủ');
      }

      final md5Password = AuthService.generateMd5(password);
      final url = Uri.parse(
        '${APIService.baseUrl}/ww1/member.1/thongbaocongviec.asp?userid=$email&pass=$md5Password&pageid=$currentPage'
      );

      final response = await http.get(url).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        if (data.isNotEmpty) {
          final newData = NotificationModel.fromJson(data[0]);
          
          setState(() {
            if (isRefresh || notificationData == null) {
              notificationData = newData;
            } else {
              // Append new data for pagination
              notificationData = NotificationModel(
                recordsTotal: newData.recordsTotal,
                recordsFiltered: newData.recordsFiltered,
                data: [...notificationData!.data, ...newData.data],
              );
            }
            
            hasMoreData = newData.data.isNotEmpty;
            isLoading = false;
          });
        } else {
          setState(() {
            notificationData = NotificationModel(recordsTotal: 0, recordsFiltered: 0, data: []);
            isLoading = false;
            hasMoreData = false;
          });
        }
      } else {
        throw Exception('Lỗi kết nối: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
        errorMessage = e.toString();
      });
      print('Error loading notifications: $e');
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (!hasMoreData || isLoading) return;
    
    setState(() {
      currentPage++;
    });
    
    await _loadNotifications();
  }

  Widget _buildNotificationItem(NotificationData notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead == true ? Colors.grey[200]! : const Color(0xff0066FF).withOpacity(0.3),
          width: notification.isRead == true ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: notification.isRead == true 
                      ? Colors.grey[100] 
                      : const Color(0xff0066FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: notification.isRead == true 
                      ? Colors.grey[600] 
                      : const Color(0xff0066FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title ?? 'Không có tiêu đề',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: notification.isRead == true ? FontWeight.w500 : FontWeight.w600,
                        color: notification.isRead == true ? Colors.grey[700] : Colors.black87,
                      ),
                    ),
                    if (notification.date != null)
                      Text(
                        _formatDate(notification.date!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
              if (notification.isRead != true)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xff0066FF),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          if (notification.content != null && notification.content!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              notification.content!,
              style: TextStyle(
                fontSize: 14,
                color: notification.isRead == true ? Colors.grey[600] : Colors.black87,
                height: 1.4,
              ),
            ),
          ],
          if (notification.priority != null && notification.priority!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPriorityColor(notification.priority!).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getPriorityColor(notification.priority!).withOpacity(0.3),
                ),
              ),
              child: Text(
                _getPriorityText(notification.priority!),
                style: TextStyle(
                  fontSize: 10,
                  color: _getPriorityColor(notification.priority!),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'order':
        return Icons.shopping_cart;
      case 'promotion':
        return Icons.local_offer;
      case 'system':
        return Icons.system_update;
      case 'security':
        return Icons.security;
      default:
        return Icons.notifications;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'Cao';
      case 'medium':
        return 'Trung bình';
      case 'low':
        return 'Thấp';
      default:
        return 'Thông thường';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes} phút trước';
        } else {
          return '${difference.inHours} giờ trước';
        }
      } else if (difference.inDays == 1) {
        return 'Hôm qua';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ngày trước';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        color: const Color(0xff0066FF),
        onRefresh: () => _loadNotifications(isRefresh: true),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xff0066FF),
                ),
              )
            : isError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Có lỗi xảy ra',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          errorMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _loadNotifications(isRefresh: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff0066FF),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : notificationData == null || notificationData!.data.isEmpty
                    ? EmptyStateWidget(title: 'Không có thông báo', subtitle: 'Bạn sẽ nhận được thông báo\nkhi có cập nhật mới', icon: Icons.notifications_none)
                    : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                            _loadMoreNotifications();
                          }
                          return true;
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: notificationData!.data.length + (hasMoreData ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == notificationData!.data.length) {
                              return hasMoreData
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(
                                          color: Color(0xff0066FF),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            }
                            return _buildNotificationItem(notificationData!.data[index]);
                          },
                        ),
                      ),
      ),
    );
  }
}
