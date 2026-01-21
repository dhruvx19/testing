import 'package:ecliniq/ecliniq_api/appointment_service.dart';
import 'package:ecliniq/ecliniq_api/models/appointment.dart';
import 'package:ecliniq/ecliniq_core/router/navigation_helper.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/cancelled.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/completed.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/confirmed.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/requested.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/quick_actions.dart';
import 'package:ecliniq/ecliniq_modules/screens/search_specialities/speciality_doctors_list.dart';
import 'package:ecliniq/ecliniq_modules/screens/search_specialities/speciality_hospital_list.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_modules/screens/notifications/notification_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/notifications/provider/notification_provider.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_navigation/bottom_navigation.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/error_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/scripts/ecliniq_ui.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/ratings/rate_your_exp_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class AppointmentData {
  final String id;
  final String doctorName;
  final String specialization;
  final String qualification;
  final String date;
  final String time;
  final String patientName;
  final AppointmentStatus status;
  final String? tokenNumber;
  final int? rating;

  AppointmentData({
    required this.id,
    required this.doctorName,
    required this.specialization,
    required this.qualification,
    required this.date,
    required this.time,
    required this.patientName,
    required this.status,
    this.tokenNumber,
    this.rating,
  });
}

enum AppointmentStatus { confirmed, requested, cancelled, completed }

class MyVisits extends StatefulWidget {
  const MyVisits({super.key});

  @override
  State<MyVisits> createState() => _MyVisitsState();
}

