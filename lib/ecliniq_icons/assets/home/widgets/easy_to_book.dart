import 'package:ecliniq/ecliniq_icons/icons.dart';
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
              width: 8,
              height: 24,
              decoration: BoxDecoration(
                color: Color(0xFF96BFFF),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Easy Way to book',
                    style: TextStyle(
                      fontSize: 20.0,
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
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SvgPicture.asset(
                    EcliniqIcons.call.assetPath,
                    width: 32,
                    height: 32,
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Request a Callback',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff424242),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Assisted booking with expert',
                          style: TextStyle(
                            fontSize: 14,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      side: const BorderSide(
                        color: Color(0xFF96BFFF),
                        width: 0.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: Color(0xFFF2F7FF),
                    ),
                    child: const Text(
                      'Call Us',
                      style: TextStyle(
                        color: Color(0xFF2372EC),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              color: Color(0xffB8B8B8),
              thickness: 0.5,
              indent: 16,
              endIndent: 16,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleWhatsAppUpdates(!_isWhatsAppEnabled),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _isWhatsAppEnabled
                            ? const Color(0xff2372EC)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(4),
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
                              width: 10,
                              height: 10,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),

                  Expanded(
                    child: GestureDetector(
                      onTap: () => _toggleWhatsAppUpdates(!_isWhatsAppEnabled),
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        'Get updates/information on WhatsApp/SMS',
                        style: TextStyle(
                          fontSize: 13,
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
              width: 8,
              height: 24,
              decoration: BoxDecoration(
                color: Color(0xFF96BFFF),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 20,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200, width: 1),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              height: 16,
                              width: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              height: 14,
                              width: 200,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4.0),
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
                        height: 32,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: Colors.grey.shade200),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4.0),
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
