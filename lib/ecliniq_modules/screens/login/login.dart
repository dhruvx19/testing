
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class CardHoleClipper extends CustomClipper<Path> {
  final double radius;
  final double centerYOffset;

  CardHoleClipper({required this.radius, required this.centerYOffset});

  @override
  Path getClip(Size size) {
    final Path outer = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(18),
      ));
    final Offset center = Offset(size.width / 2, centerYOffset);
    final Path hole = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    return Path.combine(PathOperation.difference, outer, hole);
  }

  @override
  bool shouldReclip(covariant CardHoleClipper oldClipper) {
    return oldClipper.radius != radius || oldClipper.centerYOffset != centerYOffset;
  }
}

class TopEdgePainter extends CustomPainter {
  final Color leftColor;
  final Color rightColor;
  final double holeRadius;
  final double holeCenterYOffset;
  final double cornerRadius;
  final double bandHeight;

  TopEdgePainter({
    required this.leftColor,
    required this.rightColor,
    required this.holeRadius,
    required this.holeCenterYOffset,
    this.cornerRadius = 18.0,
    this.bandHeight = 36.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 1.6;
    final outer = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(cornerRadius),
      ));
    final center = Offset(size.width / 2, holeCenterYOffset);
    final hole = Path()..addOval(Rect.fromCircle(center: center, radius: holeRadius));
    final cardPath = Path.combine(PathOperation.difference, outer, hole);

    final bandHeightLocal = (strokeWidth * 3).clamp(2.0, 12.0);
    final clipHeight = max(bandHeightLocal, holeRadius + center.dy);

    final gradient = LinearGradient(colors: [leftColor, rightColor]);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, clipHeight));

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, clipHeight));
    canvas.drawPath(cardPath, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TopEdgePainter oldDelegate) {
    return oldDelegate.leftColor != leftColor ||
        oldDelegate.rightColor != rightColor ||
        oldDelegate.holeRadius != holeRadius ||
        oldDelegate.holeCenterYOffset != holeCenterYOffset;
  }
}

class _LoginPageState extends State<LoginPage> {
  bool _showPin = false;
  String _entered = '';
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final v = _textController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (v.length > 4) _textController.text = v.substring(0, 4);
      setState(() {
        _entered = _textController.text;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final headerHeight = (screenH * 0.38).clamp(260.0, 420.0).toDouble();

    final slotWidth = 66.0;
    final totalOverlayWidth = (slotWidth + 16) * 4;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(
            height: headerHeight,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2372EC), Color(0xFFF8DFFF)],
                      stops: [0.0, 1.0],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.45,
                    child: Image.asset(
                      EcliniqIcons.lottie.assetPath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      EcliniqIcons.nameLogo.assetPath,
                      height: 56,
                      width: 200,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Welcome back, Ketan!',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Your Healthcare Platform',
                      style: TextStyle(
                        color: Color(0xE5FFFFFF),
                        fontFamily: 'Rubik',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -65),
              child: Padding(
                padding: EdgeInsets.zero,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Stack(
                        children: [
                          PhysicalShape(
                            clipper: CardHoleClipper(radius: 52.0, centerYOffset: 14.0),
                            color: Colors.white,
                            elevation: 0,
                            child: const SizedBox.expand(),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: TopEdgePainter(
                                leftColor: const Color(0xFFBF50FF).withOpacity(0.3),
                                rightColor: const Color(0xFF0064FF).withOpacity(0.4),
                                holeRadius: 52.0,
                                holeCenterYOffset: 14.0,
                                cornerRadius: 18.0,
                                bandHeight: 36.0,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(18.0, 56.0, 18.0, 0.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 35),
                                  const Text(
                                    'Enter Your MPIN to Sign In',
                                    style: TextStyle(fontSize: 18, fontFamily: 'Inter', fontWeight: FontWeight.w500, color: Colors.black87),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTap: () {
                                      FocusScope.of(context).requestFocus(_focusNode);
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
                                              final ch = i < _entered.length ? (_showPin ? _entered[i] : '*') : '';
                                              return Container(
                                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      ch,
                                                      style: const TextStyle(fontSize: 18, fontFamily: 'Inter', fontWeight: FontWeight.w400),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Container(
                                                      height: 2,
                                                      width: slotWidth,
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade400,
                                                        borderRadius: BorderRadius.circular(0),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ),
                                          Center(
                                            child: SizedBox(
                                              width: totalOverlayWidth.clamp(200.0, screenW - 48.0),
                                              child: TextField(
                                                controller: _textController,
                                                focusNode: _focusNode,
                                                keyboardType: TextInputType.number,
                                                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                                                textAlign: TextAlign.center,
                                                style: TextStyle(color: Colors.transparent, fontSize: 18, letterSpacing: slotWidth + 4, fontFamily: 'Inter'),
                                                decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
                                                cursorColor: Colors.transparent,
                                                autofocus: false,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton(
                                        onPressed: () {},
                                        child: const Text('Forgot PIN?', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => setState(() => _showPin = !_showPin),
                                        icon: Image.asset(
                                          _showPin ? 'lib/ecliniq_icons/assets/Eye.png' : 'lib/ecliniq_icons/assets/Eye Closed.png',
                                          width: 18,
                                          height: 18,
                                          errorBuilder: (c, e, s) => const SizedBox.shrink(),
                                        ),
                                        label: Text(
                                          'Show PIN',
                                          style: TextStyle(color: _showPin ? const Color(0xFF2372EC) : Colors.black),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      const Expanded(child: Divider(thickness: 1, color: Color(0xFFEEEEEE))),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                        child: Text('OR', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                      ),
                                      const Expanded(child: Divider(thickness: 1, color: Color(0xFFEEEEEE))),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Center(
                                    child: OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: ImageIcon(const AssetImage('lib/ecliniq_icons/assets/Face Scan Square.png'), color: const Color(0xFF2372EC), size: 22),
                                      label: const Text('Use Face ID', style: TextStyle(fontSize: 18, fontFamily: 'Inter', fontWeight: FontWeight.w500, color: Color(0xFF2372EC))),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(150, 48),
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        side: const BorderSide(color: Color(0x382372EC)),
                                        backgroundColor: Colors.blue.shade50,
                                        foregroundColor: Colors.blue.shade100,
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: SizedBox.shrink()),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -40,
                      left: 18,
                      right: 18,
                      child: Center(
                        child: Container(
                          width: 110,
                          height: 110,
                          child: Center(
                            child: ClipOval(
                              child: Image.asset(
                                'lib/ecliniq_icons/assets/login_man_frame.png',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Image.asset(
                                  EcliniqIcons.userCircle.assetPath,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

