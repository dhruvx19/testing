import 'package:ecliniq/ecliniq_api/appointment_service.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/clinic_visit_slot_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/profile_help.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/widgets/common.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class BookingCancelledDetail extends StatefulWidget {
  final String appointmentId;
  final AppointmentDetailModel?
  appointment; 

  const BookingCancelledDetail({
    super.key,
    required this.appointmentId,
    this.appointment,
  });

  @override
  State<BookingCancelledDetail> createState() => _BookingCancelledDetailState();
}

class _BookingCancelledDetailState extends State<BookingCancelledDetail> {
  AppointmentDetailModel? _appointment;
  bool _isLoading = true;
  String? _errorMessage;
  final _appointmentService = AppointmentService();

  @override
  void initState() {
    super.initState();
    
    if (widget.appointment != null) {
      _appointment = widget.appointment;
      _isLoading = false;
    } else {
      _loadAppointmentDetails();
    }
  }

  Future<void> _loadAppointmentDetails() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authToken = authProvider.authToken;

      if (authToken == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Authentication required. Please login again.';
          });
        }
        return;
      }

      final response = await _appointmentService.getAppointmentDetail(
        appointmentId: widget.appointmentId,
        authToken: authToken,
      );

      if (!mounted) return;

      if (!response.success || response.data == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = response.message;
        });
        return;
      }

      
      final appointmentDetail = AppointmentDetailModel.fromApiData(
        response.data!,
      );

      if (!mounted) return;

      setState(() {
        _appointment = appointmentDetail;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load appointment details: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
          leadingWidth: EcliniqTextStyles.getResponsiveWidth(context, 54.0),
          titleSpacing: 0,
          toolbarHeight: EcliniqTextStyles.getResponsiveHeight(context, 46.0),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.arrowLeft.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 32),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 32),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Booking Detail',
            style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
              color: Color(0xff424242),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.2),
          child: Container(color: Color(0xFFB8B8B8), height: 0.5),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              EcliniqRouter.push(ProfileHelpPage());
            },
            child: Row(
              children: [
                SvgPicture.asset(
                  EcliniqIcons.questionCircleFilled.assetPath,
                  width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                  height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                ),
                Text(
                  ' Help',
                  style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                    color: Color(0xff424242),
             
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 20)),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : _errorMessage != null
          ? _buildErrorWidget()
          : _appointment == null
          ? _buildErrorWidget()
          : Stack(
              children: [
                _buildContent(),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomButton(context),
                ),
              ],
            ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Column(
        children: [
          
          Container(
            height: EcliniqTextStyles.getResponsiveHeight(context, 120),
            margin: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16),
            child: ShimmerLoading(
              borderRadius: BorderRadius.circular(
                EcliniqTextStyles.getResponsiveBorderRadius(context, 12),
              ),
            ),
          ),
          Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveHeight(context, 150),
                  child: ShimmerLoading(
                    borderRadius: BorderRadius.circular(
                      EcliniqTextStyles.getResponsiveBorderRadius(context, 12),
                    ),
                  ),
                ),
                SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 24)),
                
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveHeight(context, 200),
                  child: ShimmerLoading(
                    borderRadius: BorderRadius.circular(
                      EcliniqTextStyles.getResponsiveBorderRadius(context, 12),
                    ),
                  ),
                ),
                SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 24)),
                
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveHeight(context, 120),
                  child: ShimmerLoading(
                    borderRadius: BorderRadius.circular(
                      EcliniqTextStyles.getResponsiveBorderRadius(context, 12),
                    ),
                  ),
                ),
                SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 24)),
                
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveHeight(context, 100),
                  child: ShimmerLoading(
                    borderRadius: BorderRadius.circular(
                      EcliniqTextStyles.getResponsiveBorderRadius(context, 12),
                    ),
                  ),
                ),
                SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 24)),
                
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveHeight(context, 120),
                  child: ShimmerLoading(
                    borderRadius: BorderRadius.circular(
                      EcliniqTextStyles.getResponsiveBorderRadius(context, 12),
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

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: EcliniqTextStyles.getResponsiveIconSize(context, 64),
              color: Colors.red[300],
            ),
            SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 16)),
            Text(
              _errorMessage ?? 'Failed to load appointment details',
              style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith( color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 24)),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadAppointmentDetails();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        
        StatusHeader(
          status: _appointment!.status,
          displayDate: _appointment!.timeInfo.displayDate,
        ),
        Padding(
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16),
          child: DoctorInfoCard(
            doctor: _appointment!.doctor,
            clinic: _appointment!.clinic,
            isSimplified: true,
          ),
        ),
        
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                context,
                horizontal: 16,
                vertical: 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 10)),
                  AppointmentDetailsSection(
                    patient: _appointment!.patient,
                    timeInfo: _appointment!.timeInfo,
                  ),
                  SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 8)),
                  ClinicLocationCard(clinic: _appointment!.clinic),
                  SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 16)),
                  Divider(color: Color(0xffB8B8B8), thickness: 0.5, height: 1),
                  SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 24)),
                  PaymentDetailsCard(payment: _appointment!.payment),
                  SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 40)),
                  _buildCallbackSection(),
                  SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 100)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCallbackSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child:  Text(
                'Easy Way to book',
                style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
        
                  fontWeight: FontWeight.w600,
                  color: Color(0xff424242),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 16)),
        Column(
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  EcliniqIcons.call.assetPath,
                  width: EcliniqTextStyles.getResponsiveIconSize(context, 32),
                  height: EcliniqTextStyles.getResponsiveIconSize(context, 32),
                ),
                SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 12)),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(
                        'Request a Callback',
                        style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                   
                          fontWeight: FontWeight.w500,
                          color: Color(0xff424242),
                        ),
                      ),
                      SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 2)),
                      Text(
                        'Assisted booking with expert',
                        style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                          
                          color: Color(0xff8E8E8E),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                      context,
                      horizontal: 14,
                      vertical: 7,
                    ),
                    side: const BorderSide(
                      color: Color(0xFF96BFFF),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(context, 8),
                      ),
                    ),
                    backgroundColor: Color(0xFFF2F7FF),
                  ),
                  child:  Text(
                    'Call Us',
                    style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                      color: Color(0xFF2372EC),
              
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 16)),

            Divider(
              height: 1,
              thickness: 0.5,
              color: Color(0xffB8B8B8),
              indent: 6,
              endIndent: 6,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
        context,
        top: 16,
        left: 16,
        right: 16,
        bottom: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: BookingActionButton(
          label: 'Book Again',
          type: BookingButtonType.primary,
          onPressed: () {
            if (_appointment?.doctorId != null && 
                (_appointment?.hospitalId != null || _appointment?.clinicId != null)) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClinicVisitSlotScreen(
                    doctorId: _appointment!.doctorId!,
                    hospitalId: _appointment!.hospitalId,
                    clinicId: _appointment!.clinicId,
                    doctorName: _appointment!.doctor.name,
                    doctorSpecialization: _appointment!.doctor.specialization,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
