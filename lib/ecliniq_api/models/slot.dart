class Slot {
  final String id;
  final String doctorId;
  final String hospitalId;
  final String? clinicId;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime date;
  final String slotStatus;
  final DateTime? delayedTime;
  final int maxTokens;
  final int bookedTokens;
  final int lastTokenNo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Slot({
    required this.id,
    required this.doctorId,
    required this.hospitalId,
    this.clinicId,
    required this.startTime,
    required this.endTime,
    required this.date,
    required this.slotStatus,
    this.delayedTime,
    required this.maxTokens,
    required this.bookedTokens,
    required this.lastTokenNo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    // Parse times as UTC to ensure correct timezone handling
    final parseTime = (dynamic timeValue) {
      if (timeValue == null) {
        return DateTime.utc(1970, 1, 1);
      }
      // Convert to string if it's not already
      final timeStr = timeValue is String ? timeValue : timeValue.toString();
      try {
        final parsed = DateTime.parse(timeStr);
        // Ensure UTC time - if parsed as local, convert to UTC
        return parsed.isUtc ? parsed : DateTime.utc(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
          parsed.millisecond,
          parsed.microsecond,
        );
      } catch (e) {
        return DateTime.utc(1970, 1, 1);
      }
    };
    
    // Helper to safely convert to string
    final toString = (dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      return value.toString();
    };
    
    // Helper to safely convert to int
    final toInt = (dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is double) return value.toInt();
      return defaultValue;
    };
    
    return Slot(
      id: toString(json['id'], ''),
      doctorId: toString(json['doctorId'], ''),
      hospitalId: toString(json['hospitalId'], ''),
      clinicId: json['clinicId'] != null ? toString(json['clinicId'], '') : null,
      startTime: parseTime(json['startTime']),
      endTime: parseTime(json['endTime']),
      date: parseTime(json['date']),
      slotStatus: toString(json['slotStatus'], ''),
      delayedTime: json['delayedTime'] != null ? parseTime(json['delayedTime']) : null,
      maxTokens: toInt(json['maxTokens'], 0),
      bookedTokens: toInt(json['bookedTokens'], 0),
      lastTokenNo: toInt(json['lastTokenNo'], 0),
      createdAt: parseTime(json['createdAt']),
      updatedAt: parseTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'hospitalId': hospitalId,
      if (clinicId != null) 'clinicId': clinicId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'date': date.toIso8601String(),
      'slotStatus': slotStatus,
      if (delayedTime != null) 'delayedTime': delayedTime!.toIso8601String(),
      'maxTokens': maxTokens,
      'bookedTokens': bookedTokens,
      'lastTokenNo': lastTokenNo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  int get availableTokens => maxTokens - bookedTokens;
}

class SlotResponse {
  final bool success;
  final String message;
  final List<Slot> data;
  final dynamic errors;
  final dynamic meta;
  final String timestamp;

  SlotResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.errors,
    required this.meta,
    required this.timestamp,
  });

  factory SlotResponse.fromJson(Map<String, dynamic> json) {
    return SlotResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => Slot.fromJson(item))
          .toList() ?? [],
      errors: json['errors'],
      meta: json['meta'],
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((slot) => slot.toJson()).toList(),
      'errors': errors,
      'meta': meta,
      'timestamp': timestamp,
    };
  }
}

class FindSlotsRequest {
  final String doctorId;
  final String date;
  final String? hospitalId;
  final String? clinicId;

  FindSlotsRequest({
    required this.doctorId,
    required this.date,
    this.hospitalId,
    this.clinicId,
  }) : assert(
          hospitalId != null || clinicId != null,
          'Either hospitalId or clinicId must be provided',
        );

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'doctorId': doctorId,
      'date': date,
    };
    
    if (hospitalId != null) {
      json['hospitalId'] = hospitalId;
    }
    if (clinicId != null) {
      json['clinicId'] = clinicId;
    }
    
    return json;
  }
}

class HoldTokenRequest {
  final String slotId;

  HoldTokenRequest({
    required this.slotId,
  });

  Map<String, dynamic> toJson() {
    return {
      'slotId': slotId,
    };
  }
}

class HoldTokenSlotInfo {
  final String id;
  final int totalTokens;
  final int availableTokens;
  final int holdTokens;
  final int bookedTokens;

  HoldTokenSlotInfo({
    required this.id,
    required this.totalTokens,
    required this.availableTokens,
    required this.holdTokens,
    required this.bookedTokens,
  });

  factory HoldTokenSlotInfo.fromJson(Map<String, dynamic> json) {
    final toInt = (dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is double) return value.toInt();
      return defaultValue;
    };

    final toString = (dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      return value.toString();
    };

    return HoldTokenSlotInfo(
      id: toString(json['id'], ''),
      totalTokens: toInt(json['totalTokens'], 0),
      availableTokens: toInt(json['availableTokens'], 0),
      holdTokens: toInt(json['holdTokens'], 0),
      bookedTokens: toInt(json['bookedTokens'], 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'totalTokens': totalTokens,
      'availableTokens': availableTokens,
      'holdTokens': holdTokens,
      'bookedTokens': bookedTokens,
    };
  }
}

class HoldTokenData {
  final bool success;
  final String message;
  final DateTime expiresAt;
  final HoldTokenSlotInfo slot;

  HoldTokenData({
    required this.success,
    required this.message,
    required this.expiresAt,
    required this.slot,
  });

  factory HoldTokenData.fromJson(Map<String, dynamic> json) {
    final parseTime = (dynamic timeValue) {
      if (timeValue == null) {
        return DateTime.utc(1970, 1, 1);
      }
      final timeStr = timeValue is String ? timeValue : timeValue.toString();
      try {
        final parsed = DateTime.parse(timeStr);
        return parsed.isUtc ? parsed : DateTime.utc(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
          parsed.millisecond,
          parsed.microsecond,
        );
      } catch (e) {
        return DateTime.utc(1970, 1, 1);
      }
    };

    return HoldTokenData(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      expiresAt: parseTime(json['expiresAt']),
      slot: HoldTokenSlotInfo.fromJson(json['slot'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'expiresAt': expiresAt.toIso8601String(),
      'slot': slot.toJson(),
    };
  }
}

class HoldTokenResponse {
  final bool success;
  final String message;
  final HoldTokenData? data;
  final dynamic errors;
  final dynamic meta;
  final String timestamp;

  HoldTokenResponse({
    required this.success,
    required this.message,
    this.data,
    required this.errors,
    required this.meta,
    required this.timestamp,
  });

  factory HoldTokenResponse.fromJson(Map<String, dynamic> json) {
    return HoldTokenResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? HoldTokenData.fromJson(json['data']) : null,
      errors: json['errors'],
      meta: json['meta'],
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
      'errors': errors,
      'meta': meta,
      'timestamp': timestamp,
    };
  }
}

