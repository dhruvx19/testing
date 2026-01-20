import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';
import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/details/user_details.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/login.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/login_trouble.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/success_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/scripts/ecliniq_ui.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

class MPINSet extends StatefulWidget {
  final bool isResetMode;

  const MPINSet({super.key, this.isResetMode = false});

  @override
  State<MPINSet> createState() => _MPINSetState();
}

class _MPINSetState extends State<MPINSet> with TickerProviderStateMixin {
  late final TextEditingController _createMPINController;
  late final TextEditingController _confirmMPINController;

  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<String> _errorNotifier = ValueNotifier('');
  final ValueNotifier<bool> _pinsMatchNotifier = ValueNotifier(false);

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  static const Set<String> _weakPINs = {
    '1234',
    '0000',
    '1111',
    '2222',
    '3333',
    '4444',
    '5555',
    '6666',
    '7777',
    '8888',
    '9999',
    '0123',
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupAnimations();
  }

  void _initializeControllers() {
    _createMPINController = TextEditingController();
    _confirmMPINController = TextEditingController();

    _createMPINController.addListener(_onCreateMPINChanged);
    _confirmMPINController.addListener(_onConfirmMPINChanged);
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _createMPINController.removeListener(_onCreateMPINChanged);
    _confirmMPINController.removeListener(_onConfirmMPINChanged);
    _createMPINController.dispose();
    _confirmMPINController.dispose();
    _animationController.dispose();
    _isLoadingNotifier.dispose();
    _errorNotifier.dispose();
    _pinsMatchNotifier.dispose();
    super.dispose();
  }

  void _onCreateMPINChanged() {
    if (!mounted) return;
    if (_errorNotifier.value.isNotEmpty) {
      _errorNotifier.value = '';
    }
    _updatePinsMatchState();
  }

  void _onConfirmMPINChanged() {
    if (!mounted) return;
    if (_errorNotifier.value.isNotEmpty) {
      _errorNotifier.value = '';
    }
    _updatePinsMatchState();
  }

  void _updatePinsMatchState() {
    if (!mounted) return;
    final createMPIN = _createMPINController.text.trim();
    final confirmMPIN = _confirmMPINController.text.trim();
    final pinsMatch =
        createMPIN.length == 4 &&
        confirmMPIN.length == 4 &&
        createMPIN == confirmMPIN;
    _pinsMatchNotifier.value = pinsMatch;
  }

  String? _validateMPIN() {
    final createMPIN = _createMPINController.text.trim();
    final confirmMPIN = _confirmMPINController.text.trim();

    if (createMPIN.length != 4) {
      return 'MPIN must be exactly 4 digits';
    }

    if (createMPIN != confirmMPIN) {
      return 'MPINs do not match. Please try again.';
    }

    if (_weakPINs.contains(createMPIN)) {
      return 'Please choose a stronger MPIN';
    }

    return null;
  }

  void _showSuccessSnackBar() {

      CustomSuccessSnackBar.show(
        title: 'M-PIN Created Successfully',
        subtitle: 'Your changes have been saved successfully',
        context: context,

    );
  }

  Future<void> _handleMPINCreation() async {
    if (_isLoadingNotifier.value) return;

    final validationError = _validateMPIN();
    if (validationError != null) {
      _errorNotifier.value = validationError;
      return;
    }

    _isLoadingNotifier.value = true;
    _errorNotifier.value = '';

    try {
      if (!mounted) return;

      final createMPIN = _createMPINController.text.trim();

      // Call backend API to setup or reset MPIN
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = widget.isResetMode
          ? await authProvider.forgetMpinReset(createMPIN)
          : await authProvider.setupMPIN(createMPIN);

      if (!mounted) return;

      if (success) {
        if (mounted) {
          if (widget.isResetMode) {
            // Reset mode: Check if user is authenticated (change MPIN from settings) or not (forget PIN from login)
            final hasValidSession = await SessionService.hasValidSession();
            if (hasValidSession) {
              // User is authenticated - this is change MPIN from security settings
              // Reset loading state before navigation
              _isLoadingNotifier.value = false;
              // Small delay to ensure state is stable before navigation
              await Future.delayed(const Duration(milliseconds: 100));
              // Return true to ChangeMPINScreen so it can show snackbar on SecuritySettings page
              if (!mounted || !context.mounted) return;
              Navigator.of(context).pop(true);
              return; // Exit early to prevent finally block from resetting loading state again
            } else {
              // User is not authenticated - this is forget PIN from login
              // Reset loading state
              _isLoadingNotifier.value = false;
              // Show snackbar before navigating
              _showSuccessSnackBar();
              await Future.delayed(const Duration(milliseconds: 500));
              // Navigate back to login
              EcliniqRouter.pushAndRemoveUntil(
                const LoginPage(),
                (route) => route.isFirst,
              );
              return; // Exit early
            }
          } else {
            // Normal mode: Request biometric permission via native dialog after MPIN setup
            await _requestBiometricPermission(createMPIN);
            // Navigate based on flow state
            await _navigateAfterMPINSetup();
          }
        }
      } else {
        _errorNotifier.value =
            authProvider.errorMessage ??
            'Failed to create MPIN. Please try again.';
      }
    } on Exception catch (e) {
      debugPrint('MPIN creation error: $e');
      _errorNotifier.value = 'An unexpected error occurred. Please try again.';
    } finally {
      if (mounted && _isLoadingNotifier.value) {
        _isLoadingNotifier.value = false;
      }
    }
  }

