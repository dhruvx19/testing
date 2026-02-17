import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/home_screen.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';

class VerifyMPINPage extends StatefulWidget {
  const VerifyMPINPage({super.key});

  @override
  State<VerifyMPINPage> createState() => _VerifyMPINPageState();
}

class _VerifyMPINPageState extends State<VerifyMPINPage>
    with WidgetsBindingObserver {
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
    _checkBiometricAvailability().then((_) {
      if (mounted) {
        _autoTriggerBiometric();
      }
    });
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
    
    
    if (state == AppLifecycleState.resumed && mounted) {
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
      
      _mpinSubmitTimer = Timer(Duration.zero, () {
        if (mounted && !_isLoading) {
          _handleMPINLogin(v);
        }
      });
    }
  }

  Future<void> _autoTriggerBiometric() async {
    
    
    await Future.delayed(const Duration(milliseconds: 800));

    
    if (!mounted) return;
    if (_isLoading) return;
    if (!_isBiometricAvailable) return;
    if (!_isBiometricEnabled) return;
    if (_entered.isNotEmpty) return; 

    try {
      
      
      await _handleBiometricLogin();
    } catch (e) {
      
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
      
      
      if (mounted) {
        try {
          final isEnabled = await SecureStorageService.isBiometricEnabled();
          setState(() {
            
            _isBiometricAvailable = isEnabled || _isBiometricAvailable;
            _isBiometricEnabled = isEnabled;
          });
        } catch (_) {
          
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
          
          
          if (_isBiometricAvailable && !_isBiometricEnabled) {
            
            _requestBiometricPermission(mpin).catchError((e) {
              
            });
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

  
  
  Future<void> _requestBiometricPermission(String mpin) async {
    try {
      
      if (!await BiometricService.isAvailable()) {
        return;
      }

      
      if (await SecureStorageService.isBiometricEnabled()) {
        return;
      }

      
      
      final success = await SecureStorageService.storeMPINWithBiometric(mpin);

      if (success) {
        
        if (mounted) {
          setState(() {
            _isBiometricEnabled = true;
          });
        }
      } else {
        
      }
    } catch (e) {
      
    }
  }

  Future<void> _handleBiometricLogin() async {
    
    if (_isLoading) {
      return;
    }

    if (!mounted) return;

    
    if (!_isBiometricAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Biometric authentication is not available on this device',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!_isBiometricEnabled) {
      
      final mpin = await SecureStorageService.getMPIN();
      if (mpin != null && mpin.isNotEmpty) {
        await _requestBiometricPermission(mpin);
        
        final isEnabled = await SecureStorageService.isBiometricEnabled();
        if (!isEnabled) {
          
          return;
        }
        
        setState(() {
          _isBiometricEnabled = true;
        });
      } else {
        
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

      
      final success = await authProvider.loginWithBiometric().timeout(
        const Duration(seconds: 35),
        onTimeout: () {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Biometric authentication timed out. Please try again.',
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
          return false;
        },
      );

      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (!mounted) {
        return;
      }

      if (success) {
        
        EcliniqRouter.pushAndRemoveUntil(const HomeScreen(), (route) => false);
      } else {
        final errorMsg = authProvider.errorMessage ?? '';

        final isUserCancellation =
            errorMsg.toLowerCase().contains('cancel') ||
            errorMsg.toLowerCase().contains('cancelled') ||
            errorMsg.toLowerCase().contains('user');

        if (errorMsg.isNotEmpty && !isUserCancellation) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (errorMsg.toLowerCase().contains('not enabled')) {
          
          final mpin = await SecureStorageService.getMPIN();
          if (mpin != null && mpin.isNotEmpty) {
            await _requestBiometricPermission(mpin);
            
            await _checkBiometricAvailability();
          }
        }
      }
    } catch (e) {
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        
        if (e.toString().toLowerCase().contains('timeout')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Biometric authentication timed out. Please try again.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Biometric login failed: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
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
                  Expanded(
                    child: Text(
                      'Verify MPIN',
                      style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                        color: Colors.white,

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
                       Text(
                        'Enter Your MPIN',
                        style: EcliniqTextStyles.responsiveHeadlineXLarge(context).copyWith(
                        
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildMPINInput(),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: EcliniqLoader(),
                        )
                      else ...[
                        const SizedBox(height: 24),
                        if (_isBiometricAvailable) ...[
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.0),
                                child: Text(
                                  'OR',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _isBiometricEnabled
                              ? OutlinedButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : _handleBiometricLogin,
                                  icon: ImageIcon(
                                    const AssetImage(
                                      'lib/ecliniq_icons/assets/Face Scan Square.png',
                                    ),
                                    color: const Color(0xFF2372EC),
                                    size: 22,
                                  ),
                                  label: Text(
                                    'Use ${BiometricService.getBiometricTypeName()}',
                                    style: EcliniqTextStyles.responsiveTitleXLarge(context)
                                        .copyWith(color: Color(0xFF2372EC)),
                                  ),
                                )
                              : OutlinedButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : () async {
                                          
                                          final mpin =
                                              await SecureStorageService.getMPIN();
                                          if (mpin != null && mpin.isNotEmpty) {
                                            await _requestBiometricPermission(
                                              mpin,
                                            );
                                            
                                            await _checkBiometricAvailability();
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Please enter MPIN first',
                                                ),
                                                backgroundColor: Colors.red,
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                  icon: ImageIcon(
                                    const AssetImage(
                                      'lib/ecliniq_icons/assets/Face Scan Square.png',
                                    ),
                                    color: const Color(0xFF2372EC),
                                    size: 22,
                                  ),
                                  label: Text(
                                    'Use ${BiometricService.getBiometricTypeName()}',
                                    style: EcliniqTextStyles.responsiveTitleXLarge(context)
                                        .copyWith(color: Color(0xFF2372EC)),
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
                        style:  EcliniqTextStyles.responsiveHeadlineXLarge(context).copyWith(
                     
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 2,
                        width: 66,
                        decoration: BoxDecoration(color: Colors.grey.shade400),
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
                  style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                    color: Colors.transparent,

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
