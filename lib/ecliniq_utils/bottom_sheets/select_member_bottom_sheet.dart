import 'dart:convert';

import 'package:ecliniq/ecliniq_api/models/patient.dart';
import 'package:ecliniq/ecliniq_api/patient_service.dart';
import 'package:ecliniq/ecliniq_api/src/api_client.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/add_dependent.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/widgets.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/circular.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class SelectMemberBottomSheet extends StatefulWidget {
  final DependentData? currentlySelectedDependent;

  const SelectMemberBottomSheet({super.key, this.currentlySelectedDependent});

  @override
  State<SelectMemberBottomSheet> createState() =>
      _SelectMemberBottomSheetState();
}

class _SelectMemberBottomSheetState extends State<SelectMemberBottomSheet> {
  int selectedIndex = 0;
  final PatientService _patientService = PatientService();
  bool _isLoading = true;
  String? _errorMessage;
  DependentData? _self;
  List<DependentData> _dependents = [];
  List<DependentData> _allMembers = [];
  String? _authToken;
  final Map<String, String> _imageUrlCache = {};

  @override
  void initState() {
    super.initState();
    _fetchDependents();
  }

  double _computeListHeight() {
    final double itemHeight = EcliniqTextStyles.getResponsiveHeight(context, 86);
    final double verticalMargin = EcliniqTextStyles.getResponsiveSpacing(context, 12);
    final count = _allMembers.length;
    if (count <= 0) return 0;
    final total = (itemHeight + verticalMargin) * count;
    final minHeight = EcliniqTextStyles.getResponsiveHeight(context, 86);
    final maxHeight = EcliniqTextStyles.getResponsiveHeight(context, 240);
    return total.clamp(minHeight, maxHeight);
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
          _self = response.self;
          _dependents = response.dependents;

          _allMembers = [];
          if (_self != null) {
            _allMembers.add(_self!);
          }
          _allMembers.addAll(_dependents);

          if (widget.currentlySelectedDependent != null) {
            final currentIndex = _allMembers.indexWhere(
              (member) => member.id == widget.currentlySelectedDependent!.id,
            );
            selectedIndex = currentIndex >= 0
                ? currentIndex
                : (_self != null ? 0 : -1);
          } else {
            if (_self != null) {
              final selfIndex = _allMembers.indexWhere(
                (member) => member.isSelf,
              );
              selectedIndex = selfIndex >= 0 ? selfIndex : 0;
            } else {
              selectedIndex = -1;
            }
          }

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
      final resp = await EcliniqHttpClient.get(uri, headers: headers);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        String? url;
        if (isPublic) {
          url = data?['publicUrl'];
        } else {
          url = data?['downloadUrl'];
        }
        if (url is String && url.isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _imageUrlCache[key] = url!;
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 20),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
              context,
              top: 12,
              left: 16,
              right: 16,
            ),
            child: Text(
              'Select Family Member',
              style: EcliniqTextStyles.responsiveHeadlineBMedium(
                context,
              ).copyWith(fontWeight: FontWeight.w500, color: Color(0xFF424242)),
            ),
          ),

          SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 16)),
          Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
              context,
              bottom: 2.0,
            ),
            child: SizedBox(
              height: _isLoading 
                  ? EcliniqTextStyles.getResponsiveHeight(context, 240) 
                  : _computeListHeight(),
              child: _isLoading
                  ? ShimmerListLoading(
                      itemCount: 3,
                      itemHeight: EcliniqTextStyles.getResponsiveHeight(context, 86),
                      padding: EdgeInsets.zero,
                    )
                  : _errorMessage != null
                  ? Padding(
                      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                        context,
                        horizontal: 16,
                        vertical: 0
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _allMembers.length,
                      itemBuilder: (context, index) {
                        final d = _allMembers[index];
                        final isSelected = selectedIndex == index;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });

                            Navigator.of(context).pop<DependentData>(d);
                          },
                          child: Container(
                            margin: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                              context,
                              horizontal: 16,
                              vertical: 4,
                            ),
                            padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(
                              context,
                              10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(0xFFF8F9FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(
                                EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
                              ),
                              border: Border.all(
                                color: isSelected
                                    ? Color(0xFF96BFFF)
                                    : Colors.white,
                                width: EcliniqTextStyles.getResponsiveSize(context, 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: EcliniqTextStyles.getResponsiveIconSize(context, 20),
                                  width: EcliniqTextStyles.getResponsiveIconSize(context, 20),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF8E8E8E),
                                      width: EcliniqTextStyles.getResponsiveSize(context, 1),
                                    ),
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
                                        : Colors.white,
                                  ),
                                  child: isSelected
                                      ? Container(
                                          margin: EcliniqTextStyles.getResponsiveEdgeInsetsAll(
                                            context,
                                            5,
                                          ),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),

                                SizedBox(
                                  width: EcliniqTextStyles.getResponsiveSpacing(
                                    context,
                                    8,
                                  ),
                                ),

                                Container(
                                  width: EcliniqTextStyles.getResponsiveWidth(
                                    context,
                                    52,
                                  ),
                                  height: EcliniqTextStyles.getResponsiveHeight(
                                    context,
                                    52,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xffF2F7FF),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Color(0xFF96BFFF),
                                      width: EcliniqTextStyles.getResponsiveSize(context, 0.6),
                                    ),
                                    image: () {
                                      final key = d.profilePhoto;
                                      if (key != null && key.isNotEmpty) {
                                        final cached = _imageUrlCache[key];
                                        if (cached != null &&
                                            cached.isNotEmpty) {
                                          return DecorationImage(
                                            fit: BoxFit.cover,
                                            image: NetworkImage(cached),
                                          );
                                        } else {
                                          _ensureDownloadUrl(
                                            key,
                                            isPublic: false,
                                          );
                                        }
                                      }
                                      return null;
                                    }(),
                                  ),
                                  child:
                                      (d.profilePhoto == null ||
                                              d.profilePhoto!.isEmpty) ||
                                          !_imageUrlCache.containsKey(
                                            d.profilePhoto!,
                                          )
                                      ? Center(
                                          child: Text(
                                            _initials(d.fullName),
                                            style:
                                                EcliniqTextStyles.responsiveHeadlineBMedium(
                                                  context,
                                                ).copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF2372EC),
                                                ),
                                          ),
                                        )
                                      : null,
                                ),

                                SizedBox(
                                  width: EcliniqTextStyles.getResponsiveSpacing(
                                    context,
                                    8,
                                  ),
                                ),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        d.fullName,
                                        style:
                                            EcliniqTextStyles.responsiveTitleXLarge(
                                              context,
                                            ).copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF424242),
                                            ),
                                      ),
                                      SizedBox(
                                        height:
                                            EcliniqTextStyles.getResponsiveSpacing(
                                              context,
                                              4,
                                            ),
                                      ),
                                      Text(
                                        d.formattedRelation,
                                        style:
                                            EcliniqTextStyles.responsiveBodySmall(
                                              context,
                                            ).copyWith(
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

          Container(
            margin: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16),
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
              context,
              left: 12,
              right: 12,
              bottom: 10,
              top: 0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                EcliniqTextStyles.getResponsiveBorderRadius(context, 8),
              ),
              border: Border.all(
                color: Color(0xFFD6D6D6),
                width: EcliniqTextStyles.getResponsiveSize(context, 0.5),
              ),
            ),
            child: Column(
              children: [
                CircularProfileCarousel(),

                InkWell(
                  onTap: () async {
                    final result = await EcliniqBottomSheet.show(
                      context: context,
                      child: AddDependentBottomSheet(),
                    );

                    if (mounted && result != null) {
                      await _fetchDependents();
                    }
                  },
                  child: Container(
                    height: EcliniqTextStyles.getResponsiveButtonHeight(
                      context,
                      baseHeight: 52.0,
                    ),
                    width: double.infinity,

                    decoration: BoxDecoration(
                      color: Color(0xFFF2F7FF),
                      borderRadius: BorderRadius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
                      ),
                      border: Border.all(
                        color: Color(0xFF96BFFF),
                        width: EcliniqTextStyles.getResponsiveSize(context, 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          EcliniqIcons.add.assetPath,
                          width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                          height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF2372EC),
                            BlendMode.srcIn,
                          ),
                        ),
                        SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 4)),
                        Text(
                          'Add Dependents',
                          style:
                              EcliniqTextStyles.responsiveHeadlineBMedium(
                                context,
                              ).copyWith(
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
          SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 12)),
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
