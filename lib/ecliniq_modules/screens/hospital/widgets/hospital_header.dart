import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';

class HospitalHeaderWidget extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String specialty;
  final String doctorCount;
  final String establishedInfo;
  final String location;
  final String distance;
  final VoidCallback? onBackPressed;
  final VoidCallback? onFavoritePressed;
  final VoidCallback? onSharePressed;

  const HospitalHeaderWidget({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.specialty,
    required this.doctorCount,
    required this.establishedInfo,
    required this.location,
    required this.distance,
    this.onBackPressed,
    this.onFavoritePressed,
    this.onSharePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 50,
              left: 16,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: onBackPressed,
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(
                        Icons.favorite_border,
                        color: Colors.black,
                      ),
                      onPressed: onFavoritePressed,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.share, color: Colors.black),
                      onPressed: onSharePressed,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: -30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0E4395),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    color: Colors.orange,
                    size: 40,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Text(
                name,
                style:  EcliniqTextStyles.responsiveHeadlineXLarge(context).copyWith(
              
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    specialty,
                    style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    doctorCount,
                    style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                establishedInfo,
                style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFF0E4395),
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(location, style: EcliniqTextStyles.responsiveBodySmall(context).copyWith()),
                  const SizedBox(width: 8),
                  Text(
                    distance,
                    style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.navigation,
                    color: Colors.grey,
                    size: EcliniqTextStyles.getResponsiveIconSize(context, 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
