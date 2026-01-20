import 'package:flutter/material.dart';

class HospitalFilterParams {
  final String? city;
  final String? state;
  final String? type;
  final double? maxDistance;
  final int? minDoctors;
  final int? minBeds;

  HospitalFilterParams({
    this.city,
    this.state,
    this.type,
    this.maxDistance,
    this.minDoctors,
    this.minBeds,
  });

  bool get hasFilters =>
      city != null ||
      state != null ||
      type != null ||
      maxDistance != null ||
      minDoctors != null ||
      minBeds != null;

  HospitalFilterParams copyWith({
    String? city,
    String? state,
    String? type,
    double? maxDistance,
    int? minDoctors,
    int? minBeds,
  }) {
    return HospitalFilterParams(
      city: city ?? this.city,
      state: state ?? this.state,
      type: type ?? this.type,
      maxDistance: maxDistance ?? this.maxDistance,
      minDoctors: minDoctors ?? this.minDoctors,
      minBeds: minBeds ?? this.minBeds,
    );
  }
}







