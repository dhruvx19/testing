import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CircularProfileCarousel extends StatefulWidget {
  final List<String>? profileImages;
  final List<String>? profileNames;
  final List<String>? profileSvgs; // Optional custom SVG list

  const CircularProfileCarousel({
    super.key,
    this.profileImages,
    this.profileNames,
    this.profileSvgs,
  });

  @override
  State<CircularProfileCarousel> createState() =>
      _CircularProfileCarouselState();
}

class _CircularProfileCarouselState extends State<CircularProfileCarousel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Default 7 different SVG assets for profiles
  // Replace these with your actual SVG asset paths from EcliniqIcons
  late final List<String> defaultProfileSvgs;

  @override
  void initState() {
    super.initState();
    
    // Initialize default SVGs - replace with your actual icon paths
    defaultProfileSvgs = [
      EcliniqIcons.one.assetPath,   // Profile 1
      EcliniqIcons.two.assetPath,   // Profile 2 - REPLACE with different icon
      EcliniqIcons.three.assetPath,   // Profile 3 - REPLACE with different icon
      EcliniqIcons.four.assetPath,   // Profile 4 - REPLACE with different icon
      EcliniqIcons.five.assetPath,   // Profile 5 - REPLACE with different icon
      EcliniqIcons.six.assetPath,   // Profile 6 - REPLACE with different icon
      EcliniqIcons.seven.assetPath,   // Profile 7 - REPLACE with different icon
    ];
    
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String _getSvgForProfile(int profileIndex) {
    // Use custom SVGs if provided, otherwise use defaults
    if (widget.profileSvgs != null && profileIndex < widget.profileSvgs!.length) {
      return widget.profileSvgs![profileIndex];
    }
    return defaultProfileSvgs[profileIndex % defaultProfileSvgs.length];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Padding(
        padding: EdgeInsets.only(left: 12, right: 12, bottom: 0, top: 8),
        child: SizedBox(
          width: 360,
          height: 70,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double totalProgress = _controller.value * 3;
              int moveIndex = totalProgress.floor() % 3;
              double moveProgress = totalProgress % 1;

              List<int> baseArrangement;
              int? jumpingProfile;
              int? jumpingProfile2;
              int jumpFromPos = 0;
              int jumpToPos = 6;
              bool isDoubleJump = false;

              if (moveIndex == 0) {
                baseArrangement = [0, 1, 2, 3, 4, 5, 6];
                jumpingProfile = 0;
                jumpFromPos = 0;
                jumpToPos = 6;
              } else if (moveIndex == 1) {
                baseArrangement = [1, 2, 3, 4, 5, 6, 0];
                jumpingProfile = 1;
                jumpFromPos = 0;
                jumpToPos = 6;
              } else {
                baseArrangement = [2, 3, 4, 5, 6, 0, 1];
                jumpingProfile = 0;
                jumpingProfile2 = 1;
                isDoubleJump = true;
              }

              List<Widget> profiles = [];

              double containerWidth = screenWidth - 32;

              List<double> positions = [
                containerWidth * 0.03,
                containerWidth * 0.15,
                containerWidth * 0.28,
                containerWidth * 0.40,
                containerWidth * 0.54,
                containerWidth * 0.66,
                containerWidth * 0.78,
              ];

              // Sizes: center=32, ±1=28, ±2=24, ±3=20
              List<double> sizes = [20, 24, 28, 32, 28, 24, 20];
              List<double> baseOpacities = [0.4, 0.5, 0.7, 1.0, 0.7, 0.5, 0.4];

              for (int profileIndex = 0; profileIndex < 7; profileIndex++) {
                int currentPos = baseArrangement.indexOf(profileIndex);

                double xPos;
                double containerSize;
                double opacity;
                double zIndex;

                bool isJumping =
                    (profileIndex == jumpingProfile) ||
                    (isDoubleJump && profileIndex == jumpingProfile2);

                if (isJumping) {
                  int fromPos, toPos;

                  if (isDoubleJump) {
                    if (profileIndex == jumpingProfile) {
                      fromPos = 5;
                      toPos = 0;
                    } else {
                      fromPos = 6;
                      toPos = 1;
                    }
                  } else {
                    fromPos = jumpFromPos;
                    toPos = jumpToPos;
                  }

                  if (moveProgress < 0.4) {
                    xPos = positions[fromPos];
                    containerSize = sizes[fromPos];
                    opacity =
                        baseOpacities[fromPos] * (1.0 - moveProgress / 0.4);
                    zIndex = 10 - (fromPos - 3).abs().toDouble();
                  } else if (moveProgress > 0.6) {
                    xPos = positions[toPos];
                    containerSize = sizes[toPos];
                    opacity =
                        baseOpacities[toPos] * ((moveProgress - 0.6) / 0.4);
                    zIndex = 10 - (toPos - 3).abs().toDouble();
                  } else {
                    xPos = positions[toPos];
                    containerSize = sizes[toPos];
                    opacity = 0.0;
                    zIndex = 0;
                  }
                } else {
                  int targetPos;

                  if (isDoubleJump) {
                    targetPos = (currentPos + 2).clamp(0, 6);
                  } else {
                    targetPos = (currentPos - 1).clamp(0, 6);
                  }

                  xPos =
                      positions[currentPos] +
                      (positions[targetPos] - positions[currentPos]) *
                          moveProgress;

                  containerSize =
                      sizes[currentPos] +
                      (sizes[targetPos] - sizes[currentPos]) * moveProgress;

                  opacity =
                      baseOpacities[currentPos] +
                      (baseOpacities[targetPos] - baseOpacities[currentPos]) *
                          moveProgress;

                  double currentDistance = (currentPos - 3).abs().toDouble();
                  double targetDistance = (targetPos - 3).abs().toDouble();
                  zIndex =
                      10 -
                      (currentDistance +
                          (targetDistance - currentDistance) * moveProgress);
                }

                String? imageUrl;
                String? name;

                if (widget.profileImages != null &&
                    profileIndex < widget.profileImages!.length) {
                  imageUrl = widget.profileImages![profileIndex];
                }
                if (widget.profileNames != null &&
                    profileIndex < widget.profileNames!.length) {
                  name = widget.profileNames![profileIndex];
                }

                profiles.add(
                  _ProfileItem(
                    key: ValueKey(profileIndex),
                    x: xPos,
                    y: 35,
                    containerSize: containerSize,
                    opacity: opacity,
                    zIndex: zIndex,
                    imageUrl: imageUrl,
                    svgAssetPath: _getSvgForProfile(profileIndex),
                    initials: _getInitials(name),
                  ),
                );
              }

              profiles.sort((a, b) {
                final aItem = a as _ProfileItem;
                final bItem = b as _ProfileItem;
                return aItem.zIndex.compareTo(bItem.zIndex);
              });

              return Stack(children: profiles);
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final double x;
  final double y;
  final double containerSize;
  final double opacity;
  final double zIndex;
  final String? imageUrl;
  final String svgAssetPath;
  final String initials;

  const _ProfileItem({
    super.key,
    required this.x,
    required this.y,
    required this.containerSize,
    required this.opacity,
    required this.zIndex,
    this.imageUrl,
    required this.svgAssetPath,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x - (containerSize / 2),
      top: y - (containerSize / 2),
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: SizedBox(
          width: containerSize,
          height: containerSize,
          child: SvgPicture.asset(
            svgAssetPath,
            width: containerSize,
            height: containerSize,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: containerSize * 0.4,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2372EC),
        ),
      ),
    );
  }
}