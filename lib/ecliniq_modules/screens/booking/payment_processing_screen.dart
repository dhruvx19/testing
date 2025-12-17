import 'dart:async';
import 'package:ecliniq/ecliniq_api/payment_service.dart';
import 'package:ecliniq/ecliniq_api/models/payment.dart';
import 'package:ecliniq/ecliniq_api/appointment_service.dart';
import 'package:ecliniq/ecliniq_api/models/appointment.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/booking_confirmed_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/request_sent.dart';
import 'package:ecliniq/ecliniq_services.dart/phonepe_service.dart';
// import 'package:ecliniq/ecliniq_modules/screens/booking/widgets/upi_app_selector.dart'; // Uncomment for production UPI selector UI

import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';

class PaymentProcessingScreen extends StatefulWidget {
  final String appointmentId;
  final String merchantTransactionId;
  final String? token; // PhonePe SDK token (fallback if requestPayload not available)
  final String? orderId; // PhonePe order ID (fallback if requestPayload not available)
  final String? requestPayload; // Base64-encoded payment payload from backend (preferred)
  final double totalAmount;
  final double walletAmount;
  final double gatewayAmount;
  final String provider;

  // App schema for PhonePe callback
  final String appSchema;

  // Appointment details for success screen
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
    this.appSchema = 'ecliniq', // Your app's URL scheme
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
      print('========== PAYMENT PROCESSING START ==========');
      print('Appointment ID: ${widget.appointmentId}');
      print('Merchant Txn ID: ${widget.merchantTransactionId}');
      print('Request payload present: ${widget.requestPayload != null}');
      if (widget.requestPayload != null) {
        print('Request payload length: ${widget.requestPayload!.length}');
      }
      print('Token: ${widget.token}');
      print('Order ID: ${widget.orderId}');
      print('Total amount: ${widget.totalAmount}');
      print('Wallet amount: ${widget.walletAmount}');
      print('Gateway amount: ${widget.gatewayAmount}');
      print('Provider: ${widget.provider}');
      print('App schema: ${widget.appSchema}');
      print('==============================================');
      
      // Validate requestPayload (preferred) or token/orderId (fallback)
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

      // Initialize PhonePe SDK if not already initialized
      if (!_phonePeService.isInitialized) {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id') ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
        
        // TODO: Get merchantId from your config/environment
        const merchantId = 'M237OHQ3YCVAO_2511191950';
        const isProduction = false; // Set to true for production

        final initialized = await _phonePeService.initialize(
          isProduction: isProduction,
          merchantId: merchantId,
          flowId: userId,
          enableLogs: !isProduction,
        );

        print('========== PHONEPE SDK INIT ==========');
        print('Initialized: $initialized');
        print('Is production: $isProduction');
        print('Merchant ID: $merchantId');
        print('Flow ID: $userId');
        print('Environment: ${_phonePeService.environment}');
        print('Package name: ${_phonePeService.packageName}');
        print('======================================');

        if (!initialized) {
          throw PhonePeException('Failed to initialize PhonePe SDK');
        }
      }

