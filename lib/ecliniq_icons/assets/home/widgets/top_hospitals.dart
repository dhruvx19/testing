import 'package:ecliniq/ecliniq_api/models/hospital.dart';
import 'package:ecliniq/ecliniq_api/storage_service.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/provider/hospital_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/hospital/pages/hospital_details.dart';
import 'package:ecliniq/ecliniq_modules/screens/hospital/pages/hospital_doctors.dart';
import 'package:ecliniq/ecliniq_modules/screens/search_specialities/speciality_hospital_list.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/button/button.dart';
import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class TopHospitalsWidget extends StatefulWidget {
  const TopHospitalsWidget({super.key});

  @override
  State<TopHospitalsWidget> createState() => _TopHospitalsWidgetState();
}

class _TopHospitalsWidgetState extends State<TopHospitalsWidget>
    with WidgetsBindingObserver {
  bool _isButtonPressed = false;
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hospitalProvider = Provider.of<HospitalProvider>(
        context,
        listen: false,
      );
      if (hospitalProvider.hasLocation && !hospitalProvider.hasHospitals) {
        _fetchHospitals();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isButtonPressed) {
      setState(() {
        _isButtonPressed = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isButtonPressed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isButtonPressed = false;
          });
        }
      });
    }
  }

  Future<void> _fetchHospitals() async {
    final hospitalProvider = Provider.of<HospitalProvider>(
      context,
      listen: false,
    );

    // Use hardcoded location values
    await hospitalProvider.fetchTopHospitals(
      latitude: 12.9173,
      longitude: 77.6377,
      isRefresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HospitalProvider>(
      builder: (context, hospitalProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: EcliniqTextStyles.getResponsiveSize(context, 8.0),
                      height: EcliniqTextStyles.getResponsiveSize(context,  24.0),
                      decoration: BoxDecoration(
                        color: Color(0xFF96BFFF),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context,  4.0)),
                          bottomRight: Radius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context,  4.0)),
                        ),
                      ),
                    ),
                    SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 12.0)),
                    Expanded(
                      child: EcliniqText(
                        'Top Hospitals',
                        style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                          color: Color(0xff424242),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        EcliniqRouter.push(SpecialityHospitalList());
                      },
                      style: TextButton.styleFrom(
                        padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                          context,
                          horizontal: 8.0,
                          vertical: 0.0,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          EcliniqText(
                            'View All',
                            style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                              color: Color(0xFF2372EC),
                            ),
                          ),
                          SvgPicture.asset(
                            EcliniqIcons.arrowRightBlue.assetPath,
                            width: EcliniqTextStyles.getResponsiveIconSize(context,  24.0),
                            height: EcliniqTextStyles.getResponsiveIconSize(context,  24.0),
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF2372EC),
                              BlendMode.srcIn,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                Padding(
                  padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                    context,
                    left: 20.0,
                  ),
                  child: EcliniqText(
                    'Near you',
                    style: EcliniqTextStyles.responsiveBodyMediumProminent(context).copyWith(
                      color: Color(0xff8E8E8E),
                       fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context,  16.0)),
            _buildHospitalsList(hospitalProvider),
          ],
        );
      },
    );
  }

  Widget _buildHospitalsList(HospitalProvider hospitalProvider) {
    if (hospitalProvider.isLoading) {
      return _buildShimmerList();
    }

    if (hospitalProvider.errorMessage != null) {
      return _buildErrorWidget(hospitalProvider);
    }

    if (!hospitalProvider.hasLocation) {
      return SizedBox();
    }

    if (!hospitalProvider.hasHospitals) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
        context,
        horizontal: 16.0, vertical: 0,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: hospitalProvider.hospitals.asMap().entries.map((entry) {
            final index = entry.key;
            final hospital = entry.value;
            return Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                context,
                right: index < hospitalProvider.hospitals.length - 1
                    ? EcliniqTextStyles.getResponsiveSpacing(context,  16.0)
                    : 0,
              ),
              child: _buildHospitalCard(context, hospital),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.separated(
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
        context,
        horizontal: 16.0, vertical: 0,
      ),
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      separatorBuilder: (context, index) => SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context,  16.0)),
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      width: EcliniqTextStyles.getResponsiveWidth(context,  350.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context,  16.0)),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: EcliniqTextStyles.getResponsiveHeight(context,  196.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context,  16.0)),
                  topRight: Radius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context,  16.0)),
                ),
              ),
            ),
          ),

          Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context,  14.0)),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: EcliniqTextStyles.getResponsiveSize(context,  20.0),
                    width: EcliniqTextStyles.getResponsiveWidth(context,  200.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context,  4.0)),
                    ),
                  ),
                ),
                SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context,  8.0)),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: EcliniqTextStyles.getResponsiveSize(context,  16.0),
                    width: EcliniqTextStyles.getResponsiveWidth(context,  150.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context,  4.0)),
                    ),
                  ),
                ),
                SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context,  12.0)),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: EcliniqTextStyles.getResponsiveSize(context,  16.0),
                    width: EcliniqTextStyles.getResponsiveWidth(context,  100.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0)),
                    ),
                  ),
                ),
                SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context,  12.0)),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: EcliniqTextStyles.getResponsiveSize(context,  16.0),
                    width: EcliniqTextStyles.getResponsiveWidth(context,  180.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0)),
                    ),
                  ),
                ),
                SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context,  16.0)),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: EcliniqTextStyles.getResponsiveButtonHeight(context, baseHeight: 48.0),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context,  8.0)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(HospitalProvider hospitalProvider) {
    return Center(
      child: Padding(
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context,  32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: EcliniqTextStyles.getResponsiveIconSize(context,  64.0),
              color: Colors.grey.shade400,
            ),
            SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context,  16.0)),
            EcliniqText(
              'Failed to load hospitals',
              style: EcliniqTextStyles.responsiveHeadlineZMedium(context).copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 8.0)),
            EcliniqText(
              hospitalProvider.errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context,  24.0)),
            ElevatedButton(
              onPressed: () => hospitalProvider.retry(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context,  8.0)),
                ),
              ),
              child: const EcliniqText('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context,  32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_hospital_outlined,
              size: EcliniqTextStyles.getResponsiveIconSize(context,  64.0),
              color: Colors.grey.shade400,
            ),
            SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context,  16.0)),
            EcliniqText(
              'No Hospitals Found',
              style: EcliniqTextStyles.responsiveHeadlineZMedium(context).copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context,  8.0)),
            EcliniqText(
              'No hospitals found in your area',
              textAlign: TextAlign.center,
              style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalCard(BuildContext context, Hospital hospital) {
    bool isButtonPressed = false;

    Future<void> bookClinicVisit() async {
      setState(() {
        isButtonPressed = true;
      });

      try {
        final authToken = await SessionService.getAuthToken();
        if (authToken == null || authToken.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: EcliniqText('Please log in to view doctors'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        if (mounted) {
          EcliniqRouter.push(
            HospitalDoctorsScreen(
              hospitalId: hospital.id,
              hospitalName: hospital.name,
              authToken: authToken,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load doctors: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            isButtonPressed = false;
          });
        }
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          EcliniqRouter.push(HospitalDetailScreen(hospitalId: hospital.id));
        },
        borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 16.0)),
        child: Container(
          width: EcliniqTextStyles.getResponsiveWidth(context, 350.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context,  16.0)),
            border: Border.all(color: Color(0xffD6D6D6), width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context,  12.0),
                    child: Container(
                      height: EcliniqTextStyles.getResponsiveHeight(context,  196.0),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context,  16.0)),
                          topRight: Radius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context,  16.0)),
                        ),
                        color: Colors.grey.shade100,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(
                          Radius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context,  12.0)),
                        ),
                        child: FutureBuilder<String?>(
                          future: hospital.getImageUrl(_storageService),
                          builder: (context, snapshot) {
                            final imageUrl = snapshot.data;
                            if (imageUrl != null && imageUrl.isNotEmpty) {
                              return Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildImagePlaceholder(hospital.name);
                                },
                              );
                            }
                            return _buildImagePlaceholder(hospital.name);
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: EcliniqTextStyles.getResponsiveSize(context,  14.0),
                    top: EcliniqTextStyles.getResponsiveSize(context,  126.0),
                    child: Container(
                      width: EcliniqTextStyles.getResponsiveSize(context,  80.0),
                      height: EcliniqTextStyles.getResponsiveSize(context,  80.0),
                      decoration: BoxDecoration(
                        color: Color(0xffF8FAFF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color(0xff96BFFF),
                          width: 0.5,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: FutureBuilder<String?>(
                              future: hospital.getLogoUrl(_storageService),
                              builder: (context, snapshot) {
                                final logoUrl = snapshot.data;
                                if (logoUrl != null && logoUrl.isNotEmpty) {
                                  return ClipOval(
                                    child: Image.network(
                                      logoUrl,
                                      width: EcliniqTextStyles.getResponsiveSize(context, 80.0),
                                      height: EcliniqTextStyles.getResponsiveSize(context, 80.0),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return EcliniqText(
                                          hospital.name.isNotEmpty
                                              ? hospital.name.substring(0, 1)
                                              : 'H',
                                          style: EcliniqTextStyles.responsiveHeadlineXXXLarge(context)
                                              .copyWith(color: Colors.blue.shade700),
                                        );
                                      },
                                    ),
                                  );
                                }
                                return EcliniqText(
                                  hospital.name.isNotEmpty
                                      ? hospital.name.substring(0, 1)
                                      : 'H',
                                  style: EcliniqTextStyles.responsiveHeadlineXXXLarge(context)
                                      .copyWith(color: Colors.blue.shade700),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            right: -2,
                            top: -2,
                            child: SvgPicture.asset(
                              EcliniqIcons.verified.assetPath,
                              width: EcliniqTextStyles.getResponsiveIconSize(context,  24.0),
                              height: EcliniqTextStyles.getResponsiveIconSize(context,  24.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                  context,
                  left: 12.0,
                  right: 12.0,
                  bottom: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EcliniqText(
                      hospital.name,
                      style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                        color: Color(0xff424242),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    EcliniqText(
                      '${hospital.type} | ${hospital.numberOfDoctors}+ Doctors',
                      style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                        color: Color(0xff424242),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context,  2.0)),
                    Row(
                      children: [
                        Container(
                          padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                            context,
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xffFEF9E6),
                            borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context,  4.0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                EcliniqIcons.star.assetPath,
                                width: EcliniqTextStyles.getResponsiveIconSize(context,  18.0),
                                height: EcliniqTextStyles.getResponsiveIconSize(context,  18.0),
                              ),
                              SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context,  2.0)),
                              EcliniqText(
                                '4.0',
                                style: EcliniqTextStyles.responsiveTitleXBLarge(context).copyWith(
                                  color: Color(0xffBE8B00),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context,  8.0)),
                        Container(
                          width: EcliniqTextStyles.getResponsiveSize(context,  6.0),
                          height: EcliniqTextStyles.getResponsiveSize(context,  6.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8E8E8E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context,  8.0)),
                        EcliniqText(
                          'Est in ${hospital.establishmentYear}',
                          style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                            color: Color(0xff424242),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 4.0)),
                    Row(
                      children: [
                        SvgPicture.asset(
                          EcliniqIcons.mapPointBlack.assetPath,
                          width: EcliniqTextStyles.getResponsiveIconSize(context,  24.0),
                          height: EcliniqTextStyles.getResponsiveIconSize(context,  24.0),
                        ),
                        SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context,  2.0)),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: EcliniqText(
                                  '${hospital.city}, ${hospital.state}',
                                  style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                                    color: Color(0xff626060),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0)),
                              Container(
                                padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                                  context,
                                  horizontal: 8.0,
                                  vertical: 4.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xffF9F9F9),
                                  borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context,  4.0)),
                                  border: Border.all(
                                    color: Color(0xffB8B8B8),
                                    width: 0.5,
                                  ),
                                ),
                                child: EcliniqText(
                                  hospital.distance > 0
                                      ? '${hospital.distance.toStringAsFixed(1)} Km'
                                      : 'Nearby',
                                  style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                                    color: Color(0xff424242),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context,  16.0)),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: EcliniqTextStyles.getResponsiveButtonHeight(
                              context, 
                              baseHeight: 52.0,
                              debugPrint: true,
                              debugLabel: 'TopHospitals - Book Clinic Visit',
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context,  4.0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x4D2372EC),
                                    offset: Offset(2, 2),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: bookClinicVisit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isButtonPressed
                                      ? Color(0xFF0E4395)
                                      : EcliniqButtonType.brandPrimary
                                            .backgroundColor(context),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context,  4.0)),
                                  ),
                                  elevation: 0,
                                  padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                                    context,
                                    horizontal: 12.0, vertical: 0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    EcliniqText(
                                      'View All Doctors',
                                      style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                                          .copyWith(color: Colors.white),
                                      maxLines: 1,
                                    ),
                                    SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context,  2.0)),
                                    SvgPicture.asset(
                                      EcliniqIcons.arrowRight.assetPath,
                                      width: EcliniqTextStyles.getResponsiveIconSize(context,  24.0),
                                      height: EcliniqTextStyles.getResponsiveIconSize(context,  24.0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context,  22.0)),
                        SvgPicture.asset(
                          EcliniqIcons.phone.assetPath,
                          width: EcliniqTextStyles.getResponsiveIconSize(context,  32.0),
                          height: EcliniqTextStyles.getResponsiveIconSize(context,  32.0),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isValidImageUrl(String url) {
    if (url.startsWith('file://') || url.startsWith('/hospitals/')) {
      return false;
    }
    return url.startsWith('http://') || url.startsWith('https://');
  }

  Widget _buildImagePlaceholder(String hospitalName) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade100, Colors.blue.shade50],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_hospital,
          size: 40,
          color: Colors.blue.shade300,
        ),
      ),
    );
  }
}
