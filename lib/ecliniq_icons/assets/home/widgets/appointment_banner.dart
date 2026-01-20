import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/cancelled.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/completed.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/confirmed.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/requested.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Model for appointment banner data
class AppointmentBanner {
  final String type; // REQUESTED, ACTIVE, UPCOMING, RESCHEDULE
  final String appointmentId;
  final String doctorName;
  final String doctorSpecialization;
  final int? tokenNumber;
  final String appointmentDate;
  final String appointmentDateFormatted;
  final String appointmentTime;
  final String hospitalName;
  final String bookedFor; // SELF or DEPENDENT
  final String patientName;
  final String status;
  final bool?
  isInQueue; // For confirmed appointments - whether patient is in queue

  AppointmentBanner({
    required this.type,
    required this.appointmentId,
    required this.doctorName,
    required this.doctorSpecialization,
    this.tokenNumber,
    required this.appointmentDate,
    required this.appointmentDateFormatted,
    required this.appointmentTime,
    required this.hospitalName,
    required this.bookedFor,
    required this.patientName,
    required this.status,
    this.isInQueue,
  });

  factory AppointmentBanner.fromJson(Map<String, dynamic> json) {
    return AppointmentBanner(
      type: json['type'] ?? '',
      appointmentId: json['appointmentId'] ?? '',
      doctorName: json['doctorName'] ?? '',
      doctorSpecialization: json['doctorSpecialization'] ?? '',
      tokenNumber: json['tokenNumber'],
      appointmentDate: json['appointmentDate'] ?? '',
      appointmentDateFormatted: json['appointmentDateFormatted'] ?? '',
      appointmentTime: json['appointmentTime'] ?? '',
      hospitalName: json['hospitalName'] ?? '',
      bookedFor: json['bookedFor'] ?? '',
      patientName: json['patientName'] ?? '',
      status: json['status'] ?? '',
      isInQueue: json['isInQueue'],
    );
  }
}

