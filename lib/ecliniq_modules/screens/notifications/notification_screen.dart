import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

// Enum for notification types
enum NotificationType {
  consultationCompleted,
  bookingConfirmed,
  bookingRequestReceived,
  bookingCancelled,
  paymentReceived,
  prescriptionReady,
  reminder,
  labReportReady,
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String selectedTab = 'All';

  // Sample notification data
  List<NotificationItem> allNotifications = [
    // New Notifications
    NotificationItem(
      type: NotificationType.consultationCompleted,
      title: 'Consultation Completed',
      message: 'Your consultation with ',
      highlightText: 'Dr. Milind Chauhan',
      suffix: ' is Completed',
      time: '3 min ago',
      isRead: false,
      isNew: true,
    ),
    NotificationItem(
      type: NotificationType.bookingConfirmed,
      title: 'Booking Confirmed',
      message: 'Your appointment confirmed with ',
      highlightText: 'Dr. Milind Chauhan.',
      suffix: ' ',
      tokenInfo: 'Token #24. (Est.Time: 10:45AM)',
      time: '3 min ago',
      isRead: false,
      isNew: true,
    ),
    NotificationItem(
      type: NotificationType.bookingRequestReceived,
      title: 'Booking Request Received',
      message: 'Your appointment request with ',
      highlightText: 'Dr. Milind Chauhan',
      suffix: ' has been received.',
      time: '3 min ago',
      isRead: false,
      isNew: true,
    ),
    // Older Notifications
    NotificationItem(
      type: NotificationType.bookingConfirmed,
      title: 'Booking Confirmed',
      message: 'Your appointment confirmed with ',
      highlightText: 'Dr. Milind Chauhan.',
      suffix: ' ',
      tokenInfo: 'Token #24. (Est.Time: 10:45AM)',
      time: '3 min ago',
      isRead: false,
      isNew: false,
    ),
    NotificationItem(
      type: NotificationType.bookingRequestReceived,
      title: 'Booking Request Received',
      message: 'Your appointment request with ',
      highlightText: 'Dr. Milind Chauhan',
      suffix: ' has been received.',
      time: '5 min ago',
      isRead: true,
      isNew: false,
    ),
    NotificationItem(
      type: NotificationType.bookingCancelled,
      title: 'Booking Cancelled',
      message: 'Your appointment with ',
      highlightText: 'Dr. Milind Chauhan',
      suffix: ' has been cancelled.',
      time: '1 hour ago',
      isRead: true,
      isNew: false,
    ),
    NotificationItem(
      type: NotificationType.paymentReceived,
      title: 'Payment Received',
      message: 'Payment of ',
      highlightText: '₹500',
      suffix: ' received for consultation.',
      time: '2 hours ago',
      isRead: true,
      isNew: false,
    ),
    NotificationItem(
      type: NotificationType.prescriptionReady,
      title: 'Prescription Ready',
      message: 'Your prescription from ',
      highlightText: 'Dr. Milind Chauhan',
      suffix: ' is ready to view.',
      time: '1 day ago',
      isRead: true,
      isNew: false,
    ),
    NotificationItem(
      type: NotificationType.reminder,
      title: 'Appointment Reminder',
      message: 'Reminder: Your appointment with ',
      highlightText: 'Dr. Milind Chauhan',
      suffix: ' is tomorrow at 10:00 AM.',
      time: '1 day ago',
      isRead: true,
      isNew: false,
    ),
    NotificationItem(
      type: NotificationType.labReportReady,
      title: 'Lab Report Ready',
      message: 'Your ',
      highlightText: 'Blood Test Report',
      suffix: ' is now available.',
      time: '2 days ago',
      isRead: true,
      isNew: false,
    ),
  ];

  List<NotificationItem> get filteredNotifications {
    if (selectedTab == 'Unread') {
      return allNotifications.where((n) => !n.isRead).toList();
    }
    return allNotifications;
  }

  List<NotificationItem> get newNotifications =>
      filteredNotifications.where((n) => n.isNew).toList();

