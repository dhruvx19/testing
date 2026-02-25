import 'package:ecliniq/ecliniq_api/appointment_service.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/widgets/common.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class BookingCompletedDetail extends StatefulWidget {
  final String appointmentId;
  final AppointmentDetailModel?
  appointment; 

  const BookingCompletedDetail({
    super.key,
    required this.appointmentId,
    this.appointment,
  });

  @override
  State<BookingCompletedDetail> createState() => _BookingCompletedDetailState();
}

class _BookingCompletedDetailState extends State<BookingCompletedDetail> {
  AppointmentDetailModel? _appointment;
  bool _isLoading = true;
  String? _errorMessage;
  int _userRating = 0;
  final _appointmentService = AppointmentService();

  @override
  void initState() {
    super.initState();
    
    if (widget.appointment != null) {
      _appointment = widget.appointment;
      _isLoading = false;
      _userRating = _appointment!.rating ?? 0;
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
        _userRating = appointmentDetail.rating ?? 0;
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Booking Detail',
            style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
              color: Colors.black,

              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : _errorMessage != null
          ? _buildErrorWidget()
          : _appointment == null
          ? _buildErrorWidget()
          : _buildContent(),
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
                  height: EcliniqTextStyles.getResponsiveHeight(context, 100),
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
                  height: EcliniqTextStyles.getResponsiveHeight(context, 100),
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
              style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(color: Colors.grey[700]),
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
        
        StatusHeader(status: _appointment!.status),
        Padding(
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16),
          child: DoctorInfoCard(
            doctor: _appointment!.doctor,
            clinic: _appointment!.clinic,
            isSimplified: true,
          ),
        ),
        SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 12)),
        Padding(
          padding: EdgeInsets.zero,
          child: RatingSection(
            initialRating: _userRating,
            onRatingChanged: _userRating == 0
                ? (rating) {
                    setState(() {
                      _userRating = rating;
                    });
                  }
                : null,
            doctorName: _appointment!.doctor.name,
            appointmentId: _appointment!.id,
            showAsReadOnly: _userRating > 0,
            onRefetch: _loadAppointmentDetails,
          ),
        ),
        SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 24)),
        
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16),
              child: Column(
                children: [
                  AppointmentDetailsSection(
                    patient: _appointment!.patient,
                    timeInfo: _appointment!.timeInfo,
                    clinic: _appointment!.clinic,
                  ),
                  SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 24)),
                  ClinicLocationCard(clinic: _appointment!.clinic),
                  SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 24)),
                  PaymentDetailsCard(payment: _appointment!.payment),
                  SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 40)),
                  _buildCallbackSection(),
                  SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 24)),
                  _buildBottomButton(context),
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
      width: double.infinity,

      padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 4),
      decoration: BoxDecoration(color: Colors.white),
      child: BookingActionButton(
        label: 'Book Again',
        type: BookingButtonType.primary,
        onPressed: () {
          
        },
      ),
    );
  }
}
