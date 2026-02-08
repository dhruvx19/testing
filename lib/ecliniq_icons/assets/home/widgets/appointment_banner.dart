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

class AppointmentBanner {
  final String type;
  final String appointmentId;
  final String doctorName;
  final String doctorSpecialization;
  final int? tokenNumber;
  final String appointmentDate;
  final String appointmentDateFormatted;
  final String appointmentTime;
  final String hospitalName;
  final String bookedFor;
  final String patientName;
  final String status;
  final bool? isInQueue;

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
        return _buildUpcomingBanner(context);
    }
  }

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
              SizedBox(
                width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
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
                        'Your Appointment Requested!',
                        style: EcliniqTextStyles.responsiveBodySmall(
                          context,
                        ).copyWith(color: const Color(0xFF424242)),
                      ),
                    ),
                    SizedBox(
                      height: EcliniqTextStyles.getResponsiveSpacing(
                        context,
                        2.0,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: EcliniqText(
                        'Waiting For Doctor to Confirm...',
                        style: EcliniqTextStyles.responsiveBodySmallProminent(
                          context,
                        ).copyWith(color: const Color(0xFFBE8B00)),
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
                      width: EcliniqTextStyles.getResponsiveIconSize(
                        context,
                        20.0,
                      ),
                      height: EcliniqTextStyles.getResponsiveIconSize(
                        context,
                        20.0,
                      ),
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

  Widget _buildActiveBanner(BuildContext context) {
    String subtitle = '';
    if (banner.tokenNumber != null) {
      subtitle = 'Your Token #${banner.tokenNumber}';
      if (banner.isInQueue == true) {
        subtitle += ' (In Queue)';
      } else {
        subtitle += ' (Queue Not Started)';
      }
    } else {
      subtitle = banner.appointmentTime;
    }

    return _buildBannerContainer(
      context,
      backgroundColor: const Color(0xFFF2FFF3),
      iconColor: const Color(0xFF3EAF3F),
      title: 'Appointment Confirmed With ${banner.doctorName}',
      subtitle: subtitle,
    );
  }

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
                        style: EcliniqTextStyles.responsiveBodyLarge(
                          context,
                        ).copyWith(color: const Color(0xFF3EAF3F)),
                      ),
                    ),
                    SizedBox(
                      height: EcliniqTextStyles.getResponsiveSpacing(
                        context,
                        2,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: EcliniqText(
                        subtitle,
                        style: EcliniqTextStyles.responsiveBodySmall(
                          context,
                        ).copyWith(color: const Color(0xFF424242)),
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
                      size: EcliniqTextStyles.getResponsiveIconSize(
                        context,
                        20,
                      ),
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

  Widget _buildRescheduleBanner(BuildContext context) {
    return _buildBannerContainer(
      context,
      backgroundColor: const Color(0xFFFFEBEE),
      iconColor: const Color(0xFFFFF8F8),
      title: 'Your Appointment Requested!',
      subtitle: 'Doctor Asked to Rescheduled the Appointment',
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
                    EcliniqText(
                      title,
                      style: EcliniqTextStyles.responsiveBodySmall(context)
                          .copyWith(
                            color: const Color(0xFF424242),
                            overflow: TextOverflow.ellipsis,
                          ),
                    ),
                    SizedBox(
                      height: EcliniqTextStyles.getResponsiveSpacing(
                        context,
                        2.0,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: EcliniqText(
                        subtitle,
                        style: EcliniqTextStyles.responsiveBodySmallProminent(
                          context,
                        ).copyWith(color: iconColor),
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
                      width: EcliniqTextStyles.getResponsiveIconSize(
                        context,
                        20.0,
                      ),
                      height: EcliniqTextStyles.getResponsiveIconSize(
                        context,
                        20.0,
                      ),
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
        return _buildGifIcon(context);

      default:
        return Icon(
          Icons.event,
          color: iconColor,
          size: EcliniqTextStyles.getResponsiveIconSize(context, 24),
        );
    }
  }

  Widget _buildGifIcon(BuildContext context) {
    return Image.asset(
      EcliniqIcons.bannerRequested.assetPath,
      width: EcliniqTextStyles.getResponsiveWidth(context, 60.0),
      height: EcliniqTextStyles.getResponsiveHeight(context, 40.0),
    );
  }

  Widget _buildSvgIcon() {
    return SvgPicture.asset(EcliniqIcons.bannerConfirmed.assetPath);
  }

  Widget _buildUpcomingIconContainer(BuildContext context, Color iconColor) {
    return Container(
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
        context,
        horizontal: 6.0,
        vertical: 4.0,
      ),
      decoration: BoxDecoration(
        color: Color(0xff3EAF3F),
        borderRadius: BorderRadius.circular(
          EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            EcliniqText(
              banner.appointmentTime.isNotEmpty
                  ? banner.appointmentTime
                  : 'Date',
              style: EcliniqTextStyles.responsiveBody2xSmallRegular(
                context,
              ).copyWith(color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 2.0),
            ),
            EcliniqText(
              banner.appointmentDateFormatted.isNotEmpty
                  ? banner.appointmentDateFormatted
                  : 'N/A',
              style: EcliniqTextStyles.responsiveHeadlineLargeBold(
                context,
              ).copyWith(color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAppointmentDetails(BuildContext context) {
    Widget detailScreen;

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
      detailScreen = BookingRequestedDetail(
        appointmentId: banner.appointmentId,
      );
    }

    EcliniqRouter.push(detailScreen);
  }
}

class AppointmentBannersList extends StatefulWidget {
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
  State<AppointmentBannersList> createState() => _AppointmentBannersListState();
}

class _AppointmentBannersListState extends State<AppointmentBannersList> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void didUpdateWidget(covariant AppointmentBannersList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.banners.length != oldWidget.banners.length) {
      if (_currentPage >= widget.banners.length) {
        _currentPage = widget.banners.isEmpty ? 0 : widget.banners.length - 1;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    if (widget.banners.length == 1) {
      return SizedBox(
        height: EcliniqTextStyles.getResponsiveHeight(context, 76.0),
        child: AppointmentBannerWidget(
          banner: widget.banners.first,
          onTap: widget.onBannerTap != null
              ? () => widget.onBannerTap!(widget.banners.first.appointmentId)
              : null,
          onClose: widget.onBannerClose != null
              ? () => widget.onBannerClose!(widget.banners.first.appointmentId)
              : null,
        ),
      );
    }

    return SizedBox(
      height: EcliniqTextStyles.getResponsiveHeight(context, 76.0),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.banners.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return AppointmentBannerWidget(
                banner: banner,
                onTap: widget.onBannerTap != null
                    ? () => widget.onBannerTap!(banner.appointmentId)
                    : null,
                onClose: widget.onBannerClose != null
                    ? () => widget.onBannerClose!(banner.appointmentId)
                    : null,
              );
            },
          ),
          // Carousel indicators - centered with the arrow icon
          Positioned(
            bottom: EcliniqTextStyles.getResponsiveSpacing(context, 14.0),
            right: EcliniqTextStyles.getResponsiveSpacing(context, 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: _buildCarouselIndicators(context),
            ),
          ),
        ],
      ),
    );
  }

  // Build carousel indicators with max 3 dots display
  List<Widget> _buildCarouselIndicators(BuildContext context) {
    final totalBanners = widget.banners.length;

    // Don't show indicators if only 1 banner
    if (totalBanners <= 1) {
      return [];
    }

    // If 3 or fewer banners, show all dots
    if (totalBanners <= 3) {
      return List.generate(
        totalBanners,
        (index) => _buildDot(context, index == _currentPage),
      );
    }

    // For more than 3 banners, show max 3 dots with logic
    List<Widget> dots = [];

    if (_currentPage == 0) {
      // First page: show [active, inactive, inactive]
      dots.add(_buildDot(context, true));
      dots.add(_buildDot(context, false));
      dots.add(_buildDot(context, false));
    } else if (_currentPage == totalBanners - 1) {
      // Last page: show [inactive, inactive, active]
      dots.add(_buildDot(context, false));
      dots.add(_buildDot(context, false));
      dots.add(_buildDot(context, true));
    } else {
      // Middle pages: show [inactive, active, inactive]
      dots.add(_buildDot(context, false));
      dots.add(_buildDot(context, true));
      dots.add(_buildDot(context, false));
    }

    return dots;
  }

  Widget _buildDot(BuildContext context, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(
        horizontal: EcliniqTextStyles.getResponsiveSpacing(context, 2.0),
      ),
      width: EcliniqTextStyles.getResponsiveSize(context, 8.0),
      height: EcliniqTextStyles.getResponsiveSize(context, 2.0),
      decoration: BoxDecoration(
        color: isActive ? Color(0xff2372EC) : Color(0xff96BFFF),
        borderRadius: BorderRadius.circular(
          EcliniqTextStyles.getResponsiveBorderRadius(context, 13.0),
        ),
      ),
    );
  }
}
