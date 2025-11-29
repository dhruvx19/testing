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
  appointment; // Optional for backward compatibility

  const BookingCompletedDetail({
    Key? key,
    required this.appointmentId,
    this.appointment,
  }) : super(key: key);

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
    // If appointment is provided, use it directly (backward compatibility)
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

      // Convert API response to UI model
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
          child: const Text(
            'Booking Detail',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
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
          // Status header shimmer
          Container(
            height: 120,
            margin: const EdgeInsets.all(16),
            child: ShimmerLoading(borderRadius: BorderRadius.circular(12)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor info card shimmer
                Container(
                  height: 150,
                  child: ShimmerLoading(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 24),
                // Rating section shimmer
                Container(
                  height: 100,
                  child: ShimmerLoading(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 24),
                // Appointment details shimmer
                Container(
                  height: 200,
                  child: ShimmerLoading(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 24),
                // Clinic location shimmer
                Container(
                  height: 120,
                  child: ShimmerLoading(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 24),
                // Prescription section shimmer
                Container(
                  height: 100,
                  child: ShimmerLoading(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 24),
                // Payment details shimmer
                Container(
                  height: 100,
                  child: ShimmerLoading(
                    borderRadius: BorderRadius.circular(12),
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to load appointment details',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
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
    return SingleChildScrollView(
      child: Column(
        children: [
          StatusHeader(status: _appointment!.status),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DoctorInfoCard(
                  doctor: _appointment!.doctor,
                  clinic: _appointment!.clinic,
                  isSimplified: true,
                ),
                const SizedBox(height: 12),

                const SizedBox(height: 24),
                RatingSection(
                  initialRating: _userRating,
                  onRatingChanged: (rating) {
                    setState(() {
                      _userRating = rating;
                    });
                    _submitRating(rating);
                  },
                  doctorName: _appointment!.doctor.name,
                  appointmentId: _appointment!.id,
                ),
                const SizedBox(height: 24),
                AppointmentDetailsSection(
                  patient: _appointment!.patient,
                  timeInfo: _appointment!.timeInfo,
                ),
                const SizedBox(height: 24),
                ClinicLocationCard(clinic: _appointment!.clinic),
                const SizedBox(height: 24),
                PaymentDetailsCard(payment: _appointment!.payment),
                const SizedBox(height: 40),
                _buildCallbackSection(),
                const SizedBox(height: 24),
                _buildBottomButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallbackSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: const Text(
                'Easy Way to book',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff424242),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Column(
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  EcliniqIcons.call.assetPath,
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Request a Callback',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff424242),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Assisted booking with expert',
                        style: TextStyle(
                          fontSize: 14,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    side: const BorderSide(
                      color: Color(0xFF96BFFF),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Color(0xFFF2F7FF),
                  ),
                  child: const Text(
                    'Call Us',
                    style: TextStyle(
                      color: Color(0xFF2372EC),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

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
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Colors.white),
      child: BookingActionButton(
        label: 'Book Again',
        type: BookingButtonType.primary,
        onPressed: () {
          // Handle book again
        },
      ),
    );
  }

  Future<void> _submitRating(int rating) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authToken = authProvider.authToken;

      if (authToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication required. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final appointmentId = _appointment?.id ?? widget.appointmentId;
      final res = await _appointmentService.rateAppointment(
        appointmentId: appointmentId,
        rating: rating,
        authToken: authToken,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        setState(() {
          _userRating = rating;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Appointment rated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Failed to submit rating'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit rating: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
