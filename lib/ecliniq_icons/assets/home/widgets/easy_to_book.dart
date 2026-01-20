import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';

class EasyWayToBookWidget extends StatefulWidget {
  final bool showShimmer;

  const EasyWayToBookWidget({super.key, this.showShimmer = false});

  @override
  State<EasyWayToBookWidget> createState() => _EasyWayToBookWidgetState();
}

class _EasyWayToBookWidgetState extends State<EasyWayToBookWidget> {
  bool _isWhatsAppEnabled = true;

  void _callUs() {
    print('Call us tapped');
  }

  void _toggleWhatsAppUpdates(bool value) {
    setState(() {
      _isWhatsAppEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showShimmer) {
      return _buildShimmer();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: EcliniqTextStyles.getResponsiveSize(context, 8.0),
              height: EcliniqTextStyles.getResponsiveSize(context, 24.0),
              decoration: BoxDecoration(
                color: Color(0xFF96BFFF),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0)),
                  bottomRight: Radius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0)),
                ),
              ),
            ),
            SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 12.0)),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  EcliniqText(
                    'Easy Way to book',
                    style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: Color(0xff424242),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        Column(
          children: [
            Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                context,
                top: 8.0,
                left: 16.0,
                right: 16.0,
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    EcliniqIcons.call.assetPath,
                    width: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
                    height: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
                  ),
                  SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 12.0)),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EcliniqText(
                          'Request a Callback',
                          style: EcliniqTextStyles.responsiveHeadlineZMedium(context).copyWith(
                            fontWeight: FontWeight.w500,
                            color: Color(0xff424242),
                          ),
                        ),
                        SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 2.0)),
                        EcliniqText(
                          'Assisted booking with expert',
                          style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                            color: Color(0xff8E8E8E),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  OutlinedButton(
                    onPressed: _callUs,
                    style: OutlinedButton.styleFrom(
                      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                        context,
                        horizontal: 14.0,
                        vertical: 7.0,
                      ),
                      side: const BorderSide(
                        color: Color(0xFF96BFFF),
                        width: 0.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 8.0)),
                      ),
                      backgroundColor: Color(0xFFF2F7FF),
                    ),
                    child: EcliniqText(
                      'Call Us',
                      style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                        color: Color(0xFF2372EC),

                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 8.0)),
            Divider(
              height: 1,
              color: Color(0xffB8B8B8),
              thickness: 0.5,
              indent: EcliniqTextStyles.getResponsiveSize(context, 16.0),
              endIndent: EcliniqTextStyles.getResponsiveSize(context, 16.0),
            ),

            Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleWhatsAppUpdates(!_isWhatsAppEnabled),
                    child: Container(
                      width: EcliniqTextStyles.getResponsiveSize(context, 16.0),
                      height: EcliniqTextStyles.getResponsiveSize(context, 16.0),
                      decoration: BoxDecoration(
                        color: _isWhatsAppEnabled
                            ? const Color(0xff2372EC)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0)),
                        border: Border.all(
                          color: _isWhatsAppEnabled
                              ? const Color(0xff2372EC)
                              : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: _isWhatsAppEnabled
                          ? SvgPicture.asset(
                              EcliniqIcons.checkWhite.assetPath,
                              width: EcliniqTextStyles.getResponsiveIconSize(context, 10.0),
                              height: EcliniqTextStyles.getResponsiveIconSize(context, 10.0),
                            )
                          : null,
                    ),
                  ),
                  SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 10.0)),

                  Expanded(
                    child: GestureDetector(
                      onTap: () => _toggleWhatsAppUpdates(!_isWhatsAppEnabled),
                      behavior: HitTestBehavior.opaque,
                      child: EcliniqText(
                        'Get updates/information on WhatsApp/SMS',
                        style: EcliniqTextStyles.responsiveBodyMediumProminent(context).copyWith(
                   
                          color: Color(0xff626060),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: EcliniqTextStyles.getResponsiveSize(context, 8.0),
              height: EcliniqTextStyles.getResponsiveSize(context, 24.0),
              decoration: BoxDecoration(
                color: Color(0xFF96BFFF),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0)),
                  bottomRight: Radius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0)),
                ),
              ),
            ),
            SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 12.0)),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: EcliniqTextStyles.getResponsiveSize(context, 20.0),
                width: EcliniqTextStyles.getResponsiveWidth(context, 150.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0)),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 20.0)),

        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200, width: 1),
            borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 8.0)),
            color: Colors.grey.shade50,
          ),
          child: Column(
            children: [
              Padding(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16.0),
                child: Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: EcliniqTextStyles.getResponsiveSize(context, 36.0),
                        height: EcliniqTextStyles.getResponsiveSize(context, 36.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 8.0)),
                        ),
                      ),
                    ),
                    SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 12.0)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              height: EcliniqTextStyles.getResponsiveSize(context, 16.0),
                              width: EcliniqTextStyles.getResponsiveWidth(context, 150.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0)),
                              ),
                            ),
                          ),
                          SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 8.0)),
                          Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              height: EcliniqTextStyles.getResponsiveSize(context, 14.0),
                              width: EcliniqTextStyles.getResponsiveWidth(context, 200.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        height: EcliniqTextStyles.getResponsiveSize(context, 32.0),
                        width: EcliniqTextStyles.getResponsiveWidth(context, 80.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 8.0)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: Colors.grey.shade200),
              Padding(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16.0),
                child: Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: EcliniqTextStyles.getResponsiveSize(context, 16.0),
                        height: EcliniqTextStyles.getResponsiveSize(context, 16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0)),
                        ),
                      ),
                    ),
                    SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 10.0)),
                    Expanded(
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          height: EcliniqTextStyles.getResponsiveSize(context, 14.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
