import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';

class StatisticsWidget extends StatelessWidget {
  final String patientsServed;
  final String totalDoctors;
  final String totalBeds;

  const StatisticsWidget({
    super.key,
    required this.patientsServed,
    required this.totalDoctors,
    required this.totalBeds,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
             context:   context,
            icon: Icons.people,
            label: 'Patients Served',
            value: patientsServed,
          ),
          _buildStatItem(
             context:   context,
            icon: Icons.medical_services,
            label: 'Doctors',
            value: totalDoctors,
          ),
          _buildStatItem(
             context:   context,
            icon: Icons.bed,
            label: 'Total Beds',
            value: totalBeds,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required BuildContext context,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF0E4395),
          size: EcliniqTextStyles.getResponsiveIconSize(context, 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: EcliniqTextStyles.responsiveBodyXSmall(context).copyWith(
       
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style:  EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
          
            fontWeight: FontWeight.bold,
            color: Color(0xFF0E4395),
          ),
        ),
      ],
    );
  }
}
