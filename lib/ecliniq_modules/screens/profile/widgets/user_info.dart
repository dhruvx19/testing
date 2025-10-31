import 'package:flutter/material.dart';

class UserInfoSection extends StatelessWidget {
  final String name;
  final String phone;
  final String email;
  final bool isPhoneVerified;

  const UserInfoSection({
    Key? key,
    required this.name,
    required this.phone,
    required this.email,
    this.isPhoneVerified = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              phone,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (isPhoneVerified) ...[
              const SizedBox(width: 5),
              const Icon(Icons.verified, color: Colors.green, size: 18),
            ],
          ],
        ),
        const SizedBox(height: 5),
        Text(email, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }
}
