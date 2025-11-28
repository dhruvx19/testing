import 'package:ecliniq/ecliniq_api/patient_service.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/my_doctors/model/doctor_details.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/my_doctors/widgets/doctor_info_widgets.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../ecliniq_icons/icons.dart';

class MyDoctors extends StatefulWidget {
  const MyDoctors({super.key});

  @override
  State<MyDoctors> createState() => _MyDoctorsState();
}

class _MyDoctorsState extends State<MyDoctors> {
  final PatientService _patientService = PatientService();
  List<FavouriteDoctor> _doctors = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFavouriteDoctors();
  }

  Future<void> _fetchFavouriteDoctors() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authToken = authProvider.authToken;

    if (authToken == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication required. Please login again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _patientService.getFavouriteDoctors(
        authToken: authToken,
      );

      if (mounted) {
        if (response.success) {
          setState(() {
            _doctors = response.data;
            _isLoading = false;
            _errorMessage = null;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = response.message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load doctors: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.arrowLeft.assetPath,
            width: 32,
            height: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'My Doctors',
            style: EcliniqTextStyles.headlineMedium.copyWith(
              color: Color(0xff424242),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.2),
          child: Container(color: Color(0xFFB8B8B8), height: 1.0),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(16),
            height: 50,
            padding: EdgeInsets.symmetric(horizontal: 10),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey, width: 1),
            ),
            child: Row(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Image.asset(
                  EcliniqIcons.magnifierMyDoctor.assetPath,
                  height: 24,
                  width: 24,
                ),
                Expanded(
                  child: TextField(
                    cursorColor: Colors.black,
                    decoration: InputDecoration(
                      hintText: 'Search Doctor',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                SvgPicture.asset(
                  EcliniqIcons.microphone.assetPath,
                  height: 32,
                  width: 32,
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildDoctorsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsList() {
    if (_isLoading) {
      return _buildShimmerList();
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: EcliniqTextStyles.bodyMedium.copyWith(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchFavouriteDoctors,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No favourite doctors yet',
              style: EcliniqTextStyles.bodyMedium.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _doctors.length,
      itemBuilder: (context, index) {
        return DoctorInfoWidget(doctor: _doctors[index]);
      },
    );
  }

  Widget _buildShimmerList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return Container(
          height: 300,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Avatar shimmer
                  ShimmerLoading(
                    width: 64,
                    height: 64,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  const SizedBox(width: 12),
                  // Name and details shimmer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerLoading(width: 160, height: 18, borderRadius: BorderRadius.circular(4)),
                        const SizedBox(height: 8),
                        ShimmerLoading(width: 120, height: 14, borderRadius: BorderRadius.circular(4)),
                        const SizedBox(height: 6),
                        ShimmerLoading(width: 100, height: 14, borderRadius: BorderRadius.circular(4)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ShimmerLoading(width: 24, height: 24, borderRadius: BorderRadius.circular(4)),
                ],
              ),
              // Stats row
              Row(
                children: [
                  ShimmerLoading(width: 24, height: 24, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(width: 10),
                  ShimmerLoading(width: 110, height: 16, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(width: 10),
                  ShimmerLoading(width: 58, height: 24, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(width: 10),
                  ShimmerLoading(width: 60, height: 16, borderRadius: BorderRadius.circular(4)),
                ],
              ),
              // Availability row
              Row(
                children: [
                  ShimmerLoading(width: 24, height: 24, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(width: 10),
                  ShimmerLoading(width: 140, height: 16, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(width: 8),
                  ShimmerLoading(width: 100, height: 16, borderRadius: BorderRadius.circular(4)),
                ],
              ),
              // Location row
              Row(
                children: [
                  ShimmerLoading(width: 24, height: 24, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ShimmerLoading(width: double.infinity, height: 16, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(width: 8),
                  ShimmerLoading(width: 70, height: 24, borderRadius: BorderRadius.circular(4)),
                ],
              ),
              // Tokens + button
              ShimmerLoading(width: 180, height: 24, borderRadius: BorderRadius.circular(4)),
              Row(
                children: [
                  Expanded(
                    child: ShimmerLoading(height: 48, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShimmerLoading(height: 48, borderRadius: BorderRadius.circular(4)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