class _MyVisitsState extends State<MyVisits>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final int _currentIndex = 1;
  int _selectedTabIndex = 0;
  int _selectedFilterIndex = 0;
  final _appointmentService = AppointmentService();
  bool _isLoadingAppointments = false;
  // Key counter for hot reload

  List<AppointmentData> _scheduledAppointments = [];
  List<AppointmentData> _historyAppointments = [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).fetchUnreadCount();
    });
  }

  void _onTabTapped(int index) {
    // Don't navigate if already on the same tab
    if (index == _currentIndex) {
      return;
    }

    // Navigate using the navigation helper with smooth left-to-right transitions
    NavigationHelper.navigateToTab(context, index, _currentIndex);
  }

  Future<void> _loadAppointments() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authToken = authProvider.authToken;

    if (authToken == null) {
      if (mounted) {
        _showErrorSnackBar('Authentication required. Please login again.');
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoadingAppointments = true;
    });

    try {
      // Determine type based on filter index (Default is Doctor at index 0)
      final type = _selectedFilterIndex == 0 ? 'doctor' : 'hospital';

      // Load both scheduled and history appointments
      final results = await Future.wait([
        _appointmentService.getScheduledAppointments(
          authToken: authToken,
          type: type,
        ),
        _appointmentService.getAppointmentHistory(
          authToken: authToken,
          type: type,
        ),
      ]);

      if (!mounted) return;

      final scheduledResponse = results[0];
      final historyResponse = results[1];

      if (!mounted) return;
      setState(() {
        if (scheduledResponse.success) {
          _scheduledAppointments = scheduledResponse.data
              .map((item) => _mapToAppointmentData(item))
              .toList();
        } else {
          if (mounted) {
            _showErrorSnackBar(scheduledResponse.message);
          }
        }

        if (historyResponse.success) {
          _historyAppointments = historyResponse.data
              .map((item) => _mapToAppointmentData(item))
              .toList();
        } else {
          if (mounted) {
            _showErrorSnackBar(historyResponse.message);
          }
        }
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to load appointments: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAppointments = false;
        });
      }
    }
  }

  AppointmentData _mapToAppointmentData(AppointmentListItem item) {
    // Map API status to local enum
    AppointmentStatus status;
    switch (item.status.toUpperCase()) {
      case 'CONFIRMED':
        status = AppointmentStatus.confirmed;
        break;
      case 'CHECKED_IN':
        status = AppointmentStatus.confirmed;
        break;
      case 'PENDING':
        status = AppointmentStatus.requested;
        break;
      case 'CANCELLED':
      case 'FAILED':
        status = AppointmentStatus.cancelled;
        break;
      case 'COMPLETED':
      case 'SERVED':
        status = AppointmentStatus.completed;
        break;
      default:
        status = AppointmentStatus.requested;
    }

    // Format date
    final dateFormat = DateFormat('dd MMM, yyyy');
    final date = dateFormat.format(item.appointmentDate);

    // Format time
    final timeFormat = DateFormat('hh:mm a');
    final time = timeFormat.format(item.appointmentTime.startTime);

    // Format specialization (join list)
    final specialization = item.speciality.isNotEmpty
        ? item.speciality.join(', ')
        : 'General Physician';

    // Format qualification (join degrees)
    final qualification = item.degrees.isNotEmpty
        ? item.degrees.join(', ')
        : 'MBBS';

    // Format patient name
    final patientName = item.bookedFor == 'SELF'
        ? '${item.patientName} (You)'
        : item.patientName;

    return AppointmentData(
      id: item.appointmentId,
      doctorName: item.doctorName,
      specialization: specialization,
      qualification: qualification,
      date: date,
      time: time,
      patientName: patientName,
      status: status,
      tokenNumber: item.tokenNo?.toString(),
      rating: item.rating,
    );
  }

  Future<void> _navigateToDetailPage(AppointmentData appointment) async {
    // Navigate immediately with appointment ID and status
    // The detail page will handle its own loading state
    Widget detailPage;

    // Determine status from appointment data
    String status = appointment.status.name;
    if (status == 'served') {
      status = 'completed';
    } else if (status == 'pending') {
      status = 'requested';
    }

    switch (status) {
      case 'confirmed':
        detailPage = BookingConfirmedDetail(appointmentId: appointment.id);
        break;
      case 'requested':
        detailPage = BookingRequestedDetail(appointmentId: appointment.id);
        break;
      case 'cancelled':
      case 'failed':
        detailPage = BookingCancelledDetail(appointmentId: appointment.id);
        break;
      case 'completed':
        detailPage = BookingCompletedDetail(appointmentId: appointment.id);
        break;
      default:
        // Fallback: try to determine from status enum
        if (appointment.status == AppointmentStatus.confirmed) {
          detailPage = BookingConfirmedDetail(appointmentId: appointment.id);
        } else if (appointment.status == AppointmentStatus.requested) {
          detailPage = BookingRequestedDetail(appointmentId: appointment.id);
        } else if (appointment.status == AppointmentStatus.cancelled) {
          detailPage = BookingCancelledDetail(appointmentId: appointment.id);
        } else if (appointment.status == AppointmentStatus.completed) {
          detailPage = BookingCompletedDetail(appointmentId: appointment.id);
        } else {
          _showErrorSnackBar(
            'Unknown appointment status: ${appointment.status}',
          );
          return;
        }
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => detailPage),
    );

    if (result == true && mounted) {
      _refreshAppointments();
    }
  }

  void _showErrorSnackBar(String message) {
    CustomErrorSnackBar.show(
      context: context,
      title: 'Error',
      subtitle: message,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _refreshAppointments() async {
    // Reload appointments from API
    await _loadAppointments();
    setState(() {
      // Increment key to trigger hot reload
    });
  }

  Widget _buildTopTabs() {
    return Container(
      margin: const EdgeInsets.only(
        top: 8,
        bottom: 12,
      ), // Changed bottom margin to 12
      child: Row(
        children: [
          Expanded(child: _buildTabButton('Scheduled', 0)),
          Expanded(child: _buildTabButton('History', 1)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
        // Reload appointments when switching tabs
        _loadAppointments();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Color(0xFF2372EC) : Color(0xFFE0E0E0),
              width: isSelected ? 3 : 1,
            ),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
            fontWeight: FontWeight.w400,
            color: isSelected ? Color(0xFF2372EC) : Color(0xFF626060),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['Doctor', 'Hospital'];
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      
      height: screenWidth * 0.13,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 2,
        top: 6,
      ), // Removed top padding
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedFilterIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilterIndex = index;
              });
              _loadAppointments();
            },
            child: Container(
              margin: EdgeInsets.only(right: screenWidth * 0.03),
              padding: EdgeInsets.all(screenWidth * 0.02),
              decoration: BoxDecoration(
                color: isSelected ? Color(0xffF8FAFF) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Color(0xFF96BFFF) : Colors.white,
                  width: 0.5,
                ),
              ),
              child: Center(
                child: Text(
                  filters[index],
                  style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                      .copyWith(
                        fontWeight: FontWeight.w400,
                        color: isSelected
                            ? Color(0xff2372EC)
                            : Color(0xFF626060),
                      ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentData appointment) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalMargin = screenWidth * 0.04;
    final cardPadding = screenWidth * 0.04;

    return GestureDetector(
      onTap: () => _navigateToDetailPage(appointment),
      child: Container(
        width: screenWidth - (horizontalMargin * 2),
        margin: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
          context,
          horizontal: 16,
          vertical: 8,
        ),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 12),
          ),
          border: Border.all(color: Color(0xffD6D6D6), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(appointment),
            Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                context,
                left: 16,
                top: 12,
                right: 16,
                bottom: 16,
              ),
              child: Column(
                children: [
                  _buildDoctorInfo(appointment),
                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveSpacing(context, 12),
                  ),
                  _buildAppointmentDetails(appointment),
                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveSpacing(context, 12),
                  ),
                  _buildPatientInfo(appointment),
                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveSpacing(context, 12),
                  ),
                  _buildActionButtons(appointment),
                ],
              ),
            ),
            if (appointment.status == AppointmentStatus.completed)
              _buildRatingSection(appointment),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(AppointmentData appointment) {
    Color statusColor;
    Color textColor;
    String statusText;

    switch (appointment.status) {
      case AppointmentStatus.confirmed:
        statusColor = Color(0xFFF2FFF3);
        textColor = Color(0xff3EAF3F);
        statusText = 'Booking Confirmed';
        break;
      case AppointmentStatus.requested:
        statusColor = Color(0xFFFEF9E6);
        textColor = Color(0xffBE8B00);
        statusText = 'Requested';
        break;
      case AppointmentStatus.cancelled:
        statusColor = Color(0xFFFFF8F8);
        textColor = Color(0xffF04248);
        statusText = 'Cancelled';
        break;
      case AppointmentStatus.completed:
        statusColor = Color(0xFF4CAF50);
        textColor = Colors.white;
        statusText = 'Completed';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: appointment.status == AppointmentStatus.confirmed
          ? Row(
              children: [
                Text(
                  statusText,
                  style: EcliniqTextStyles.responsiveHeadlineBMedium(
                    context,
                  ).copyWith(fontWeight: FontWeight.w400, color: textColor),
                ),
                const Spacer(),
                if (appointment.tokenNumber != null)
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Token Number ',
                          style:
                              EcliniqTextStyles.responsiveHeadlineBMedium(
                                context,
                              ).copyWith(
                                color: Color(0xff424242),
                                fontWeight: FontWeight.w300,
                              ),
                        ),
                        TextSpan(
                          text: appointment.tokenNumber,
                          style:
                              EcliniqTextStyles.responsiveHeadlineBMedium(
                                context,
                              ).copyWith(
                                color: Color(0xff3EAF3F),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  statusText,
                  style: EcliniqTextStyles.responsiveHeadlineZMedium(
                    context,
                  ).copyWith(color: textColor),
                ),
                if (appointment.tokenNumber != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Token Number ${appointment.tokenNumber}',
                    style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                        .copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w300,
                        ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildDoctorInfo(AppointmentData appointment) {
    return Row(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Color(0xFFF8FAFF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFF96BFFF), width: 0.5),
                  ),
                  child: Center(
                    child: Text(
                      'D',
                      style: EcliniqTextStyles.responsiveHeadlineXXLargeBold(
                        context,
                      ).copyWith(color: Color(0xFF2196F3)),
                    ),
                  ),
                ),
                Positioned(
                  top: -2,
                  right: 0,
                  child: SvgPicture.asset(
                    EcliniqIcons.verified.assetPath,
                    width: 24,
                    height: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appointment.doctorName,
                style: EcliniqTextStyles.responsiveHeadlineLarge(
                  context,
                ).copyWith(color: Color(0xFF424242)),
              ),
              Text(
                appointment.specialization,
                style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF424242),
                ),
              ),
              Text(
                appointment.qualification,
                style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF424242),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentDetails(AppointmentData appointment) {
    return Row(
      children: [
        SvgPicture.asset(
          EcliniqIcons.appointmentReminder.assetPath,
          width: 24,
          height: 24,
        ),
        const SizedBox(width: 8),
        Text(
          '${appointment.date} | ${appointment.time}',
          style: EcliniqTextStyles.responsiveTitleXLarge(
            context,
          ).copyWith(fontWeight: FontWeight.w400, color: Color(0xFF626060)),
        ),
      ],
    );
  }

  Widget _buildPatientInfo(AppointmentData appointment) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Color(0xFFFFF7F0),
            borderRadius: BorderRadius.circular(42),
            border: Border.all(color: Color(0xffEC7600), width: 0.5),
          ),
          child: Center(
            child: Text(
              'DB',
              style: EcliniqTextStyles.responsiveBody2xSmallRegular(
                context,
              ).copyWith(color: Color(0xffEC7600), fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          appointment.patientName,
          style: EcliniqTextStyles.responsiveTitleXLarge(
            context,
          ).copyWith(fontWeight: FontWeight.w400, color: Color(0xFF626060)),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppointmentData appointment) {
    switch (appointment.status) {
      case AppointmentStatus.confirmed:
      case AppointmentStatus.requested:
        return SizedBox(
          width: double.infinity,
          height: EcliniqTextStyles.getResponsiveButtonHeight(
            context,
            baseHeight: 52.0,
          ),

          child: ElevatedButton(
            onPressed: () => _navigateToDetailPage(appointment),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white,
              side: BorderSide(color: Color(0xFF8E8E8E), width: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                context,
                horizontal: 0,
                vertical: 12,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View Details',
                  style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                      .copyWith(
                        color: Color(0xFF424242),

                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(width: 4),
                SvgPicture.asset(
                  EcliniqIcons.arrowRight.assetPath,
                  width: 24,
                  height: 24,
                  color: Color(0xFF424242),
                ),
              ],
            ),
          ),
        );

      case AppointmentStatus.cancelled:
      case AppointmentStatus.completed:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _navigateToDetailPage(appointment),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'View Details',
                  style: EcliniqTextStyles.responsiveHeadlineXMedium(
                    context,
                  ).copyWith(color: Color(0xFF2372EC)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2372EC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Book Again',
                  style: EcliniqTextStyles.responsiveHeadlineMedium(
                    context,
                  ).copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildRatingSection(AppointmentData appointment) {
    if (_selectedTabIndex != 1) return SizedBox.shrink();

    final hasRating = appointment.rating != null && appointment.rating! > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFFF9F9F9),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: GestureDetector(
        onTap: hasRating ? null : () => _openRatingSheet(appointment),
        child: Row(
          children: [
            Text(
              'Rate Doctor :',
              style: EcliniqTextStyles.responsiveTitleXLarge(
                context,
              ).copyWith(fontWeight: FontWeight.w400, color: Color(0xff424242)),
            ),
            const Spacer(),
            Row(
              children: List.generate(5, (index) {
                final filled = hasRating && index < appointment.rating!;
                return SvgPicture.asset(
                  filled
                      ? EcliniqIcons.starRateExp.assetPath
                      : EcliniqIcons.starHistory.assetPath,
                  width: 24,
                  height: 24,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRatingSheet(AppointmentData appointment) async {
    // Don't allow opening if rating already exists
    if (appointment.rating != null && appointment.rating! > 0) {
      return;
    }

    await RatingBottomSheet.show(
      context: context,
      initialRating: appointment.rating,
      doctorName: appointment.doctorName,
      appointmentId: appointment.id,
      onRatingSubmitted: (rating) {
        // Refresh appointments after rating is submitted
        _refreshAppointments();
      },
      onRefetch: () {
        // Refresh appointments to get updated rating
        _refreshAppointments();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentAppointments = _selectedTabIndex == 0
        ? _scheduledAppointments
        : _historyAppointments;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Stack(
          children: [
            EcliniqScaffold(
              backgroundColor: EcliniqScaffold.primaryBlue,
              body: SizedBox.expand(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            EcliniqIcons.nameLogo.assetPath,
                            height: 28,
                            width: 140,
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () async {
                              await EcliniqRouter.push(NotificationScreen());
                              if (mounted) {
                                Provider.of<NotificationProvider>(
                                  context,
                                  listen: false,
                                ).fetchUnreadCount();
                              }
                            },
                            child: Consumer<NotificationProvider>(
                              builder: (context, provider, child) {
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    SvgPicture.asset(
                                      EcliniqIcons.notificationBell.assetPath,
                                      height: 32,
                                      width: 32,
                                    ),
                                    if (provider.unreadCount > 0)
                                      Positioned(
                                        top: -12,
                                        right: -8,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(
                                            minWidth: 20,
                                            minHeight: 20,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xffF04248),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: EcliniqText(
                                              provider.unreadCount > 99
                                                  ? '99+'
                                                  : '${provider.unreadCount}',
                                              style: EcliniqTextStyles
                                                  .headlineSmall
                                                  .copyWith(
                                                    color: Colors.white,
                                                    height: 1,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(color: Colors.white),
                        child: Column(
                          children: [
                            _buildTopTabs(),
                            _buildFilterTabs(),
                            Expanded(
                              child: _isLoadingAppointments
                                  ? const ShimmerListLoading(
                                      itemCount: 3,
                                      itemHeight: 200,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                    )
                                  : currentAppointments.isEmpty
                                  ? Center(
                                      child: SingleChildScrollView(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                        
                                            SvgPicture.asset(
                                              EcliniqIcons
                                                  .noSchedule
                                                  .assetPath,
                                              width: EcliniqTextStyles
                                                  .getResponsiveWidth(
                                                context,
                                                130,
                                              ),
                                              height: EcliniqTextStyles
                                                  .getResponsiveHeight(
                                                context,
                                                140,
                                              ),
                                            ),
                                            SizedBox(
                                              height:
                                                  EcliniqTextStyles
                                                      .getResponsiveSpacing(
                                                context,
                                                16,
                                              ),
                                            ),
                                            Text('No Schedule yet!',
                                                style: EcliniqTextStyles
                                                    .responsiveBodyLarge(
                                                  context,
                                                ).copyWith(
                                                  color: Color(0xFF424242),
                                                  fontWeight: FontWeight.w400,
                                                )),
                                            Text(
                                              'You didn’t scheduled any appointment.',
                                              style:
                                                  EcliniqTextStyles.responsiveBodyLarge(
                                                    context,
                                                  ).copyWith(
                                                    color: Color(0xFF8E8E8E),
                                                      fontWeight: FontWeight.w400,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 16.0,
                                              ),
                                              child: QuickActionsWidget(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: EdgeInsets.only(
                                        top: 20,
                                        bottom: 50,
                                      ),
                                      itemCount: currentAppointments.length,
                                      itemBuilder: (context, index) {
                                        final appointment =
                                            currentAppointments[index];
                                        return _buildAppointmentCard(
                                          appointment,
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    EcliniqBottomNavigationBar(
                      currentIndex: _currentIndex,
                      onTap: _onTabTapped,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class QuickActionsWidget extends StatelessWidget {
  final bool showShimmer;

  const QuickActionsWidget({super.key, this.showShimmer = false});

  @override
  Widget build(BuildContext context) {
    if (showShimmer) {
      return _buildShimmer(context);
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final itemWidth = isSmallScreen ? 195.0 : 195.0;
    final itemHeight = isSmallScreen ? 192.0 : 90.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Padding(
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
            context,
           
            bottom: 16.0,
            top: 12.0,
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildQuickActionItem(
                  context,
                  width: itemWidth,
                  height: itemHeight,
                  assetPath: EcliniqIcons.quick1.assetPath,
                  title: 'Consult Doctors',
                  onTap: () => EcliniqRouter.push(SpecialityDoctorsList()),
                ),
              ),
              SizedBox(
                width: EcliniqTextStyles.getResponsiveSpacing(context, 12.0),
              ),
              Expanded(
                child: _buildQuickActionItem(
                  context,
                  width: itemWidth,
                  height: itemHeight,
                  assetPath: EcliniqIcons.hospitalBuilding.assetPath,
                  title: 'Visit Hospitals',
                  onTap: () => EcliniqRouter.push(SpecialityHospitalList()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context, {
    required double width,
    required double height,
    required String assetPath,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          EcliniqTextStyles.getResponsiveBorderRadius(context, 16.0),
        ),
        child: Container(
          width: width,
          height: height,
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 6.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              EcliniqTextStyles.getResponsiveBorderRadius(context, 8.0),
            ),
            border: Border.all(color: Color(0xffD6D6D6), width: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: EcliniqTextStyles.getResponsiveWidth(context, 52),
                height: EcliniqTextStyles.getResponsiveHeight(context, 52),
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 26.0),
                  ),
                  border: Border.all(color: Color(0xFFE4EFFF), width: 0.5),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    assetPath,
                    width: EcliniqTextStyles.getResponsiveIconSize(
                      context,
                      32.0,
                    ),
                    height: EcliniqTextStyles.getResponsiveIconSize(
                      context,
                      32.0,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 2),
              ),
              EcliniqText(
                title,
                textAlign: TextAlign.center,
                style: EcliniqTextStyles.responsiveTitleXLarge(
                  context,
                ).copyWith(color: Color(0xFF424242)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: EcliniqTextStyles.getResponsiveSize(context, 8.0),
              height: EcliniqTextStyles.getResponsiveSize(context, 24.0),
              decoration: BoxDecoration(
                color: Color(0xFF96BFFF),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                  ),
                  bottomRight: Radius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: EcliniqTextStyles.getResponsiveSpacing(context, 12.0),
            ),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: EcliniqTextStyles.getResponsiveSize(context, 20.0),
                width: EcliniqTextStyles.getResponsiveWidth(context, 150.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0)),

        Padding(
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 12.0),
          child: Row(
            children: [
              Expanded(child: _buildCardShimmer(context)),
              SizedBox(
                width: EcliniqTextStyles.getResponsiveSpacing(context, 10.0),
              ),
              Expanded(child: _buildCardShimmer(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: EcliniqTextStyles.getResponsiveHeight(context, 105.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 12.0),
          ),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
      ),
    );
  }
}
