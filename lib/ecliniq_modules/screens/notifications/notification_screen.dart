import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/cancelled.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/completed.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/confirmed.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/requested.dart';
import 'package:ecliniq/ecliniq_modules/screens/notifications/models/notification_model.dart';
import 'package:ecliniq/ecliniq_modules/screens/notifications/provider/notification_provider.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';


enum NotificationType {
  consultationCompleted,
  bookingConfirmed,
  bookingRequestReceived,
  
  
  
  
  
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String selectedTab = 'All';

  @override
  void initState() {
    super.initState();
    
    Future.microtask(() {
      if (mounted) {
        _loadNotifications();
      }
    });
  }

  
  Future<void> _loadNotifications() async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    await provider.fetchAllNotifications();
  }

  
  List<NotificationModel> get _allNotifications {
    final provider = Provider.of<NotificationProvider>(context);
    final data = provider.allNotifications?['data'];
    if (data == null) return [];

    final allData = data['all'];
    if (allData == null) return [];

    final newList = (allData['new'] as List<dynamic>?) ?? [];
    final olderList = (allData['older'] as List<dynamic>?) ?? [];

    final allNotifications = <NotificationModel>[];
    allNotifications.addAll(
      newList.map((item) => NotificationModel.fromJson(item)),
    );
    allNotifications.addAll(
      olderList.map((item) => NotificationModel.fromJson(item)),
    );
    
    
    allNotifications.sort((a, b) {
      try {
        final dateA = DateTime.parse(a.createdAt);
        final dateB = DateTime.parse(b.createdAt);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });

    return allNotifications;
  }

  
  List<NotificationModel> get _unreadNotifications {
    
    return _allNotifications.where((n) => !n.isRead).toList();
  }

  
  
  List<NotificationModel> get _newNotifications {
    if (selectedTab == 'Unread') {
      
      return _unreadNotifications;
    }

    final all = _allNotifications;
    final now = DateTime.now();
    final fortyEightHoursAgo = now.subtract(const Duration(hours: 48));

    return all.where((n) {
      if (!n.isRead) return true; 
      
      try {
        final date = DateTime.parse(n.createdAt);
        return date.isAfter(fortyEightHoursAgo); 
      } catch (e) {
        return true; 
      }
    }).toList();
  }

  
  
  List<NotificationModel> get _olderNotifications {
    if (selectedTab == 'Unread') {
      return []; 
    }

    final all = _allNotifications;
    final now = DateTime.now();
    final fortyEightHoursAgo = now.subtract(const Duration(hours: 48));

    return all.where((n) {
      if (!n.isRead) return false; 
      
      try {
        final date = DateTime.parse(n.createdAt);
        return date.isBefore(fortyEightHoursAgo) || date.isAtSameMomentAs(fortyEightHoursAgo);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  
  bool get _hasUnreadNotifications {
    final provider = Provider.of<NotificationProvider>(context);
    return provider.unreadCount > 0;
  }

  
  Future<void> _markAllAsRead() async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    final success = await provider.markAllAsRead();
    if (success) {
      
      await provider.fetchAllNotifications();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? 'Failed to mark all as read',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  
  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    final provider = Provider.of<NotificationProvider>(context, listen: false);
    final success = await provider.markAsRead(notification.id);
    if (success) {
      
      await provider.fetchAllNotifications();
    }
  }

  
  NotificationItem _toNotificationItem(NotificationModel model) {
    
    String doctorName = '';
    String token = '';
    String estimatedTime = '';
    
    if (model.metadata?.data != null) {
      doctorName = model.metadata!.data!['doctorName']?.toString() ?? 
                   model.metadata!.data!['doctor_name']?.toString() ?? '';
      
      token = model.metadata!.data!['tokenNo']?.toString() ?? 
              model.metadata!.data!['token']?.toString() ?? 
              model.metadata!.data!['tokenNumber']?.toString() ?? '';
      estimatedTime = model.metadata!.data!['estimatedTime']?.toString() ?? 
                      model.metadata!.data!['estTime']?.toString() ?? 
                      model.metadata!.data!['time']?.toString() ?? '';
    }

    
    NotificationType type = NotificationType.bookingRequestReceived;
    String title = model.subject;
    String message = '';
    String highlightText = '';
    String suffix = '';
    String? tokenInfo;
    String? tokenNumber;
    String? estTime;

    
    if (model.subject == 'APPOINTMENT_CONFIRMED') {
      type = NotificationType.bookingConfirmed;
      title = 'Booking Confirmed';
      
      
      
      String doctorPart = '';
      if (doctorName.isNotEmpty) {
        doctorPart = doctorName.trim().startsWith('Dr.') 
            ? doctorName.trim() 
            : 'Dr. ${doctorName.trim()}';
      } else {
        doctorPart = 'the doctor';
      }
      message = 'Your appointment confirmed with';
      highlightText = doctorPart;
      
      
      tokenNumber = token.isNotEmpty ? token : null;
      estTime = estimatedTime.isNotEmpty ? estimatedTime : null;
      
      
      suffix = '.';
    }
    
    else if (model.subject == 'APPOINTMENT_REQUESTED') {
      type = NotificationType.bookingRequestReceived;
      title = 'Booking Request Received';
      
      
      
      String doctorPart = '';
      if (doctorName.isNotEmpty) {
        doctorPart = doctorName.trim().startsWith('Dr.') 
            ? doctorName.trim() 
            : 'Dr. ${doctorName.trim()}';
      } else {
        doctorPart = 'the doctor';
      }
      message = 'Your appointment request with';
      highlightText = doctorPart;
      suffix = ' has been received.';
    }
    
    else if (model.category == 'APPOINTMENT') {
      if (model.subject.toLowerCase().contains('confirmed')) {
        type = NotificationType.bookingConfirmed;
      } else if (model.subject.toLowerCase().contains('completed') ||
          model.subject.toLowerCase().contains('consultation')) {
        type = NotificationType.consultationCompleted;
      } else {
        type = NotificationType.bookingRequestReceived;
      }
      
      
      message = model.message;
      highlightText = doctorName.isNotEmpty ? doctorName : '';
      suffix = '';
    }
    
    else {
      message = model.message;
      highlightText = doctorName.isNotEmpty ? doctorName : '';
      suffix = '';
    }

    return NotificationItem(
      id: model.id,
      type: type,
      title: title,
      message: message,
      highlightText: highlightText,
      suffix: suffix,
      tokenInfo: tokenInfo,
      tokenNumber: tokenNumber,
      estimatedTime: estTime,
      time: model.timeAgo,
      isRead: model.isRead,
      isNew: false, 
      entityType: model.entityType,
      entityId: model.entityId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final isLoading = provider.isLoading;
        final hasNewNotifications = _newNotifications.isNotEmpty;
        final hasOlderNotifications = _olderNotifications.isNotEmpty;
        final hasAnyNotifications =
            hasNewNotifications || hasOlderNotifications;

        if (isLoading && provider.allNotifications == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildAppBar(),
            body: _buildShimmerLoading(),
          );
        }

        if (provider.errorMessage != null &&
            provider.allNotifications == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildAppBar(),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.errorMessage ?? 'Error loading notifications'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadNotifications,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(),
          body: Column(
            children: [
              
              Padding(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16.0),
                child: Row(
                  children: [
                    _buildTabButton('All'),
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                    ),
                    _buildTabButton('Unread'),
                    const Spacer(),
                    if (_hasUnreadNotifications)
                      GestureDetector(
                        onTap: _markAllAsRead,
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              EcliniqIcons.doubleMark.assetPath,
                              width: EcliniqTextStyles.getResponsiveIconSize(context, 18),
                              height: EcliniqTextStyles.getResponsiveIconSize(context, 18),
                            ),
                            SizedBox(
                              width: EcliniqTextStyles.getResponsiveSpacing(context, 4),
                            ),
                            Text(
                              'Mark all as Read',
                              style: EcliniqTextStyles.responsiveBodyMedium(context).copyWith(
                                color: const Color(0xff424242),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              
              Expanded(
                child: hasAnyNotifications
                    ? ListView(
                        children: [
                          if (hasNewNotifications) ...[
                            _buildSectionHeader('New'),
                            ..._newNotifications.map(
                              (notification) => _buildNotificationCard(
                                _toNotificationItem(notification),
                                notification,
                              ),
                            ),
                          ],
                          SizedBox(
                            height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
                          ),
                          if (hasOlderNotifications) ...[
                            _buildSectionHeader('Older'),
                            ..._olderNotifications.map(
                              (notification) => _buildNotificationCard(
                                _toNotificationItem(notification),
                                notification,
                              ),
                            ),
                          ],
                        ],
                      )
                    : _buildEmptyState(),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      surfaceTintColor: Colors.transparent,
      leadingWidth: 58,
      titleSpacing: 0,
      toolbarHeight: 38,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: SvgPicture.asset(
          EcliniqIcons.backArrow.assetPath,
          width: EcliniqTextStyles.getResponsiveSize(context, 32.0),
          height: EcliniqTextStyles.getResponsiveSize(context, 32.0),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Notifications',
          style: EcliniqTextStyles.responsiveHeadlineMedium(
            context,
          ).copyWith(color: Color(0xff424242)),
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
        preferredSize: Size.fromHeight(
          EcliniqTextStyles.getResponsiveSize(context, 1.0),
        ),
        child: Container(
          color: Color(0xFFB8B8B8),
          height: EcliniqTextStyles.getResponsiveSize(context, 1.0),
        ),
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
        style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
          color: const Color(0xff111111),
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FAFF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: const Color(0xFF96BFFF), width: 0.5)
              : null,
        ),
        child: Text(
          label,
          style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
            color: isSelected
                ? const Color(0xFF2372EC)
                : const Color(0xff626060),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    NotificationItem notification,
    NotificationModel model,
  ) {
    
    final backgroundColor = notification.isRead
        ? const Color(0xFFF9F9F9)
        : Colors.white;

    return GestureDetector(
      onTap: () {
        _markAsRead(model);
        _navigateToDetails(notification, model);
      },
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 0, top: 16),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0x0D111111), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    notification.title,
                    style: EcliniqTextStyles.responsiveTitleXBLarge(context).copyWith(
                      color: const Color(0xff424242),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _markAsRead(model);
                    _navigateToDetails(notification, model);
                  },
                  child: Row(
                    children: [
                      Text(
                        'View Details',
                        style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                          color: const Color(0xFF2372EC),
                        ),
                      ),

                      SvgPicture.asset(
                        EcliniqIcons.arrowRightBlue.assetPath,
                        width: 16,
                        height: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0x0D111111), width: 1),
              ),
            ),
            const SizedBox(height: 8),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                _buildNotificationIcon(notification.type),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMessageText(notification),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),

                
                if (!notification.isRead)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(left: 8, top: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1001D),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              notification.time,
              style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                color: const Color(0x00000000).withOpacity(0.6),
              
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    EcliniqIcons iconData;
    Color iconColor;
    Color bgColor;

    switch (type) {
      case NotificationType.consultationCompleted:
        iconData = EcliniqIcons.verifiedCheckGreen;
        iconColor = const Color(0xFF3EAF3F);
        bgColor = const Color(0xFFF2FFF3);
        break;
      case NotificationType.bookingConfirmed:
        iconData = EcliniqIcons.calendarCheck;
        iconColor = const Color(0xFF3EAF3F);
        bgColor = const Color(0xFFF2FFF3);
        break;
      case NotificationType.bookingRequestReceived:
        iconData = EcliniqIcons.bookingReceived;
        iconColor = const Color(0xFF96BFFF);
        bgColor = const Color(0xFFF8FAFF);
        break;
      
      
      
      
      
      
      
      
      
      
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: iconColor, width: 0.5),
      ),
      child: Center(
        child: SvgPicture.asset(
          iconData.assetPath,
          width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
          height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
        ),
      ),
    );
  }

  Widget _buildMessageText(NotificationItem notification) {
    final List<TextSpan> children = [
      TextSpan(
        text: '${notification.message} ',
        style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
          color: Color(0xff424242),
          fontWeight: FontWeight.w300,
        ),
      ),
      TextSpan(
        text: notification.highlightText,
        style: EcliniqTextStyles.responsiveTitleXBLarge(context).copyWith(
          color: Color(0xff424242),
        ),
      ),
      TextSpan(
        text: notification.suffix,
        style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
          color: Color(0xff424242),
          fontWeight: FontWeight.w300,
        ),
      ),
    ];

    
    if (notification.type == NotificationType.bookingConfirmed) {
      if (notification.tokenNumber != null && notification.estimatedTime != null) {
        children.add(
          TextSpan(
            text: ' Token #${notification.tokenNumber}. ',
            style: EcliniqTextStyles.responsiveTitleXBLarge(context).copyWith(
              color: Color(0xFF3EAF3F),
            ),
          ),
        );
        children.add(
          TextSpan(
            text: '(Est.Time: ${notification.estimatedTime})',
            style: EcliniqTextStyles.responsiveTitleXBLarge(context).copyWith(
              color: Color(0xFF3EAF3F),
            ),
          ),
        );
      } else if (notification.tokenNumber != null) {
        children.add(
          TextSpan(
            text: ' Token #${notification.tokenNumber}.',
            style: EcliniqTextStyles.responsiveTitleXBLarge(context).copyWith(
              color: Color(0xFF3EAF3F),
            ),
          ),
        );
      } else if (notification.estimatedTime != null) {
        children.add(
          TextSpan(
            text: ' (Est.Time: ${notification.estimatedTime})',
            style: EcliniqTextStyles.responsiveTitleXBLarge(context).copyWith(
              color: Color(0xFF3EAF3F),
            ),
          ),
        );
      }
    } else if (notification.tokenInfo != null) {
      
      children.add(
        TextSpan(
          text: notification.tokenInfo,
          style: EcliniqTextStyles.responsiveTitleXBLarge(context).copyWith(
            color: Color(0xFF3EAF3F),
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: EcliniqTextStyles.responsiveBodyMedium(context).copyWith(
          color: const Color(0xff424242),
        ),
        children: children,
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
              style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                color: const Color(0xff424242),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ve got a blank slate (for now). We\'ll let you know when updates arrive.',
              style: EcliniqTextStyles.responsiveBodyMedium(context).copyWith(
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
                style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
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
              ]),
              
              
              
              
              
              
              
              
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
        style: EcliniqTextStyles.responsiveBodyLarge(context).copyWith(
          color: const Color(0xff424242),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xff8E8E8E)),
      onTap: () {
        Navigator.pop(context);
        
      },
    );
  }

  void _navigateToDetails(
    NotificationItem notification,
    NotificationModel model,
  ) {
    
    if (model.entityType == 'APPOINTMENT' && model.entityId.isNotEmpty) {
      
      final appointmentId = model.entityId;

      
      
      EcliniqRouter.push(BookingConfirmedDetail(appointmentId: appointmentId));
    }
    
  }

  
  Widget _buildShimmerLoading() {
    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFFF7F6FA),
          child: ShimmerLoading(
            width: 60,
            height: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        
        ...List.generate(5, (index) => _buildNotificationCardShimmer()),
      ],
    );
  }

  
  Widget _buildNotificationCardShimmer() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 0, top: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x0D111111), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ShimmerLoading(
                  height: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 16),
              ShimmerLoading(
                width: 100,
                height: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          ShimmerLoading(
            height: 1,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 8),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              ShimmerLoading(
                width: 48,
                height: 48,
                borderRadius: BorderRadius.circular(24),
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    ShimmerLoading(
                      width: 200,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          ShimmerLoading(
            width: 80,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}


class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String highlightText;
  final String suffix;
  final String? tokenInfo;
  final String? tokenNumber;
  final String? estimatedTime;
  final String time;
  bool isRead;
  final bool isNew;
  final String entityType;
  final String entityId;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.highlightText,
    required this.suffix,
    this.tokenInfo,
    this.tokenNumber,
    this.estimatedTime,
    required this.time,
    this.isRead = false,
    this.isNew = true,
    required this.entityType,
    required this.entityId,
  });
}
