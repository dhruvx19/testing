import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/home/home_screen.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class VerifyMPINPage extends StatefulWidget {
  const VerifyMPINPage({super.key});

  @override
  State<VerifyMPINPage> createState() => _VerifyMPINPageState();
}

class _VerifyMPINPageState extends State<VerifyMPINPage> with WidgetsBindingObserver {
  // Feature flag: Set to false to disable biometric for production
  static const bool _enableBiometric = false;
  
  final TextEditingController _mpinController = TextEditingController();
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  String _entered = '';
  Timer? _mpinSubmitTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mpinController.addListener(_onMPINChanged);
    if (_enableBiometric) {
      _checkBiometricAvailability().then((_) {
        if (mounted) {
          _autoTriggerBiometric();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mpinSubmitTimer?.cancel();
    _mpinController.removeListener(_onMPINChanged);
    _mpinController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Re-check biometric availability when app comes to foreground
    // This helps if user enabled biometric in device settings while app was in background
    if (_enableBiometric && state == AppLifecycleState.resumed && mounted) {
      _checkBiometricAvailability();
    }
  }

  void _onMPINChanged() {
    final v = _mpinController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (v.length > 4) {
      _mpinController.text = v.substring(0, 4);
      _mpinController.selection = TextSelection.fromPosition(
        TextPosition(offset: 4),
      );
      return;
    }
    
    if (_entered != v) {
      setState(() {
        _entered = v;
      });
    }
    
    _mpinSubmitTimer?.cancel();
    
    if (v.length == 4) {
      _mpinSubmitTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted && !_isLoading) {
          _handleMPINLogin(v);
        }
      });
    }
  }

  Future<void> _autoTriggerBiometric() async {
    // Auto-trigger biometric if available and enabled (after a short delay)
    // Only trigger if user hasn't started typing MPIN
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Double-check all conditions before triggering
    if (!mounted) return;
    if (_isLoading) return;
    if (!_isBiometricAvailable) return;
    if (!_isBiometricEnabled) return;
    if (_entered.isNotEmpty) return; // User has started typing
    
    try {
      // Don't set loading state here - let _handleBiometricLogin() handle it
      // This prevents race conditions
      await _handleBiometricLogin();
    } catch (e) {
      // Silently fail - user can still use MPIN
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await BiometricService.isAvailable();
      final isEnabled = await SecureStorageService.isBiometricEnabled();
      
      if (mounted) {
        setState(() {
          _isBiometricAvailable = isAvailable;
          _isBiometricEnabled = isEnabled;
        });
      }
    } catch (e) {
      // On error, still try to show the button if we can't determine availability
      // This is better UX than hiding it completely
      if (mounted) {
        try {
          final isEnabled = await SecureStorageService.isBiometricEnabled();
          setState(() {
            // If biometric was previously enabled, assume it's available
            _isBiometricAvailable = isEnabled || _isBiometricAvailable;
            _isBiometricEnabled = isEnabled;
          });
        } catch (_) {
          // If everything fails, keep current state
        }
      }
    }
  }

  Future<void> _handleMPINLogin(String mpin) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.loginWithMPIN(mpin);
      
