import 'package:url_launcher/url_launcher.dart';

/// Utility class for launching phone calls
class PhoneLauncher {
  /// Launches the phone dialer with the given phone number
  /// If phone number is null or empty, uses a random number for testing
  /// 
  /// @param phoneNumber - The phone number to dial (can be null or empty)
  /// @returns Future<bool> - Returns true if the phone dialer was launched successfully
  static Future<bool> launchPhoneCall(String? phoneNumber) async {
    // If no phone number provided, use a random number for testing
    String numberToCall = phoneNumber?.trim() ?? '1234567890';
    
    // Remove any non-digit characters except +
    numberToCall = numberToCall.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If number doesn't start with +, add it (assuming default country code)
    if (!numberToCall.startsWith('+')) {
      // If it's a 10-digit number, assume it's Indian (+91)
      if (numberToCall.length == 10) {
        numberToCall = '+91$numberToCall';
      } else {
        // Otherwise, just add + prefix
        numberToCall = '+$numberToCall';
      }
    }
    
    final Uri phoneUri = Uri(scheme: 'tel', path: numberToCall);
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // If launching fails, return false
      return false;
    }
  }
}



