import 'package:ecliniq/ecliniq_modules/screens/hospital/pages/surgery_list.dart';
import 'package:flutter/material.dart';

class HospitalDetailUI extends StatelessWidget {
  const HospitalDetailUI({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderImage(),
                const SizedBox(height: 16),
                _buildHospitalInfo(),
                _buildStatsCards(),
                Divider(color: Colors.grey.shade300, height: 0.5,),
                _buildBranchCard(
                  'Manipal Hospital - Baner',
                  'Multi-Speciality | 50+ Doctors | 650 Beds',
                  'Wakad',
                  '4 KM',
                  '4.0',
                  'OPD Timing: Mon-Fri (10:00 AM - 2:00 PM),\nSat - Sun (4:00 PM - 6:00 PM)',
                ),
                Divider(color: Colors.grey.shade300, height: 0.5,),
                _buildBranchCard(
                  'Manipal Hospital - Wakad',
                  'Multi-Speciality | 20+ Doctors | 650 Beds',
                  'Wakad',
                  '4 KM',
                  '4.0',
                  'OPD Timing: Mon-Fri (10:00 AM - 2:00 PM),\nSat - Sun (4:00 PM - 6:00 PM)',
                ),
                const SizedBox(height: 100),
              ],
            ),
            Positioned(
              top: 120,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue, width: 3),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.local_hospital,
                          size: 50,
                          color: Colors.orange[700],
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderImage() {
    return Container(
      height: 172,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800&q=80',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircleButton(Icons.arrow_back),
                _buildCircleButton(Icons.share),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 20),
    );
  }

  Widget _buildHospitalInfo() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 50, left: 8, right: 8, bottom: 8),
      child: Column(
        children: [
          const Text(
            'Manipal Hospital',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Multi-Specialty',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('|', style: TextStyle(color: Colors.grey[400])),
              ),
              Text(
                'All Branches Near You',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatCard(
            Icons.people,
            'Patients Served',
            '100,000',
          ),
          Container(
            width: 1,
            height: 60,
            color: Colors.grey[300],
          ),
          _buildStatCard(
            Icons.medical_services_outlined,
            'Doctors',
            '90',
          ),
          Container(
            width: 1,
            height: 60,
            color: Colors.grey[300],
          ),
          _buildStatCard(
            Icons.bed_outlined,
            'Total Bed',
            '1,800',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[600], size: 28),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBranchCard(
      String title,
      String subtitle,
      String location,
      String distance,
      String rating,
      String timing,
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),

      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                location,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              const SizedBox(width: 8),
              Text(
                distance,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Spacer(),
              Icon(Icons.star, size: 16, color: Colors.amber[700]),
              const SizedBox(width: 4),
              Text(
                rating,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  timing,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2372EC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View All Doctors',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.phone,
                  color: Color(0xff2372EC),
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}