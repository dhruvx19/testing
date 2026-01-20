import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CircularProfileCarousel extends StatefulWidget {
  final List<String>? profileImages;
  final List<String>? profileNames;

  const CircularProfileCarousel({
    super.key,
    this.profileImages,
    this.profileNames,
  });

  @override
  State<CircularProfileCarousel> createState() =>
      _CircularProfileCarouselState();
}

class _CircularProfileCarouselState extends State<CircularProfileCarousel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Fallback colors if no images provided
  // final List<Color> profileColors = [
  //   Color(0xFF4F46E5),
  //   Color(0xFF2372EC),
  //   Color(0xFFEC4899),
  //   Color(0xFFF59E0B),
  //   Color(0xFF10B981),
  //   Color(0xFF8B5CF6),
  //   Color(0xFF06B6D4),
  // ];

  @override
  void initState() {
    super.initState();
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
                    //  color: profileColors[profileIndex],
                    imageUrl: imageUrl,
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
  // final Color color;
  final String? imageUrl;
  final String initials;

  const _ProfileItem({
    super.key,
    required this.x,
    required this.y,
    required this.containerSize,
    required this.opacity,
    required this.zIndex,
    // required this.color,
    this.imageUrl,
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
          // decoration: BoxDecoration(
          //   shape: BoxShape.circle,
          //   // color: imageUrl == null,
          //   border: Border.all(color: Color(0xFF96BFFF), width: 1.5),
          // ),
          child: SvgPicture.asset(
            EcliniqIcons.photo2.assetPath,
            width: containerSize,
            height: containerSize,
          ),
          // child: ClipOval(
          //   child: imageUrl != null && imageUrl!.isNotEmpty
          //       ? Image.network(
          //           imageUrl!,
          //           fit: BoxFit.cover,
          //           errorBuilder: (context, error, stackTrace) {
          //             return _buildInitials();
          //           },
          //           loadingBuilder: (context, child, loadingProgress) {
          //             if (loadingProgress == null) return child;
          //             return _buildInitials();
          //           },
          //         )
          //       : _buildInitials(),
          // ),
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