  List<NotificationItem> get olderNotifications =>
      filteredNotifications.where((n) => !n.isNew).toList();

  bool get hasUnreadNotifications => allNotifications.any((n) => !n.isRead);

  void markAllAsRead() {
    setState(() {
      for (var notification in allNotifications) {
        notification.isRead = true;
      }
    });
  }

  void markAsRead(NotificationItem notification) {
    setState(() {
      notification.isRead = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool hasNewNotifications = newNotifications.isNotEmpty;
    bool hasOlderNotifications = olderNotifications.isNotEmpty;
    bool hasAnyNotifications = hasNewNotifications || hasOlderNotifications;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.backArrow.assetPath,
            width: 32,
            height: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Notifications',
            style: EcliniqTextStyles.headlineMedium.copyWith(
              color: Color(0xff424242),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              EcliniqIcons.notifilter.assetPath,
              width: 40,
              height: 40,
            ),
            onPressed: () {
              _showFilterBottomSheet();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: Color(0xFFB8B8B8), height: 0.5),
        ),
      ),
      body: Column(
        children: [
          // Filter tabs
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildTabButton('All'),
                const SizedBox(width: 8),
                _buildTabButton('Unread'),
                const Spacer(),
                if (hasUnreadNotifications)
                  GestureDetector(
                    onTap: markAllAsRead,
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          EcliniqIcons.doubleMark.assetPath,
                          width: 18,
                          height: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Mark all as Read',
                          style: EcliniqTextStyles.bodyMedium.copyWith(
                            color: const Color(0xff424242),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: hasAnyNotifications
                ? ListView(
                    children: [
                      if (hasNewNotifications) ...[
                        _buildSectionHeader('New'),
                        ...newNotifications.map(
                          (notification) =>
                              _buildNotificationCard(notification),
                        ),
                      ],
                      if (hasOlderNotifications) ...[
                        _buildSectionHeader('Older'),
                        ...olderNotifications.map(
                          (notification) =>
                              _buildNotificationCard(notification),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  )
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFF7F6FA),
      child: Text(
        title,
        style: EcliniqTextStyles.bodySmall.copyWith(
          color: const Color(0xff424242),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildTabButton(String label) {
    bool isSelected = selectedTab == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FAFF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: const Color(0xFF96BFFF), width: 0.5)
              : null,
        ),
        child: Text(
          label,
          style: EcliniqTextStyles.headlineXMedium.copyWith(
            color: isSelected
                ? const Color(0xFF2372EC)
                : const Color(0xff626060),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return GestureDetector(
      onTap: () {
        markAsRead(notification);
        _navigateToDetails(notification);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    notification.title,
                    style: EcliniqTextStyles.bodyLarge.copyWith(
                      color: const Color(0xff424242),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    markAsRead(notification);
                    _navigateToDetails(notification);
                  },
                  child: Row(
                    children: [
                      Text(
                        'View Details',
                        style: EcliniqTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFF2372EC),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        color: const Color(0xFF2372EC),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Content Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                _buildNotificationIcon(notification.type),
                const SizedBox(width: 12),
                // Message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMessageText(notification),
                      const SizedBox(height: 4),
                      Text(
                        notification.time,
                        style: EcliniqTextStyles.bodySmall.copyWith(
                          color: const Color(0xff8E8E8E),
                        ),
                      ),
                    ],
                  ),
                ),
                // Unread indicator
                if (!notification.isRead)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(left: 8, top: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData iconData;
    Color iconColor;
    Color bgColor;

    switch (type) {
      case NotificationType.consultationCompleted:
        iconData = Icons.check;
        iconColor = const Color(0xFF4CAF50);
        bgColor = const Color(0xFFE8F5E9);
        break;
      case NotificationType.bookingConfirmed:
        iconData = Icons.event_available;
        iconColor = const Color(0xFF4CAF50);
        bgColor = const Color(0xFFE8F5E9);
        break;
      case NotificationType.bookingRequestReceived:
        iconData = Icons.send;
        iconColor = const Color(0xFF2372EC);
        bgColor = const Color(0xFFE3F2FD);
        break;
      case NotificationType.bookingCancelled:
        iconData = Icons.cancel_outlined;
        iconColor = const Color(0xFFE53935);
        bgColor = const Color(0xFFFFEBEE);
        break;
      case NotificationType.paymentReceived:
        iconData = Icons.payment;
        iconColor = const Color(0xFF4CAF50);
        bgColor = const Color(0xFFE8F5E9);
        break;
      case NotificationType.prescriptionReady:
        iconData = Icons.description_outlined;
        iconColor = const Color(0xFF9C27B0);
        bgColor = const Color(0xFFF3E5F5);
        break;
      case NotificationType.reminder:
        iconData = Icons.alarm;
        iconColor = const Color(0xFFFF9800);
        bgColor = const Color(0xFFFFF3E0);
        break;
      case NotificationType.labReportReady:
        iconData = Icons.science_outlined;
        iconColor = const Color(0xFF00BCD4);
        bgColor = const Color(0xFFE0F7FA);
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: iconColor.withOpacity(0.3), width: 1),
      ),
      child: Center(child: Icon(iconData, color: iconColor, size: 24)),
    );
  }

  Widget _buildMessageText(NotificationItem notification) {
    return RichText(
      text: TextSpan(
        style: EcliniqTextStyles.bodyMedium.copyWith(
          color: const Color(0xff424242),
        ),
        children: [
          TextSpan(text: notification.message),
          TextSpan(
            text: notification.highlightText,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: notification.suffix),
          if (notification.tokenInfo != null)
            TextSpan(
              text: notification.tokenInfo,
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              EcliniqIcons.noNotifications.assetPath,
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: EcliniqTextStyles.headlineMedium.copyWith(
                color: const Color(0xff424242),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ve got a blank slate (for now). We\'ll let you know when updates arrive.',
              style: EcliniqTextStyles.bodyMedium.copyWith(
                color: const Color(0xff8E8E8E),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Filter Notifications',
                style: EcliniqTextStyles.headlineMedium.copyWith(
                  color: const Color(0xff424242),
                ),
              ),
              const SizedBox(height: 16),
              _buildFilterOption('All Notifications', NotificationType.values),
              _buildFilterOption('Consultations', [
                NotificationType.consultationCompleted,
              ]),
              _buildFilterOption('Bookings', [
                NotificationType.bookingConfirmed,
                NotificationType.bookingRequestReceived,
                NotificationType.bookingCancelled,
              ]),
              _buildFilterOption('Payments', [
                NotificationType.paymentReceived,
              ]),
              _buildFilterOption('Reports', [
                NotificationType.prescriptionReady,
                NotificationType.labReportReady,
              ]),
              _buildFilterOption('Reminders', [NotificationType.reminder]),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String label, List<NotificationType> types) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: EcliniqTextStyles.bodyLarge.copyWith(
          color: const Color(0xff424242),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xff8E8E8E)),
      onTap: () {
        Navigator.pop(context);
        // Implement filter logic here
      },
    );
  }

  void _navigateToDetails(NotificationItem notification) {
    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.consultationCompleted:
        // Navigate to consultation details
        break;
      case NotificationType.bookingConfirmed:
      case NotificationType.bookingRequestReceived:
      case NotificationType.bookingCancelled:
        // Navigate to booking details
        break;
      case NotificationType.paymentReceived:
        // Navigate to payment details
        break;
      case NotificationType.prescriptionReady:
        // Navigate to prescription
        break;
      case NotificationType.reminder:
        // Navigate to appointment
        break;
      case NotificationType.labReportReady:
        // Navigate to lab reports
        break;
    }
  }
}

// Model class for notifications
class NotificationItem {
  final NotificationType type;
  final String title;
  final String message;
  final String highlightText;
  final String suffix;
  final String? tokenInfo;
  final String time;
  bool isRead;
  final bool isNew;

  NotificationItem({
    required this.type,
    required this.title,
    required this.message,
    required this.highlightText,
    required this.suffix,
    this.tokenInfo,
    required this.time,
    this.isRead = false,
    this.isNew = true,
  });
}
