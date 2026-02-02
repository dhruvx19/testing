import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class NotificationsSettingsWidget extends StatefulWidget {
  final bool initialWhatsAppEnabled;
  final bool initialSmsEnabled;
  final bool initialInAppEnabled;
  final bool initialEmailEnabled;
  final bool initialPromotionalEnabled;
  final Function(NotificationSettings)? onSettingsChanged;

  const NotificationsSettingsWidget({
    super.key,
    this.initialWhatsAppEnabled = true,
    this.initialSmsEnabled = true,
    this.initialInAppEnabled = true,
    this.initialEmailEnabled = true,
    this.initialPromotionalEnabled = false,
    this.onSettingsChanged,
  });

  @override
  State<NotificationsSettingsWidget> createState() =>
      _NotificationsSettingsWidgetState();
}

class _NotificationsSettingsWidgetState
    extends State<NotificationsSettingsWidget> {
  late bool whatsAppEnabled;
  late bool smsEnabled;
  late bool inAppEnabled;
  late bool emailEnabled;
  late bool promotionalEnabled;
  bool _isWhatsAppEnabled = true;

  void _toggleWhatsAppUpdates(bool value) {
    setState(() {
      _isWhatsAppEnabled = value;
    });
  }

  @override
  void initState() {
    super.initState();
    whatsAppEnabled = widget.initialWhatsAppEnabled;
    smsEnabled = widget.initialSmsEnabled;
    inAppEnabled = widget.initialInAppEnabled;
    emailEnabled = widget.initialEmailEnabled;
    promotionalEnabled = widget.initialPromotionalEnabled;
  }

  void _updateSettings() {
    widget.onSettingsChanged?.call(
      NotificationSettings(
        whatsApp: whatsAppEnabled,
        sms: smsEnabled,
        inApp: inAppEnabled,
        email: emailEnabled,
        promotional: promotionalEnabled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(2),
            child: Text(
              'Notifications',
              style: EcliniqTextStyles.responsiveHeadlineLarge(
                context,
              ).copyWith(color: Color(0xff8E8E8E)),
            ),
          ),

          _NotificationToggleItem(
            icon: 'whatsapp',
            title: "What's App Notifications",
            subtitle:
                'Keep it turn ON to get the notification about your appointment and token number status',
            value: whatsAppEnabled,
            onChanged: (value) {
              setState(() {
                whatsAppEnabled = value;
              });
              _updateSettings();
            },
          ),

          _buildDivider(),

          _NotificationToggleItem(
            icon: 'sms',
            title: 'SMS Notifications',
            subtitle:
                'Keep it turn ON to get the notification about your appointment and token number status',
            value: smsEnabled,
            onChanged: (value) {
              setState(() {
                smsEnabled = value;
              });
              _updateSettings();
            },
          ),

          _buildDivider(),

          _NotificationToggleItem(
            icon: 'bell',
            title: 'In App Updates',
            subtitle:
                'Keep it turn ON to get the notification about your appointment and token number status',
            value: inAppEnabled,
            onChanged: (value) {
              setState(() {
                inAppEnabled = value;
              });
              _updateSettings();
            },
          ),

          _buildDivider(),

          _NotificationToggleItem(
            icon: 'email',
            title: 'Get Email Notifications',
            subtitle:
                'Keep it turn ON to get the new feature updates and newletters',
            value: emailEnabled,
            onChanged: (value) {
              setState(() {
                emailEnabled = value;
              });
              _updateSettings();
            },
          ),

          Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 8.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleWhatsAppUpdates(!_isWhatsAppEnabled),
                  child: Container(
                    width: EcliniqTextStyles.getResponsiveSize(context, 20.0),
                    height: EcliniqTextStyles.getResponsiveSize(context, 20.0),
                    decoration: BoxDecoration(
                      color: _isWhatsAppEnabled
                          ? const Color(0xff2372EC)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(
                          context,
                          4.0,
                        ),
                      ),
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
                            width: EcliniqTextStyles.getResponsiveIconSize(
                              context,
                              8.0,
                            ),
                            height: EcliniqTextStyles.getResponsiveIconSize(
                              context,
                              8.0,
                            ),
                          )
                        : null,
                  ),
                ),
                SizedBox(
                  width: EcliniqTextStyles.getResponsiveSpacing(context, 10.0),
                ),

                Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleWhatsAppUpdates(!_isWhatsAppEnabled),
                    behavior: HitTestBehavior.opaque,
                    child: EcliniqText(
                      'Get Promotional Messages and Updates',
                      style:
                          EcliniqTextStyles.responsiveBodySmallProminent(
                            context,
                          ).copyWith(
                            color: Color(0xff626060),
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // _NotificationToggleItem(
          //   icon: 'bell',
          //   title: 'Promotional Messages',
          //   subtitle: 'Get Promotional Messages and Updates',
          //   value: promotionalEnabled,
          //   onChanged: (value) {
          //     setState(() {
          //       promotionalEnabled = value;
          //     });
          //     _updateSettings();
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Divider(height: 1, thickness: 0.5, color: Color(0xffD6D6D6)),
    );
  }
}

class _NotificationToggleItem extends StatelessWidget {
  final String icon;

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationToggleItem({
    required this.icon,

    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  String _getIconPath() {
    switch (icon) {
      case 'whatsapp':
        return EcliniqIcons.whatsapp.assetPath;
      case 'sms':
        return EcliniqIcons.sms.assetPath;
      case 'bell':
        return EcliniqIcons.bellBlue.assetPath;
      case 'email':
        return EcliniqIcons.mail.assetPath;
      default:
        return EcliniqIcons.mail.assetPath;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: SvgPicture.asset(
              _getIconPath(),
              width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
              height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: EcliniqTextStyles.responsiveHeadlineXMedium(
                    context,
                  ).copyWith(color: Color(0xff424242)),
                ),
             
                Text(
                  subtitle,
                  style: EcliniqTextStyles.responsiveBodySmall(
                    context,
                  ).copyWith(color: Color(0xff8E8E8E)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 40,
            height: 23,
            child: GestureDetector(
              onTap: () {
                onChanged(!value);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 60,
                height: 30,
                decoration: BoxDecoration(
                  color: value ? Color(0xff0D47A1) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  curve: Curves.easeInOut,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationSettings {
  final bool whatsApp;
  final bool sms;
  final bool inApp;
  final bool email;
  final bool promotional;

  NotificationSettings({
    required this.whatsApp,
    required this.sms,
    required this.inApp,
    required this.email,
    required this.promotional,
  });
}
