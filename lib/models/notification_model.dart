class NotificationModel {
  final int recordsTotal;
  final int recordsFiltered;
  final List<NotificationData> data;

  NotificationModel({
    required this.recordsTotal,
    required this.recordsFiltered,
    required this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      recordsTotal: json['recordsTotal'] ?? 0,
      recordsFiltered: json['recordsFiltered'] ?? 0,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => NotificationData.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class NotificationData {
  final String? id;
  final String? title;
  final String? content;
  final String? date;
  final String? type;
  final bool? isRead;
  final String? priority;

  NotificationData({
    this.id,
    this.title,
    this.content,
    this.date,
    this.type,
    this.isRead,
    this.priority,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      id: json['id']?.toString(),
      title: json['title']?.toString(),
      content: json['content']?.toString(),
      date: json['date']?.toString(),
      type: json['type']?.toString(),
      isRead: json['isRead'] == 'true' || json['isRead'] == true,
      priority: json['priority']?.toString(),
    );
  }
}