      if (mounted) {
        if (success) {
          // After successful MPIN login, ask for biometric permission if available and not enabled
          if (_isBiometricAvailable && !_isBiometricEnabled) {
            await _requestBiometricPermission(mpin);
          }
          
          EcliniqRouter.pushAndRemoveUntil(
            const HomeScreen(),
            (route) => false,
          );
        } else {
          setState(() {
            _isLoading = false;
            _entered = '';
            _mpinController.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Invalid MPIN'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
        // Update local state
        if (mounted) {
          setState(() {
            _isBiometricEnabled = true;
          });
        }
      } else {
        // User skipped or denied - that's okay, continue without biometric
      }
    } catch (e) {
      // Continue without biometric if permission request fails
    }
  }

  Future<void> _handleBiometricLogin() async {
    // Prevent multiple simultaneous calls
    if (_isLoading) {
      return;
    }
    
    if (!mounted) return;
    
    // Check if biometric is actually available before proceeding
    if (!_isBiometricAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric authentication is not available on this device'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    if (!_isBiometricEnabled) {
      // Get MPIN from storage to enable biometric
      final mpin = await SecureStorageService.getMPIN();
      if (mpin != null && mpin.isNotEmpty) {
        await _requestBiometricPermission(mpin);
        // Re-check if enabled after permission request
        final isEnabled = await SecureStorageService.isBiometricEnabled();
        if (!isEnabled) {
          // User skipped or denied, can't proceed with biometric login
          return;
        }
        // Update state and continue with biometric login
        setState(() {
          _isBiometricEnabled = true;
        });
      } else {
        // Can't enable biometric without MPIN
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('MPIN not found. Please login with MPIN first.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Add timeout wrapper to ensure we don't hang forever
      final success = await authProvider.loginWithBiometric()
          .timeout(
            const Duration(seconds: 35),
            onTimeout: () {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                _showBiometricFailureOptions('Biometric authentication timed out');
              }
              return false;
            },
          );
      
      
      // Always reset loading state first, before any navigation
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      if (!mounted) {
        return;
      }
      
      if (success) {
        // Navigate to home
        EcliniqRouter.pushAndRemoveUntil(
          const HomeScreen(),
          (route) => false,
        );
      } else {
        final errorMsg = authProvider.errorMessage ?? '';
        

        final isUserCancellation = errorMsg.toLowerCase().contains('cancel') ||
            errorMsg.toLowerCase().contains('cancelled') ||
            errorMsg.toLowerCase().contains('user');
        
        if (errorMsg.isNotEmpty && !isUserCancellation) {
          // Show options dialog for authentication failure
          _showBiometricFailureOptions(errorMsg);
        } else if (errorMsg.toLowerCase().contains('not enabled')) {
          // Biometric not enabled - request permission via native dialog
          final mpin = await SecureStorageService.getMPIN();
          if (mpin != null && mpin.isNotEmpty) {
            await _requestBiometricPermission(mpin);
            // Re-check availability after permission request
            await _checkBiometricAvailability();
          }
        } else if (isUserCancellation) {
          // User cancelled - focus on MPIN input
          _focusMPINInput();
        }
      }
    } catch (e) {
      
      // Always reset loading state on exception
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Check if it's a timeout exception
        if (e.toString().toLowerCase().contains('timeout')) {
          _showBiometricFailureOptions('Biometric authentication timed out');
        } else {
          // Show options for other failures
          _showBiometricFailureOptions('Biometric authentication failed');
        }
      }
    }
  }

  /// Show options dialog when biometric fails
  void _showBiometricFailureOptions(String errorMessage) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Authentication Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(errorMessage),
            const SizedBox(height: 16),
            const Text(
              'Please choose an option to continue:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Focus on MPIN input
              _focusMPINInput();
            },
            child: const Text(
              'Use MPIN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2372EC),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // Retry biometric
              Future.delayed(const Duration(milliseconds: 300), () {
                _handleBiometricLogin();
              });
            },
            icon: ImageIcon(
              const AssetImage('lib/ecliniq_icons/assets/Face Scan Square.png'),
              size: 20,
            ),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2372EC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Focus on MPIN input field
  void _focusMPINInput() {
    if (!mounted) return;
    // Clear any existing input
    _mpinController.clear();
    setState(() {
      _entered = '';
    });
    // Focus on the MPIN input after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(FocusNode());
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return EcliniqScaffold(
      backgroundColor: EcliniqScaffold.primaryBlue,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => EcliniqRouter.pop(),
                    icon: Image.asset(
                      EcliniqIcons.arrowBack.assetPath,
                      width: 24,
                      height: 24,
                      color: Colors.white,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Verify MPIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Enter Your MPIN',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildMPINInput(),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: CircularProgressIndicator(),
                        )
                      else ...[
                        const SizedBox(height: 24),
                        if (_enableBiometric && _isBiometricAvailable) ...[
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.0),
                                child: Text('OR', style: TextStyle(color: Colors.grey)),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _isBiometricEnabled
                              ? OutlinedButton.icon(
                                  onPressed: _isLoading ? null : _handleBiometricLogin,
                                  icon: ImageIcon(
                                    const AssetImage('lib/ecliniq_icons/assets/Face Scan Square.png'),
                                    color: const Color(0xFF2372EC),
                                    size: 22,
                                  ),
                                  label: Text(
                                    'Use ${BiometricService.getBiometricTypeName()}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF2372EC),
                                    ),
                                  ),
                                )
                              : OutlinedButton.icon(
                                  onPressed: _isLoading ? null : () async {
                                    // Get MPIN and request biometric permission via native dialog
                                    final mpin = await SecureStorageService.getMPIN();
                                    if (mpin != null && mpin.isNotEmpty) {
                                      await _requestBiometricPermission(mpin);
                                      // Re-check availability after permission request
                                      await _checkBiometricAvailability();
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please enter MPIN first'),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  icon: ImageIcon(
                                    const AssetImage('lib/ecliniq_icons/assets/Face Scan Square.png'),
                                    color: const Color(0xFF2372EC),
                                    size: 22,
                                  ),
                                  label: Text(
                                    'Use ${BiometricService.getBiometricTypeName()}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF2372EC),
                                    ),
                                  ),
                                ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMPINInput() {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
        SystemChannels.textInput.invokeMethod('TextInput.show');
      },
      child: SizedBox(
        height: 96,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final ch = i < _entered.length ? '*' : '';
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ch,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 2,
                        width: 66,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            Center(
              child: SizedBox(
                width: 300,
                child: TextField(
                  controller: _mpinController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.transparent,
                    fontSize: 18,
                    letterSpacing: 70,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  cursorColor: Colors.transparent,
                  autofocus: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

