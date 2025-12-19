import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';
import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/main_flow/otp_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/main_flow/phone_input.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/details/user_details.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/login.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/login_trouble.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/security_settings/security_settings.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/button/button.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/success_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/scripts/ecliniq_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';

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
  bool _isButtonPressed = false;

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
    ScaffoldMessenger.of(context).showSnackBar(
      CustomSuccessSnackBar(
        title: 'M-PIN Created Successfully',
        subtitle: 'Your changes have been saved successfully',
        context: context,
      ),
    );
  }

  Future<void> _handleMPINCreation() async {
    if (_isLoadingNotifier.value) return;

    final validationError = _validateMPIN();
    if (validationError != null) {
      _errorNotifier.value = validationError;
      return;
    }

    setState(() {
      _isButtonPressed = true;
    });
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
        _showSuccessSnackBar();

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          if (widget.isResetMode) {
            // Reset mode: Check if user is authenticated (change MPIN from settings) or not (forget PIN from login)
            final hasValidSession = await SessionService.hasValidSession();
            if (hasValidSession) {
              // User is authenticated - this is change MPIN from security settings
              // Navigation stack: SecuritySettings -> ChangeMPIN -> MPINSet
              // Pop twice to get back to SecuritySettings (pop MPINSet, then pop ChangeMPIN)
              if (Navigator.canPop(context)) {
                Navigator.pop(context); // Pop MPINSet
              }
              if (Navigator.canPop(context)) {
                Navigator.pop(context); // Pop ChangeMPIN, now at SecuritySettings
              }
            } else {
              // User is not authenticated - this is forget PIN from login
              // Navigate back to login
              EcliniqRouter.pushAndRemoveUntil(
                const LoginPage(),
                (route) => route.isFirst,
              );
            }
          } else {
            // Normal mode: Request biometric permission via native dialog after MPIN setup
            await _requestBiometricPermission(createMPIN);
            // Continue to user details page
            _navigateToUserDetails();
          }
        }
      } else {
        setState(() {
          _isButtonPressed = false;
        });
        _errorNotifier.value = authProvider.errorMessage ?? 'Failed to create MPIN. Please try again.';
      }
    } on Exception catch (e) {
      debugPrint('MPIN creation error: $e');
      setState(() {
        _isButtonPressed = false;
      });
      _errorNotifier.value = 'An unexpected error occurred. Please try again.';
    } finally {
      if (mounted) {
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

  void _navigateToUserDetails() {
    if (!mounted) return;
    EcliniqRouter.pushAndRemoveUntil(
      const UserDetails(),
      (route) => route.isFirst,
    );
  }

  


  @override
  Widget build(BuildContext context) {
    return EcliniqScaffold(
      backgroundColor: EcliniqScaffold.primaryBlue,
      body: SizedBox.expand(
        child: Column(
          children: [
            SizedBox(height: 40),
            Row(
              children: [
                IconButton(
                  onPressed: EcliniqRouter.pop,
                  icon: Image.asset(
                    EcliniqIcons.arrowBack.assetPath,
                    width: 24,
                    height: 24,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                SizedBox(width: 35),
                Center(
                  child: Text(
                    widget.isResetMode ? 'Reset Your M-PIN' : 'Create Your M-PIN',
                    style: EcliniqTextStyles.headlineMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    EcliniqRouter.push(const LoginTroublePage());
                  },
                  icon: const Icon(Icons.help_outline, color: Colors.white),
                  label: const Text(
                    'Help',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
  
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
                  const _MPINImage(),
                  const SizedBox(height: 16),
                  const _InstructionsText(),
                  const SizedBox(height: 16),
                  _buildPinInputSection(),
                  const SizedBox(height: 16),
                  _buildPinInputDescription(),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
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
        const SizedBox(height: 20),
        _buildPinField(
          title: 'Confirm M-PIN',
          controller: _confirmMPINController,
          onCompleted: (_) => _handleMPINCreation(),
        ),
        const SizedBox(height: 18),
        ValueListenableBuilder<String>(
          valueListenable: _errorNotifier,
          builder: (context, error, _) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: error.isEmpty ? 0 : null,
              child: error.isEmpty
                  ? const SizedBox.shrink()
                  : _ErrorMessage(message: error),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPinInputDescription() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  EcliniqIcons.shield.assetPath,
                  width: 24,
                  height: 24,
                ),
                SizedBox(width: 2),
                Column(
                  children: [
                    Text(
                      'Your M-PIN will be used for:',
                      style: EcliniqTextStyles.titleXBLarge.copyWith(
                        color: Color(0xff424242),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              ' • Quick log in to your account',
              style: EcliniqTextStyles.titleXLarge.copyWith(
                color: Color(0xff626060),
              ),
            ),
            Text(
              ' • Secure access to your medical records',
              style: EcliniqTextStyles.titleXLarge.copyWith(
                 color: Color(0xff626060),
              ),
            ),
            Text(
              ' • Authorizing important actions',
              style: EcliniqTextStyles.titleXLarge.copyWith(
                color: Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinField({
    required String title,
    required TextEditingController controller,
    bool autoFocus = false,
    void Function(String)? onCompleted,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: EcliniqTextStyles.headlineMedium.copyWith(
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        PinCodeTextField(
          appContext: context,
          length: 4,
          controller: controller,
          autoFocus: autoFocus,
          obscureText: true,
          obscuringCharacter: '*',
          keyboardType: TextInputType.number,
          animationType: AnimationType.fade,
          hapticFeedbackTypes: HapticFeedbackTypes.light,
          onCompleted: onCompleted,
          pinTheme: _getPinTheme(),
          enableActiveFill: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          cursorColor: Colors.black,
          hintCharacter: '-',
        ),
      ],
    );
  }

  PinTheme _getPinTheme() {
    return PinTheme(
      shape: PinCodeFieldShape.box,
      borderRadius: BorderRadius.circular(12),
      fieldHeight: 52,
      fieldWidth: 80,
      activeFillColor: Colors.blue.shade50,
      selectedFillColor: Colors.blue.shade50,
      inactiveFillColor: Colors.grey.shade50,
      activeColor: EcliniqScaffold.primaryBlue,
      selectedColor: EcliniqScaffold.primaryBlue,
      inactiveColor: Colors.grey.shade400,
      borderWidth: 2,
      fieldOuterPadding: const EdgeInsets.symmetric(horizontal: 4),
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

            return SizedBox(
              width: double.infinity,
              height: 46,
              child: GestureDetector(
                onTap: isButtonEnabled ? _handleMPINCreation : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: _isButtonPressed
                        ? Color(0xFF0E4395)
                        : isButtonEnabled
                        ? EcliniqButtonType.brandPrimary.backgroundColor(
                            context,
                          )
                        : EcliniqButtonType.brandPrimary
                              .disabledBackgroundColor(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
						child: EcliniqLoader(
							size: 20,
							color: Colors.white,
						),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.isResetMode ? 'Reset M-PIN' : 'Create M-PIN',
                              style: EcliniqTextStyles.titleXLarge.copyWith(
                                color: isButtonEnabled
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: isButtonEnabled
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MPINImage extends StatelessWidget {
  const _MPINImage();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      width: 140,
      child: Image.asset(
        'lib/ecliniq_icons/assets/mpin.gif',
        fit: BoxFit.contain,
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
      style: EcliniqTextStyles.headlineXMedium.copyWith(color: Colors.black87),
      textAlign: TextAlign.center,
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
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}