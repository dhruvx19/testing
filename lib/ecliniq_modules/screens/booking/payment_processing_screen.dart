import 'dart:async';
import 'package:ecliniq/ecliniq_api/payment_service.dart';
import 'package:ecliniq/ecliniq_api/models/payment.dart';
import 'package:ecliniq/ecliniq_api/appointment_service.dart';
import 'package:ecliniq/ecliniq_api/models/appointment.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/booking_confirmed_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/request_sent.dart';
import 'package:ecliniq/ecliniq_services.dart/phonepe_service.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class PaymentProcessingScreen extends StatefulWidget {
  final String appointmentId;
  final String merchantTransactionId;
  final String? token; 
  final String? orderId; 
  final String? requestPayload; 
  final double totalAmount;
  final double walletAmount;
  final double gatewayAmount;
  final String provider;

  
  final String appSchema;

  
  final String? selectedUPIPackage;

  
  final String? doctorName;
  final String? doctorSpecialization;
  final String? selectedSlot;
  final String? selectedDate;
  final String? hospitalAddress;
  final String? patientName;
  final String? patientSubtitle;
  final String? patientBadge;

  const PaymentProcessingScreen({
    super.key,
    required this.appointmentId,
    required this.merchantTransactionId,
    this.token,
    this.orderId,
    this.requestPayload,
    required this.totalAmount,
    required this.walletAmount,
    required this.gatewayAmount,
    required this.provider,
    this.appSchema = 'ecliniq', 
    this.selectedUPIPackage,
    this.doctorName,
    this.doctorSpecialization,
    this.selectedSlot,
    this.selectedDate,
    this.hospitalAddress,
    this.patientName,
    this.patientSubtitle,
    this.patientBadge,
  });

  @override
  State<PaymentProcessingScreen> createState() => _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen> {
  final PaymentService _paymentService = PaymentService();
  final AppointmentService _appointmentService = AppointmentService();
  final PhonePeService _phonePeService = PhonePeService();

  PaymentStatus _currentStatus = PaymentStatus.initiating;
  String _statusMessage = 'Initializing payment...';
  String? _errorMessage;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadAuthTokenAndInitiate();
  }

  Future<void> _loadAuthTokenAndInitiate() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    await _initializeAndStartPayment();
  }

  Future<void> _initializeAndStartPayment() async {
    try {
      if (widget.requestPayload != null) {
      }
      
      
      if (widget.requestPayload == null || widget.requestPayload!.isEmpty) {
        if (widget.token == null || widget.token!.isEmpty) {
          throw PhonePeException('Payment token is missing. Please try booking again.');
        }
        if (widget.orderId == null || widget.orderId!.isEmpty) {
          throw PhonePeException('Order ID is missing. Please try booking again.');
        }
      }
      
      setState(() {
        _currentStatus = PaymentStatus.initiating;
        _statusMessage = 'Preparing payment...';
      });

      
      if (!_phonePeService.isInitialized) {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id') ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
        
        
        const merchantId = 'SU2512271831021904206385';
        const isProduction = true;

        final initialized = await _phonePeService.initialize(
          isProduction: isProduction,
          merchantId: merchantId,
          flowId: userId,
          enableLogs: !isProduction,
        );


        if (!initialized) {
          throw PhonePeException('Failed to initialize PhonePe SDK');
        }
      }

      
      await _startPhonePePayment();
    } catch (e) {
      setState(() {
        _currentStatus = PaymentStatus.failed;
        _statusMessage = 'Payment initialization failed';
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _openUPIApp(String packageName) async {
    try {
      if (Platform.isAndroid) {
        
        final uri = Uri.parse('package:$packageName');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          
          final intentUri = Uri.parse('intent://#Intent;package=$packageName;end');
          if (await canLaunchUrl(intentUri)) {
            await launchUrl(intentUri, mode: LaunchMode.externalApplication);
          }
        }
      }
    } catch (e) {
      
      
    }
  }

  Future<void> _startPhonePePayment() async {
    try {
      
      if (widget.requestPayload == null || widget.requestPayload!.isEmpty) {
        if (widget.token == null || widget.token!.isEmpty) {
          throw PhonePeException('Payment token is empty. Please try booking again.');
        }
      }

      setState(() {
        _currentStatus = PaymentStatus.processing;
        _statusMessage = 'Opening payment app...';
      });

      
      if (widget.selectedUPIPackage != null) {
        await _openUPIApp(widget.selectedUPIPackage!);
        
        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (!mounted) return;

      if (widget.requestPayload != null) {
      } else {
      }

      final result = await _phonePeService.startPayment(
        requestPayload: widget.requestPayload, 
        token: widget.token, 
        orderId: widget.orderId, 
        appSchema: widget.appSchema, 
      );



      if (result.success) {
        
        await _verifyPayment();
      } else if (result.status == 'INCOMPLETE') {
        
        setState(() {
          _currentStatus = PaymentStatus.failed;
          _statusMessage = 'Payment cancelled';
          _errorMessage = 'Payment was cancelled. You can try booking again.';
        });
      } else {
        
        await _verifyPayment();
      }
    } catch (e) {
      
      
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('cancelled') || errorString.contains('cancel')) {
        setState(() {
          _currentStatus = PaymentStatus.failed;
          _statusMessage = 'Payment cancelled';
          _errorMessage = 'Payment was cancelled. You can try booking again.';
        });
      } else if (errorString.contains('not found') || 
                 errorString.contains('not installed') ||
                 errorString.contains('no app found')) {
        setState(() {
          _currentStatus = PaymentStatus.failed;
          _statusMessage = 'PhonePe app not found';
          _errorMessage = 'Please install PhonePe app or PhonePe Simulator to proceed with payment.';
        });
      } else {
        
        
        setState(() {
          _errorMessage = 'Error opening PhonePe: ${e.toString()}';
        });
        await _verifyPayment();
      }
    }
  }

  Future<void> _verifyPayment() async {
    setState(() {
      _currentStatus = PaymentStatus.verifying;
      _statusMessage = 'Verifying payment...';
    });

    try {
      
      final statusData = await _paymentService.pollPaymentUntilComplete(
        widget.merchantTransactionId,
        onStatusUpdate: (status) {
          setState(() {
            _statusMessage = 'Checking payment status: ${status.status}';
          });
        },
      );


      if (statusData == null) {
        setState(() {
          _currentStatus = PaymentStatus.timeout;
          _statusMessage = 'Payment verification timed out';
          _errorMessage = 'Unable to verify payment status. Please check My Visits or contact support.';
        });
        return;
      }

      if (statusData.isSuccess) {
        await _verifyAppointment();
      } else {
        setState(() {
          _currentStatus = PaymentStatus.failed;
          _statusMessage = 'Payment ${statusData.status.toLowerCase()}';
          _errorMessage = _getPaymentErrorMessage(statusData.status);
        });
      }
    } catch (e) {
      setState(() {
        _currentStatus = PaymentStatus.failed;
        _statusMessage = 'Verification failed';
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _verifyAppointment() async {
    setState(() {
      _statusMessage = 'Confirming appointment...';
    });

    try {
      final verifyRequest = VerifyAppointmentRequest(
        appointmentId: widget.appointmentId,
        merchantTransactionId: widget.merchantTransactionId,
      );

      final response = await _appointmentService.verifyAppointment(
        request: verifyRequest,
        authToken: _authToken,
      );

      if (response.success && response.data != null) {
        setState(() {
          _currentStatus = PaymentStatus.success;
          _statusMessage = 'Payment successful!';
        });

        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentRequestScreen(
                doctorName: widget.doctorName,
                doctorSpecialization: widget.doctorSpecialization,
                selectedSlot: widget.selectedSlot ?? '',
                selectedDate: widget.selectedDate ?? '',
                hospitalAddress: widget.hospitalAddress,
                tokenNumber: response.data!.tokenNo.toString(),
                patientName: widget.patientName ?? '',
                patientSubtitle: widget.patientSubtitle ?? '',
                patientBadge: widget.patientBadge ?? '',
                merchantTransactionId: widget.merchantTransactionId,
                paymentMethod: widget.provider,
                totalAmount: widget.totalAmount,
                walletAmount: widget.walletAmount,
                gatewayAmount: widget.gatewayAmount,
                appointmentId: response.data!.id,
                bookingStatus: response.data!.status,
              ),
            ),
          );
        }
      } else {
        setState(() {
          _currentStatus = PaymentStatus.failed;
          _statusMessage = 'Appointment verification failed';
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _currentStatus = PaymentStatus.failed;
        _statusMessage = 'Appointment verification failed';
        _errorMessage = e.toString();
      });
    }
  }

  String _getPaymentErrorMessage(String status) {
    switch (status) {
      case 'FAILED':
        return widget.walletAmount > 0
            ? 'Payment failed. Wallet amount of ₹${widget.walletAmount.toStringAsFixed(0)} will be refunded.'
            : 'Payment failed. Please try again.';
      case 'CANCELLED':
        return 'Payment was cancelled. You can try booking again.';
      case 'EXPIRED':
        return 'Payment link expired. Please book again.';
      default:
        return 'Payment could not be completed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return _currentStatus == PaymentStatus.success ||
            _currentStatus == PaymentStatus.failed ||
            _currentStatus == PaymentStatus.timeout;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: _currentStatus == PaymentStatus.success ||
                  _currentStatus == PaymentStatus.failed ||
                  _currentStatus == PaymentStatus.timeout
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          automaticallyImplyLeading: false,
          title: Text(
            'Payment Processing',
            style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
              color: const Color(0xff424242),
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatusIcon(),
                  const SizedBox(height: 32),
                  Text(
                    _statusMessage,
                    style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                      color: const Color(0xff424242),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  if (_currentStatus == PaymentStatus.processing ||
                      _currentStatus == PaymentStatus.verifying) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Color(0xFF1976D2),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _currentStatus == PaymentStatus.processing
                                      ? 'Please complete the payment in the UPI app that opened. Do not close this screen.'
                                      : 'Verifying your payment. Please wait...',
                                  style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                                    color: const Color(0xFF1976D2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                          color: const Color(0xFFD32F2F),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_currentStatus == PaymentStatus.failed ||
                      _currentStatus == PaymentStatus.timeout) ...[
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Try Again',
                        style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  _buildPaymentBreakdown(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (_currentStatus) {
      case PaymentStatus.success:
        return Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            color: Color(0xFF4CAF50),
            size: EcliniqTextStyles.getResponsiveIconSize(context, 80),
          ),
        );
      case PaymentStatus.failed:
      case PaymentStatus.timeout:
        return Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFD32F2F).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.error,
            color: Color(0xFFD32F2F),
            size: EcliniqTextStyles.getResponsiveIconSize(context, 80),
          ),
        );
      default:
        return const SizedBox(
          width: 80, height: 80,
          child: EcliniqLoader(
            size: 80,
            color: Color(0xFF1976D2),
          ),
        );
    }
  }

  Widget _buildPaymentBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Details',
            style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
              color: const Color(0xff424242), fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildPaymentRow('Total Amount', widget.totalAmount),
          if (widget.walletAmount > 0) ...[
            const SizedBox(height: 8),
            _buildPaymentRow('Wallet', widget.walletAmount, isSubItem: true),
          ],
          if (widget.gatewayAmount > 0) ...[
            const SizedBox(height: 8),
            _buildPaymentRow('Gateway', widget.gatewayAmount, isSubItem: true),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, double amount, {bool isSubItem = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(isSubItem ? '  • $label' : label,
          style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(color: const Color(0xff626060))),
        Text('₹${amount.toStringAsFixed(0)}',
          style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
            color: const Color(0xff424242),
            fontWeight: isSubItem ? FontWeight.normal : FontWeight.bold)),
      ],
    );
  }
}

enum PaymentStatus { initiating, processing, verifying, success, failed, timeout }