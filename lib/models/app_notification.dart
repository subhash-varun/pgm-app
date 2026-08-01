class AppNotification {
  final int id;
  final String title;
  final String body;
  final String type;
  final int senderId;
  final int targetUserId;
  final String targetRole;
  final int targetPropertyId;
  final Map<String, dynamic> payload;
  bool isRead;
  final String createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.senderId,
    required this.targetUserId,
    required this.targetRole,
    required this.targetPropertyId,
    required this.payload,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        type: json['type']?.toString() ?? 'info',
        senderId: (json['senderId'] as num?)?.toInt() ?? 0,
        targetUserId: (json['targetUserId'] as num?)?.toInt() ?? 0,
        targetRole: json['targetRole']?.toString() ?? '',
        targetPropertyId: (json['targetPropertyId'] as num?)?.toInt() ?? 0,
        payload: (json['payload'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v),
            ) ??
            {},
        isRead: json['isRead'] as bool? ?? false,
        createdAt: json['createdAt']?.toString() ?? '',
      );
}

class NotificationPreferences {
  final int id;
  final int userId;
  final bool emailEnabled;
  final bool pushEnabled;
  final bool smsEnabled;
  final bool webEnabled;
  final String createdAt;

  NotificationPreferences({
    required this.id,
    required this.userId,
    required this.emailEnabled,
    required this.pushEnabled,
    required this.smsEnabled,
    required this.webEnabled,
    required this.createdAt,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        id: (json['id'] as num?)?.toInt() ?? 0,
        userId: (json['userId'] as num?)?.toInt() ?? 0,
        emailEnabled: json['emailEnabled'] as bool? ?? false,
        pushEnabled: json['pushEnabled'] as bool? ?? false,
        smsEnabled: json['smsEnabled'] as bool? ?? false,
        webEnabled: json['webEnabled'] as bool? ?? false,
        createdAt: json['createdAt']?.toString() ?? '',
      );

  Map<String, bool> toPartialPayload() => {
        'emailEnabled': emailEnabled,
        'pushEnabled': pushEnabled,
        'smsEnabled': smsEnabled,
        'webEnabled': webEnabled,
      };
}
