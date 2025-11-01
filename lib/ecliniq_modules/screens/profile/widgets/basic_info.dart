import 'package:flutter/material.dart';

class BasicInfoCards extends StatelessWidget {
  final String age;
  final String gender;
  final String bloodGroup;

  const BasicInfoCards({
    super.key,
    required this.age,
    required this.gender,
    required this.bloodGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _InfoCard(
          icon: Icons.cake_outlined,
          label: "Age",
          value: age,
          iconColor: Colors.blue,
        ),
        _InfoCard(
          icon: Icons.person_outline,
          label: "Gender",
          value: gender,
          iconColor: Colors.blue,
        ),
        _InfoCard(
          icon: Icons.bloodtype_outlined,
          label: "Blood Group",
          value: bloodGroup,
          iconColor: Colors.red,
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class ProfileHeader extends StatelessWidget {
  final VoidCallback? onSettingsPressed;
  final String? profileImageUrl;

  const ProfileHeader({
    super.key,
    this.onSettingsPressed,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(

      child:Column(
        children: [

          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20, top: 10),
              child: IconButton(
                icon: const Icon(
                  Icons.my_location_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: onSettingsPressed,
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(1.0),
                    Colors.white.withOpacity(0.0),
                  ],
                ).createShader(bounds);
              },
              child: const Text(
                "Profile",
                style: TextStyle(
                  fontSize: 74,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: Colors.white,
                ),
              ),
            ),
          ),
           

          
         
        ],
      ),
    );
  }
}
