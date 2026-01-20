/// Model class for notification data from API
class NotificationModel {
  final String id;
  final String type;
  final String subject;
  final String message;
  final String entityType;
  final String entityId;
  final String category;
  final String priority;
  final bool isRead;
  final String? readAt;
  final String createdAt;
  final NotificationMetadata? metadata;

  NotificationModel({
    required this.id,
    required this.type,
    required this.subject,
    required this.message,
    required this.entityType,
    required this.entityId,
    required this.category,
    required this.priority,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    this.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      entityType: json['entityType'] ?? '',
      entityId: json['entityId'] ?? '',
      category: json['category'] ?? '',
      priority: json['priority'] ?? '',
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'],
      createdAt: json['createdAt'] ?? '',
      metadata: json['metadata'] != null
          ? NotificationMetadata.fromJson(json['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'subject': subject,
      'message': message,
      'entityType': entityType,
      'entityId': entityId,
      'category': category,
      'priority': priority,
      'isRead': isRead,
      'readAt': readAt,
      'createdAt': createdAt,
      'metadata': metadata?.toJson(),
    };
  }

  /// Format time ago from createdAt
  String get timeAgo {
    try {
      final createdAtDate = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(createdAtDate);

      if (difference.inDays > 0) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }
}

class NotificationMetadata {
  final String? actionUrl;
  final String? imageUrl;
  final String? icon;
  final Map<String, dynamic>? data;

  NotificationMetadata({
    this.actionUrl,
    this.imageUrl,
    this.icon,
    this.data,
  });

  factory NotificationMetadata.fromJson(Map<String, dynamic> json) {
    return NotificationMetadata(
      actionUrl: json['actionUrl'],
      imageUrl: json['imageUrl'],
      icon: json['icon'],
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'actionUrl': actionUrl,
      'imageUrl': imageUrl,
      'icon': icon,
      'data': data,
    };
  }
}

/// Notification counts from API
class NotificationCounts {
  final int allCount;
  final int unreadCount;
  final int allNewCount;
  final int allOlderCount;
  final int unreadNewCount;
  final int unreadOlderCount;

  NotificationCounts({
    required this.allCount,
    required this.unreadCount,
    required this.allNewCount,
    required this.allOlderCount,
    required this.unreadNewCount,
    required this.unreadOlderCount,
  });

  factory NotificationCounts.fromJson(Map<String, dynamic> json) {
    return NotificationCounts(
      allCount: json['allCount'] ?? 0,
      unreadCount: json['unreadCount'] ?? 0,
      allNewCount: json['allNewCount'] ?? 0,
      allOlderCount: json['allOlderCount'] ?? 0,
      unreadNewCount: json['unreadNewCount'] ?? 0,
      unreadOlderCount: json['unreadOlderCount'] ?? 0,
    );
  }
}

/// Notification pagination info
class NotificationPagination {
  final bool hasMore;
  final String? nextCursor;
  final int limit;

  NotificationPagination({
    required this.hasMore,
    this.nextCursor,
    required this.limit,
  });

  factory NotificationPagination.fromJson(Map<String, dynamic> json) {
    return NotificationPagination(
      hasMore: json['hasMore'] ?? false,
      nextCursor: json['nextCursor'],
      limit: json['limit'] ?? 20,
    );
  }
}