/// Widget to display appointment banners
class AppointmentBannerWidget extends StatelessWidget {
  final AppointmentBanner banner;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  const AppointmentBannerWidget({
    super.key,
    required this.banner,
    this.onTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return _buildBannerByType(context);
  }

  Widget _buildBannerByType(BuildContext context) {
    switch (banner.type.toUpperCase()) {
      case 'REQUESTED':
        return _buildRequestedBanner(context);
      case 'ACTIVE':
        return _buildActiveBanner(context);
      case 'UPCOMING':
        return _buildUpcomingBanner(context);
      case 'RESCHEDULE':
        return _buildRescheduleBanner(context);
      default:
        return _buildUpcomingBanner(context); // Default to upcoming
    }
  }

  /// REQUESTED Banner - Yellow/Orange theme (no left padding)
  Widget _buildRequestedBanner(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _navigateToAppointmentDetails(context),
      child: Container(
        height: EcliniqTextStyles.getResponsiveHeight(context, 76.0),
        decoration: const BoxDecoration(color: Color(0xFFFEF9E6)),
        child: Padding(
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
            context,
            horizontal: 16.0,
            vertical: 14.0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildGifIcon(context),
              SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0)),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: EcliniqText(
                        'Your Appointment Requested!',
                        style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                          color: const Color(0xFF424242),
                        ),
                      ),
                    ),
                    SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 2.0)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: EcliniqText(
                        'Waiting For Doctor to Confirm...',
                        style: EcliniqTextStyles.responsiveBodySmallProminent(context).copyWith(
                          color: const Color(0xFFBE8B00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: EcliniqTextStyles.getResponsiveSize(context, 28.0),
                height: EcliniqTextStyles.getResponsiveSize(context, 28.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD6D6D6),
                    width: EcliniqTextStyles.getResponsiveSize(context, 0.5),
                  ),
                ),
                child: Center(
                  child: Transform.rotate(
                    angle: 90 * 3.14159 / 180,
                    child: SvgPicture.asset(
                      EcliniqIcons.arrowUp.assetPath,
                      width: EcliniqTextStyles.getResponsiveIconSize(context, 20.0),
                      height: EcliniqTextStyles.getResponsiveIconSize(context, 20.0),
                      color: const Color(0xff424242),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ACTIVE Banner - Green theme (Confirmed)
  Widget _buildActiveBanner(BuildContext context) {
    return _buildBannerContainer(
      context,
      backgroundColor: const Color(0xFFF2FFF3),
      iconColor: const Color(0xFF3EAF3F),
      title: 'Appointment Confirmed With Dr. Milind Chauhan',
      subtitle: 'Your Token #24 (Queue Not Started)',
    );
  }

  /// UPCOMING Banner - Blue theme with custom styling
  Widget _buildUpcomingBanner(BuildContext context) {
    String subtitle = '';
    if (banner.doctorName.isNotEmpty) {
      subtitle = banner.doctorName;
      if (banner.tokenNumber != null) {
        subtitle += ' | Token #${banner.tokenNumber}';
      }
    } else if (banner.tokenNumber != null) {
      subtitle = 'Token #${banner.tokenNumber}';
    } else {
      subtitle = 'Your appointment is scheduled';
    }

    return GestureDetector(
      onTap: onTap ?? () => _navigateToAppointmentDetails(context),
      child: Container(
        height: EcliniqTextStyles.getResponsiveHeight(context, 76.0),
        decoration: const BoxDecoration(color: Color(0xFFF2FFF3)),
        child: Padding(
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
            context,
            horizontal: 16.0,
            vertical: 14.0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildUpcomingIconContainer(context, const Color(0xFF424242)),
              SizedBox(
                width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: EcliniqText(
                        'Upcoming Appointment',
                        style: EcliniqTextStyles.responsiveBodyLarge(context).copyWith(
                          color: const Color(0xFF3EAF3F),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: EcliniqTextStyles.getResponsiveSpacing(context, 2),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: EcliniqText(
                        subtitle,
                        style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                          color: const Color(0xFF424242),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClose ?? () {},
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: EcliniqTextStyles.getResponsiveWidth(context, 28),
                  height: EcliniqTextStyles.getResponsiveHeight(context, 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD6D6D6),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.close,
                      size: EcliniqTextStyles.getResponsiveIconSize(context, 20),
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// RESCHEDULE Banner - Red/Orange theme
  Widget _buildRescheduleBanner(BuildContext context) {
    return _buildBannerContainer(
      context,
      backgroundColor: const Color(0xFFFFEBEE),
      iconColor: const Color(0xFFD32F2F),
      title: 'Reschedule Required',
      subtitle: 'Please reschedule your appointment',
    );
  }

  Widget _buildBannerContainer(
    BuildContext context, {
    required Color backgroundColor,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: onTap ?? () => _navigateToAppointmentDetails(context),
      child: Container(
        height: EcliniqTextStyles.getResponsiveHeight(context, 76),
        decoration: BoxDecoration(color: backgroundColor),
        child: Padding(
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
            context,
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildBannerIcon(iconColor, context),
              SizedBox(
                width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: EcliniqText(
                        title,
                        style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                          color: const Color(0xFF424242),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                      SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 2.0)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: EcliniqText(
                          subtitle,
                          style: EcliniqTextStyles.responsiveBodySmallProminent(context).copyWith(
                            color: iconColor,
                          ),
                        ),
                      ),
                    ],
                  ),
              ),
              Container(
                width: EcliniqTextStyles.getResponsiveSize(context, 28.0),
                height: EcliniqTextStyles.getResponsiveSize(context, 28.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD6D6D6),
                    width: EcliniqTextStyles.getResponsiveSize(context, 0.5),
                  ),
                ),
                child: Center(
                  child: Transform.rotate(
                    angle: 90 * 3.14159 / 180,
                    child: SvgPicture.asset(
                      EcliniqIcons.arrowUp.assetPath,
                      width: EcliniqTextStyles.getResponsiveIconSize(context, 20.0),
                      height: EcliniqTextStyles.getResponsiveIconSize(context, 20.0),
                      color: const Color(0xff424242),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the appropriate icon/image widget based on banner type
  Widget _buildBannerIcon(Color iconColor, BuildContext context) {
    final type = banner.type.toUpperCase();
    final status = banner.status.toUpperCase();

    switch (type) {
      case 'REQUESTED':
        return _buildGifIcon(context);

      case 'ACTIVE':
        if (status == 'CONFIRMED') {
          if (banner.isInQueue == true) {
            return _buildSvgIcon();
          } else {
            return _buildSvgIcon();
          }
        }
        return _buildSvgIcon();

      case 'UPCOMING':
        return _buildUpcomingIconContainer(context, iconColor);

      case 'RESCHEDULE':
        return _buildSvgIcon();

      default:
        return Icon(
          Icons.event,
          color: iconColor,
          size: EcliniqTextStyles.getResponsiveIconSize(context, 24),
        );
    }
  }

  /// Build GIF icon widget
  Widget _buildGifIcon(BuildContext context) {
    return Image.asset(
      EcliniqIcons.bannerRequested.assetPath,
      width: EcliniqTextStyles.getResponsiveWidth(context, 60.0),
      height: EcliniqTextStyles.getResponsiveHeight(context, 40.0),
    );
  }

  /// Build SVG icon widget
  Widget _buildSvgIcon() {
    return SvgPicture.asset(EcliniqIcons.bannerConfirmed.assetPath);
  }

  /// Build special container for upcoming appointments
  Widget _buildUpcomingIconContainer(BuildContext context, Color iconColor) {
    return Container(
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
        context,
        horizontal: 6.0,
        vertical: 4.0,
      ),
      decoration: BoxDecoration(
        color: Color(0xff3EAF3F),
        borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          EcliniqText(
            'Date',
            style: EcliniqTextStyles.responsiveBody2xSmallRegular(context).copyWith(
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 2.0),
          ),
          EcliniqText(
            '12 Nov',
            style: EcliniqTextStyles.responsiveHeadlineLargeBold(context).copyWith(
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _navigateToAppointmentDetails(BuildContext context) {
    Widget detailScreen;

    // Determine which detail screen to show based on banner type and status
    final status = banner.status.toUpperCase();
    final type = banner.type.toUpperCase();

    if (type == 'RESCHEDULE' || status == 'CANCELLED') {
      detailScreen = BookingCancelledDetail(
        appointmentId: banner.appointmentId,
      );
    } else if (type == 'REQUESTED' ||
        status == 'PENDING' ||
        status == 'REQUESTED') {
      detailScreen = BookingRequestedDetail(
        appointmentId: banner.appointmentId,
      );
    } else if (type == 'ACTIVE' || status == 'CONFIRMED') {
      detailScreen = BookingConfirmedDetail(
        appointmentId: banner.appointmentId,
      );
    } else if (status == 'COMPLETED' || status == 'SERVED') {
      detailScreen = BookingCompletedDetail(
        appointmentId: banner.appointmentId,
      );
    } else if (type == 'UPCOMING') {
      // For upcoming appointments, check status
      if (status == 'CONFIRMED') {
        detailScreen = BookingConfirmedDetail(
          appointmentId: banner.appointmentId,
        );
      } else {
        detailScreen = BookingRequestedDetail(
          appointmentId: banner.appointmentId,
        );
      }
    } else {
      // Default to requested
      detailScreen = BookingRequestedDetail(
        appointmentId: banner.appointmentId,
      );
    }

    EcliniqRouter.push(detailScreen);
  }
}

/// Widget to display multiple banners in a scrollable list
/// Widget to display multiple banners in a scrollable list
class AppointmentBannersList extends StatelessWidget {
  final List<AppointmentBanner> banners;
  final Function(String)? onBannerTap;
  final Function(String)? onBannerClose;

  const AppointmentBannersList({
    super.key,
    required this.banners,
    this.onBannerTap,
    this.onBannerClose,
  });

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }

    // If multiple banners, show in horizontal scroll, each taking full width
    if (banners.length > 1) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            height: EcliniqTextStyles.getResponsiveHeight(context, 76.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: banners.map((banner) {
                  return SizedBox(
                    width: constraints.maxWidth > 0 ? constraints.maxWidth : MediaQuery.of(context).size.width,
                    height: EcliniqTextStyles.getResponsiveHeight(context, 68.0),
                    child: AppointmentBannerWidget(
                      banner: banner,
                      onTap: onBannerTap != null
                          ? () => onBannerTap!(banner.appointmentId)
                          : null,
                      onClose: onBannerClose != null
                          ? () => onBannerClose!(banner.appointmentId)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      );
    }

    // Single banner - full width
    return SizedBox(
      height: EcliniqTextStyles.getResponsiveHeight(context, 76.0),
      child: AppointmentBannerWidget(
        banner: banners.first,
        onTap: onBannerTap != null
            ? () => onBannerTap!(banners.first.appointmentId)
            : null,
        onClose: onBannerClose != null
            ? () => onBannerClose!(banners.first.appointmentId)
            : null,
      ),
    );
  }
}