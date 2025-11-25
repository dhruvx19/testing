import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/add_dependent.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:ecliniq/ecliniq_api/patient_service.dart';
import 'package:ecliniq/ecliniq_api/models/patient.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SelectMemberBottomSheet extends StatefulWidget {
  const SelectMemberBottomSheet({super.key});

  @override
  State<SelectMemberBottomSheet> createState() =>
      _SelectMemberBottomSheetState();
}

class _SelectMemberBottomSheetState extends State<SelectMemberBottomSheet> {
  int selectedIndex = 0;
  final PatientService _patientService = PatientService();
  bool _isLoading = true;
  String? _errorMessage;
  List<DependentData> _dependents = [];
  String? _authToken;
  final Map<String, String> _imageUrlCache = {};

  @override
  void initState() {
    super.initState();
    _fetchDependents();
  }

  double _computeListHeight() {
    const double itemHeight = 86;
    const double verticalMargin = 12;
    final count = _dependents.length;
    if (count <= 0) return 0;
    final total = (itemHeight + verticalMargin) * count;
    return total.clamp(86.0, 240.0);
  }

  Future<void> _fetchDependents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authToken = authProvider.authToken;

      if (authToken == null || authToken.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication required. Please login again.';
        });
        return;
      }

      final response = await _patientService.getDependents(
        authToken: authToken,
      );
      if (!mounted) return;

      if (response.success) {
        setState(() {
          _dependents = response.data;
          _isLoading = false;
          _authToken = authToken;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load dependents: $e';
      });
    }
  }

  Future<void> _ensureDownloadUrl(String key, {bool isPublic = false}) async {
    if (_imageUrlCache.containsKey(key)) return;
    try {
      final uri = Uri.parse(
        isPublic
            ? '${Endpoints.storagePublicUrl}?key=${Uri.encodeComponent(key)}'
            : '${Endpoints.storageDownloadUrl}?key=${Uri.encodeComponent(key)}',
      );
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (!isPublic && _authToken != null && _authToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${_authToken!}';
        headers['x-access-token'] = _authToken!;
      }
      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        final url = isPublic ? data?['publicUrl'] : data?['downloadUrl'];
        if (url is String && url.isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _imageUrlCache[key] = url;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Select Family Member',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF424242),
              ),
            ),
          ),

          SizedBox(height: 20),
          // Dependents list
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: SizedBox(
              height: _isLoading ? 240 : _computeListHeight(),
              child: _isLoading
                  ? const ShimmerListLoading(
                      itemCount: 3,
                      itemHeight: 86,
                      padding: EdgeInsets.zero,
                    )
                  : _errorMessage != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _dependents.length,
                      itemBuilder: (context, index) {
                        final d = _dependents[index];
                        final isSelected = selectedIndex == index;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                            Navigator.of(context).pop<DependentData>(d);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(0xFFF8F9FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected
                                    ? Color(0xFF96BFFF)
                                    : Colors.white,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Radio button
                                Container(
                                  height: 24,
                                  width: 24,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected
                                          ? Color(0xFF4F46E5)
                                          : Color(0xFFD1D5DB),
                                      width: 2,
                                    ),
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: isSelected
                                      ? Center(
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFF4F46E5),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),

                                SizedBox(width: 16),

                                // Avatar
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Color(0xffF2F7FF),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Color(0xFF96BFFF),
                                      width: 0.6,
                                    ),
                                    image: () {
                                      final key = d.profilePhoto;
                                      if (key != null && key.isNotEmpty) {
                                        final cached = _imageUrlCache[key];
                                        if (cached != null && cached.isNotEmpty) {
                                          return DecorationImage(
                                            fit: BoxFit.cover,
                                            image: NetworkImage(cached),
                                          );
                                        } else {
                                          // kick off fetch, show initials till then
                                          _ensureDownloadUrl(key, isPublic: false);
                                        }
                                      }
                                      return null;
                                    }(),
                                  ),
                                  child: (d.profilePhoto == null ||
                                          d.profilePhoto!.isEmpty) ||
                                          !_imageUrlCache.containsKey(d.profilePhoto!)
                                      ? Center(
                                          child: Text(
                                            _initials(d.fullName),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2372EC),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),

                                SizedBox(width: 16),

                                // Name and Relation
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        d.fullName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF424242),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        d.relation,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFF626060),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          SizedBox(height: 12),

          // Add Dependents Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFFD6D6D6), width: 0.5),
            ),
            child: Column(
              children: [
                SizedBox(height: 16),

                InkWell(
                  onTap: () async {
                    final result = await EcliniqBottomSheet.show(
                      context: context,
                      child: AddDependentBottomSheet(),
                    );
                    // If user added a dependent successfully, refresh the list
                    if (mounted && result != null) {
                      await _fetchDependents();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Color(0xFFF2F7FF),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Color(0xFF96BFFF), width: 0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          EcliniqIcons.add.assetPath,
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF2372EC),
                            BlendMode.srcIn,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Add Dependents',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2372EC),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r"\s+"))
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'NA';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}