  /// Request biometric permission using native dialog (like location permission)
  /// This will trigger the native biometric permission dialog automatically
  Future<void> _requestBiometricPermission(String mpin) async {
    try {
      // Check if biometric is available
      if (!await BiometricService.isAvailable()) {
        return;
      }

      // Check if already enabled
      if (await SecureStorageService.isBiometricEnabled()) {
        return;
      }

      // This will trigger the native biometric permission dialog automatically
      // The native dialog will appear just like location permission dialog
      final success = await SecureStorageService.storeMPINWithBiometric(mpin);

      if (success) {
      } else {
        // User skipped or denied - that's okay, continue without biometric
      }
    } catch (e) {
      // Continue without biometric if permission request fails
    }
  }

  Future<void> _navigateAfterMPINSetup() async {
    if (!mounted) return;

    // Always navigate to User Details after MPIN setup
    // Flow: OTP → MPIN → User Details → Home
    await SessionService.saveFlowState('profile_setup');
    if (!mounted) return;
    EcliniqRouter.pushAndRemoveUntil(
      const UserDetails(),
      (route) => route.isFirst,
    );
  }

  void _navigateToUserDetails() {
    if (!mounted) return;
    EcliniqRouter.pushAndRemoveUntil(
      const UserDetails(),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: EcliniqScaffold.primaryBlue,
        toolbarHeight: 50,
        title: Text(
          widget.isResetMode ? 'Reset M-PIN' : 'Create Your M-PIN',
          style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(color: Colors.white),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              EcliniqRouter.push(LoginTroublePage());
            },
            child: Row(
              children: [
                SvgPicture.asset(
                  EcliniqIcons.questionCircleWhite.assetPath,
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 4),
                Text(
                  'Help',
                  style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                    color: Colors.white,

                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: EcliniqScaffold.primaryBlue,
      body: SizedBox.expand(
        child: Column(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildMainContent(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 18),
                  Image.asset(
                    EcliniqIcons.mpin.assetPath,
                    width: 132,
                    height: 120,
                  ),
                  const SizedBox(height: 16),
                  const _InstructionsText(),
                  const SizedBox(height: 20),
                  _buildPinInputSection(),
                  const SizedBox(height: 32),
                  _buildPinInputDescription(),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: _buildCreateButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildPinInputSection() {
    return Column(
      children: [
        _buildPinField(
          title: 'Create M-PIN',
          controller: _createMPINController,
          autoFocus: true,
        ),
        const SizedBox(height: 24),
        _buildPinField(
          title: 'Confirm M-PIN',
          controller: _confirmMPINController,
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<String>(
          valueListenable: _errorNotifier,
          builder: (context, error, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: _pinsMatchNotifier,
              builder: (context, pinsMatch, _) {
                // Show success message if pins match and no error
                if (pinsMatch && error.isEmpty) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: _SuccessMessage(message: 'M-PIN matches'),
                  );
                }
                // Show error message if there's an error
                if (error.isNotEmpty) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: _ErrorMessage(message: error),
                  );
                }
                return const SizedBox.shrink();
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPinInputDescription() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            EcliniqIcons.shieldBlue.assetPath,
            width: 32,
            height: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your M-PIN will be used for:',
                  style: EcliniqTextStyles.responsiveTitleXBLarge(context).copyWith(
                    color: Color(0xff424242),
                  ),
                ),
                const SizedBox(height: 8),
                _buildBulletPoint('Quick login to your account'),
                const SizedBox(height: 4),
                _buildBulletPoint('Secure access to your medical records'),
                const SizedBox(height: 4),
                _buildBulletPoint('Authorizing important actions'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(right: 8, top: 8),
          decoration: BoxDecoration(
            color: Color(0xff626060),
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
              color: Color(0xff626060),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPinField({
    required String title,
    required TextEditingController controller,
    bool autoFocus = false,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
            color: Color(0xff424242),
          ),
        ),
        const SizedBox(height: 12),
        PinCodeTextField(
          textStyle: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
            color: const Color(0xff424242),
          ),
          appContext: context,
          length: 4,
          controller: controller,
          autoFocus: autoFocus,
          obscureText: true,
          obscuringCharacter: '*',
          keyboardType: TextInputType.number,
          animationType: AnimationType.fade,
          hapticFeedbackTypes: HapticFeedbackTypes.light,
          pinTheme: _getPinTheme(),
          enableActiveFill: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          cursorColor: Colors.black,
          hintCharacter: '-',
          errorTextSpace: 0,
        ),
      ],
    );
  }

  PinTheme _getPinTheme() {
    // Calculate responsive field width and padding to fit all 4 fields on screen
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding =
        36.0; // Total horizontal padding (18px on each side from parent)
    final availableWidth = screenWidth - horizontalPadding;

    // For 4 fields with padding on each side: 4 * (fieldWidth + 2*padding) = availableWidth
    // 4w + 8p = availableWidth
    // Increase spacing and reduce field size
    const padding = 8.0; // Increased padding (16px total between fields)
    final calculatedWidth = (availableWidth - (8 * padding)) / 4;
    // Ensure we don't exceed available width by using floor to be safe
    final fieldWidth = (calculatedWidth.floor()).toDouble().clamp(40.0, 70.0);

    return PinTheme(
      shape: PinCodeFieldShape.box,
      borderRadius: BorderRadius.circular(12),
      fieldHeight: 48, // Reduced height
      fieldWidth: fieldWidth,
      activeFillColor: Color(0xffffffff),
      selectedFillColor: Color(0xffffffff),
      inactiveFillColor: Color(0xffffffff),
      activeColor: Color(0xff626060),
      selectedColor: Color(0xff626060),
      inactiveColor: Color(0xff626060),
      borderWidth: 0.5,
      activeBorderWidth: 0.5,
      selectedBorderWidth: 1,
      inactiveBorderWidth: 0.5,
      fieldOuterPadding: EdgeInsets.symmetric(horizontal: padding),
    );
  }

  Widget _buildCreateButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isLoadingNotifier,
      builder: (context, isLoading, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _pinsMatchNotifier,
          builder: (context, pinsMatch, _) {
            final isButtonEnabled = pinsMatch && !isLoading;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: _MPINButton(
                  isEnabled: isButtonEnabled,
                  isLoading: isLoading,
                  onPressed: isButtonEnabled ? _handleMPINCreation : null,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MPINButton extends StatefulWidget {
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _MPINButton({
    required this.isEnabled,
    required this.isLoading,
    this.onPressed,
  });

  @override
  State<_MPINButton> createState() => _MPINButtonState();
}

class _MPINButtonState extends State<_MPINButton> {
  bool _isButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isEnabled
          ? (_) => setState(() => _isButtonPressed = true)
          : null,
      onTapUp: widget.isEnabled
          ? (_) {
              setState(() => _isButtonPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: widget.isEnabled
          ? () => setState(() => _isButtonPressed = false)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: widget.isLoading
              ? const Color(0xFF2372EC)
              : _isButtonPressed
              ? const Color(0xFF0E4395) // Pressed color
              : widget.isEnabled
              ? const Color(0xFF2372EC) // Enabled color
              : const Color(0xffF9F9F9), // Disabled color
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: widget.isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: EcliniqLoader(size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Setting M-PIN',
                      style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Create M-PIN',
                      style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                        color: widget.isEnabled
                            ? Colors.white
                            : const Color(0xffD6D6D6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SvgPicture.asset(
                      EcliniqIcons.arrowRight.assetPath,
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        widget.isEnabled
                            ? Colors.white
                            : const Color(0xff8E8E8E),
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _InstructionsText extends StatelessWidget {
  const _InstructionsText();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Enter a 4-digit PIN that you can remember easily',
      style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
        color: Color(0xff424242),
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _SuccessMessage extends StatelessWidget {
  final String message;

  const _SuccessMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          EcliniqIcons.shieldCheck.assetPath,
          width: 24,
          height: 24,
        ),
        SizedBox(width: 2),
        Text(
          textAlign: TextAlign.center,
          message,
          style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
            color: Color(0xff3EAF3F),
            
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: EcliniqTextStyles.getResponsiveIconSize(context, 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: EcliniqTextStyles.responsiveButtonXLarge(context).copyWith(color: Colors.red.shade600,),
            ),
          ),
        ],
      ),
    );
  }
}
