import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class EasyWayToBookWidget extends StatefulWidget {
  const EasyWayToBookWidget({super.key});

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          children: [
            SizedBox(width: 16),

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
                        width: 1.5,
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

            Divider(height: 1,thickness: 0.5, color: Color(0xffB8B8B8), indent: 15, endIndent: 15),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleWhatsAppUpdates(!_isWhatsAppEnabled),
                    child: Container(
                      width: 20,
                      height: 20,
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
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
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
                          fontSize: 14,
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
}
