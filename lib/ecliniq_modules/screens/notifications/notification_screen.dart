import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String selectedTab = 'All';

  // Sample notification data - replace with your actual data source
  List<NotificationItem> allNotifications = [
    // Add your notifications here or fetch from API
    // Example:
    // NotificationItem(
    //   type: 'Consultation Completed',
    //   message: 'Your consultation with Dr. Milind Chauhan is Completed',
    //   time: '3 min ago',
    //   isRead: false,
    //   isNew: true,

    // ),
  ];

  List<NotificationItem> get newNotifications => allNotifications
      .where((n) => n.isNew && (selectedTab == 'All' || !n.isRead))
      .toList();

  List<NotificationItem> get olderNotifications => allNotifications
      .where((n) => !n.isNew && (selectedTab == 'All' || !n.isRead))
      .toList();

  void markAllAsRead() {
    setState(() {
      for (var notification in allNotifications) {
        notification.isRead = true;
      }
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
              
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.2),
          child: Container(color: Color(0xFFB8B8B8), height: 1.0),
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
                const SizedBox(width: 4),
                _buildTabButton('Unread'),
                const Spacer(),
                if (!hasAnyNotifications)
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
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Text(
                            'New',
                            style: EcliniqTextStyles.bodyLarge.copyWith(
                              color: const Color(0xff424242),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ...newNotifications.map(
                          (notification) =>
                              _buildNotificationCard(notification),
                        ),
                      ],
                      if (hasOlderNotifications) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Text(
                            'Older',
                            style: EcliniqTextStyles.bodyLarge.copyWith(
                              color: const Color(0xff424242),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ...olderNotifications.map(
                          (notification) =>
                              _buildNotificationCard(notification),
                        ),
                      ],
                    ],
                  )
                : _buildEmptyState(),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FAFF) : Colors.white,
          borderRadius: isSelected
              ? BorderRadius.circular(8)
              : BorderRadius.circular(0),
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
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                notification.type,
                style: EcliniqTextStyles.bodyLarge.copyWith(
                  color: const Color(0xff424242),
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to details
                },
                child: Text(
                  'View Details >',
                  style: EcliniqTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF2196F3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: notification.iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    notification.iconData,
                    color: notification.iconColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.message,
                      style: EcliniqTextStyles.bodyMedium.copyWith(
                        color: const Color(0xff424242),
                      ),
                    ),
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
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(EcliniqIcons.noNotifications.assetPath),
            const SizedBox(height: 4),
            Text(
              'No notifications yet',
              style: EcliniqTextStyles.bodyMedium.copyWith(
                color: const Color(0xff424242),
                fontWeight: FontWeight.w400,
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
}

// Model class for notifications
class NotificationItem {
  final String type;
  final String message;
  final String time;
  bool isRead;
  final bool isNew;
  final IconData iconData;
  final Color iconColor;
  final Color iconBgColor;

  NotificationItem({
    required this.type,
    required this.message,
    required this.time,
    this.isRead = false,
    this.isNew = true,
    this.iconData = Icons.check_circle,
    this.iconColor = Colors.green,
    this.iconBgColor = const Color(0xFFE8F5E9),
  });
}