      // Start payment
      await _startPhonePePayment();
    } catch (e) {
      setState(() {
        _currentStatus = PaymentStatus.failed;
        _statusMessage = 'Payment initialization failed';
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _startPhonePePayment() async {
    try {
      // Validate requestPayload (preferred) or token (fallback)
      if (widget.requestPayload == null || widget.requestPayload!.isEmpty) {
        if (widget.token == null || widget.token!.isEmpty) {
          throw PhonePeException('Payment token is empty. Please try booking again.');
        }
      }

      setState(() {
        _currentStatus = PaymentStatus.processing;
        _statusMessage = 'Opening PhonePe...\nYou can choose UPI apps, UPI ID, Card, or Net Banking';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      print('========== STARTING PHONEPE PAYMENT ==========');
      if (widget.requestPayload != null) {
        print('Using requestPayload from backend (preferred method)');
        print('Request payload length: ${widget.requestPayload!.length}');
      } else {
        print('Using token/orderId (fallback method)');
        print('Token: ${widget.token}');
        print('Order ID: ${widget.orderId}');
      }
      print('App schema: ${widget.appSchema}');
      print('Environment: ${_phonePeService.environment}');
      print('Package name: ${_phonePeService.packageName}');
      print('==============================================');

      // PhonePe SDK will automatically:
      // 1. Open PhonePe app (or simulator in sandbox mode)
      // 2. Show all payment options (UPI apps, UPI ID, Card, Net Banking)
      // 3. User selects payment method and completes payment
      // 4. Returns to app via deep link (appSchema)
      //
      // Use requestPayload directly if available (preferred), otherwise fallback to token/orderId
      final result = await _phonePeService.startPayment(
        requestPayload: widget.requestPayload, // Base64-encoded payload from backend (preferred)
        token: widget.token, // PhonePe SDK token from backend (fallback)
        orderId: widget.orderId, // PhonePe order ID from backend (fallback)
        appSchema: widget.appSchema, // 'ecliniq' - your app's URL scheme
      );

      print('========== PHONEPE PAYMENT RESULT ==========');
      print('Success: ${result.success}');
      print('Status: ${result.status}');
      print('Error: ${result.error}');
      print('Data: ${result.data}');
      print('===========================================');

      // Check the SDK result before verifying with backend
      if (result.success) {
        // SDK reported success, verify with backend
        await _verifyPayment();
      } else if (result.status == 'INCOMPLETE') {
        // User cancelled or flow incomplete
        setState(() {
          _currentStatus = PaymentStatus.failed;
          _statusMessage = 'Payment cancelled';
          _errorMessage = 'Payment was cancelled. You can try booking again.';
        });
      } else {
        // SDK reported failure, still verify with backend (payment might have succeeded)
        await _verifyPayment();
      }
    } catch (e) {
      print('========== PHONEPE PAYMENT EXCEPTION ==========');
      print('Exception: $e');
      print('Exception type: ${e.runtimeType}');
      print('===============================================');
      
      // On error, check if it's a cancellation or app not found
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
        // For other errors, still try to verify (PhonePe might have processed it)
        // But also show the error to user
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
      print('========== VERIFYING PAYMENT ==========');
      print('Polling status for: ${widget.merchantTransactionId}');
      print('=======================================');
      
      final statusData = await _paymentService.pollPaymentUntilComplete(
        widget.merchantTransactionId,
        onStatusUpdate: (status) {
          print('Status update: ${status.status}');
          setState(() {
            _statusMessage = 'Checking payment status: ${status.status}';
          });
        },
      );

      print('========== PAYMENT STATUS RESULT ==========');
      print('Status data: ${statusData?.toJson()}');
      print('Is success: ${statusData?.isSuccess}');
      print('Status: ${statusData?.status}');
      print('==========================================');

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
            style: EcliniqTextStyles.headlineMedium.copyWith(
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
                    style: EcliniqTextStyles.headlineLarge.copyWith(
                      color: const Color(0xff424242),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Show helpful message when processing payment
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
                                  style: EcliniqTextStyles.headlineXMedium.copyWith(
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
                        style: EcliniqTextStyles.headlineXMedium.copyWith(
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
                        style: EcliniqTextStyles.headlineMedium.copyWith(color: Colors.white),
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
          child: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 80),
        );
      case PaymentStatus.failed:
      case PaymentStatus.timeout:
        return Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFD32F2F).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error, color: Color(0xFFD32F2F), size: 80),
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
            style: EcliniqTextStyles.headlineMedium.copyWith(
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
          style: EcliniqTextStyles.headlineXMedium.copyWith(color: const Color(0xff626060))),
        Text('₹${amount.toStringAsFixed(0)}',
          style: EcliniqTextStyles.headlineXMedium.copyWith(
            color: const Color(0xff424242),
            fontWeight: isSubItem ? FontWeight.normal : FontWeight.bold)),
      ],
    );
  }
}

enum PaymentStatus { initiating, processing, verifying, success, failed, timeout }