

import 'dart:convert';
import 'package:ecliniq/ecliniq_api/models/hospital.dart';
import 'package:ecliniq/ecliniq_api/models/hospital_doctor_model.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:http/http.dart' as http;

class HospitalService {
  
  String? _authToken;

  
  void setAuthToken(String token) {
    _authToken = token;
  }

  
  void clearAuthToken() {
    _authToken = null;
  }

  
  String? get authToken => _authToken;

  Future<TopHospitalsResponse> getTopHospitals({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(Endpoints.topHospitals);

      
      final requestBody = TopHospitalsRequest(
        latitude: 12.9173,
        longitude: 77.6377,
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return TopHospitalsResponse.fromJson(responseData);
      } else if (response.statusCode == 400) {
        return TopHospitalsResponse(
          success: false,
          message: 'Invalid location coordinates',
          data: [],
          errors: 'Bad request',
          meta: {'statusCode': 400},
          timestamp: DateTime.now().toIso8601String(),
        );
      } else if (response.statusCode >= 500) {
        return TopHospitalsResponse(
          success: false,
          message: 'Server error: Please try again later',
          data: [],
          errors: 'Internal server error',
          meta: {'statusCode': response.statusCode},
          timestamp: DateTime.now().toIso8601String(),
        );
      } else {
        return TopHospitalsResponse(
          success: false,
          message: 'Failed to fetch hospitals: ${response.statusCode}',
          data: [],
          errors: response.body,
          meta: {'statusCode': response.statusCode},
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } on http.ClientException catch (e) {
      return TopHospitalsResponse(
        success: false,
        message: 'Network error: Unable to connect to server',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    } on FormatException catch (e) {
      return TopHospitalsResponse(
        success: false,
        message: 'Invalid response format from server',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      return TopHospitalsResponse(
        success: false,
        message: 'Unexpected error: $e',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<TopHospitalsResponse> getAllHospitals({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(Endpoints.getAllHospitals);

      final requestBody = {"latitude": latitude, "longitude": longitude};

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return TopHospitalsResponse.fromJson(responseData);
      } else {
        return TopHospitalsResponse(
          success: false,
          message: 'Failed to fetch hospitals: ${response.statusCode}',
          data: [],
          errors: response.body,
          meta: {'statusCode': response.statusCode},
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return TopHospitalsResponse(
        success: false,
        message: 'Unexpected error: $e',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<HospitalDetailsResponse> getHospitalDetails({
    required String hospitalId,
  }) async {
    
    if (hospitalId.isEmpty) {
      return HospitalDetailsResponse(
        success: false,
        message: 'Hospital ID is required',
        data: null,
        errors: 'Missing hospital ID',
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }

    try {
      final url = Uri.parse(Endpoints.hospitalDetails(hospitalId));

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return HospitalDetailsResponse.fromJson(responseData);
      } else if (response.statusCode == 404) {
        return HospitalDetailsResponse(
          success: false,
          message: 'Hospital not found',
          data: null,
          errors: 'Hospital ID does not exist',
          meta: {'statusCode': 404},
          timestamp: DateTime.now().toIso8601String(),
        );
      } else if (response.statusCode >= 500) {
        return HospitalDetailsResponse(
          success: false,
          message: 'Server error: Please try again later',
          data: null,
          errors: 'Internal server error',
          meta: {'statusCode': response.statusCode},
          timestamp: DateTime.now().toIso8601String(),
        );
      } else {
        return HospitalDetailsResponse(
          success: false,
          message: 'Failed to fetch hospital details: ${response.statusCode}',
          data: null,
          errors: response.body,
          meta: {'statusCode': response.statusCode},
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } on http.ClientException catch (e) {
      return HospitalDetailsResponse(
        success: false,
        message: 'Network error: Unable to connect to server',
        data: null,
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    } on FormatException catch (e) {
      return HospitalDetailsResponse(
        success: false,
        message: 'Invalid response format from server',
        data: null,
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      return HospitalDetailsResponse(
        success: false,
        message: 'Unexpected error: $e',
        data: null,
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<TopDoctorsResponse> getHospitalDoctors({
    required String hospitalId,
    required String authToken,
  }) async {
    
    if (hospitalId.isEmpty) {
      return TopDoctorsResponse(
        success: false,
        message: 'Hospital ID is required',
        data: [],
        errors: 'Missing hospital ID',
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }

    
    if (authToken.isEmpty) {
      return TopDoctorsResponse(
        success: false,
        message: 'Authentication token is required',
        data: [],
        errors: 'Missing authentication token',
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }

    try {
      final url = Uri.parse(Endpoints.getAllDoctorHospital(hospitalId));

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      
      final response = await http.get(url, headers: headers);

      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return TopDoctorsResponse.fromJson(responseData);
      } else if (response.statusCode == 401) {
        return TopDoctorsResponse(
          success: false,
          message: 'Unauthorized: Invalid or expired authentication token',
          data: [],
          errors: 'Authentication failed',
          meta: {'statusCode': 401},
          timestamp: DateTime.now().toIso8601String(),
        );
      } else if (response.statusCode == 403) {
        return TopDoctorsResponse(
          success: false,
          message: 'Forbidden: You do not have access to this resource',
          data: [],
          errors: 'Access denied',
          meta: {'statusCode': 403},
          timestamp: DateTime.now().toIso8601String(),
        );
      } else if (response.statusCode == 404) {
        return TopDoctorsResponse(
          success: false,
          message: 'Hospital not found',
          data: [],
          errors: 'Hospital ID does not exist',
          meta: {'statusCode': 404},
          timestamp: DateTime.now().toIso8601String(),
        );
      } else if (response.statusCode >= 500) {
        return TopDoctorsResponse(
          success: false,
          message: 'Server error: Please try again later',
          data: [],
          errors: 'Internal server error',
          meta: {'statusCode': response.statusCode},
          timestamp: DateTime.now().toIso8601String(),
        );
      } else {
        return TopDoctorsResponse(
          success: false,
          message: 'Failed to fetch doctors: ${response.statusCode}',
          data: [],
          errors: response.body,
          meta: {'statusCode': response.statusCode},
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } on http.ClientException catch (e) {
      return TopDoctorsResponse(
        success: false,
        message: 'Network error: Unable to connect to server',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    } on FormatException catch (e) {
      return TopDoctorsResponse(
        success: false,
        message: 'Invalid response format from server',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      return TopDoctorsResponse(
        success: false,
        message: 'Unexpected error: $e',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<TopHospitalsResponse> searchHospitals({
    required String query,
    double? latitude,
    double? longitude,
  }) async {
    if (query.isEmpty) {
      return TopHospitalsResponse(
        success: false,
        message: 'Search query is required',
        data: [],
        errors: 'Empty search query',
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }

    try {
      
      final response = await getTopHospitals(
        latitude: 12.9173,
        longitude: 77.6377,
      );

      if (response.success) {
        final filteredHospitals = response.data.where((hospital) {
          return hospital.name.toLowerCase().contains(query.toLowerCase());
        }).toList();

        return TopHospitalsResponse(
          success: true,
          message: 'Hospitals filtered successfully',
          data: filteredHospitals,
          errors: null,
          meta: {
            'searchQuery': query,
            'resultsCount': filteredHospitals.length,
          },
          timestamp: DateTime.now().toIso8601String(),
        );
      }

      return response;
    } catch (e) {
      return TopHospitalsResponse(
        success: false,
        message: 'Search failed: $e',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<TopDoctorsResponse> getDoctorsBySpecialization({
    required String hospitalId,
    required String specialization,
    required String authToken,
  }) async {
    try {
      final response = await getHospitalDoctors(
        hospitalId: hospitalId,
        authToken: authToken,
      );

      if (response.success) {
        final filteredDoctors = response.data.where((doctor) {
          return doctor.specializations.any(
            (spec) => spec.toLowerCase().contains(specialization.toLowerCase()),
          );
        }).toList();

        return TopDoctorsResponse(
          success: true,
          message: 'Doctors filtered by specialization',
          data: filteredDoctors,
          errors: null,
          meta: {
            'specialization': specialization,
            'resultsCount': filteredDoctors.length,
          },
          timestamp: DateTime.now().toIso8601String(),
        );
      }

      return response;
    } catch (e) {
      return TopDoctorsResponse(
        success: false,
        message: 'Failed to filter doctors: $e',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<TopDoctorsResponse> getAvailableDoctors({
    required String hospitalId,
    required String authToken,
  }) async {
    try {
      final response = await getHospitalDoctors(
        hospitalId: hospitalId,
        authToken: authToken,
      );

      if (response.success) {
        final availableDoctors = response.data.where((doctor) {
          return doctor.availability != null &&
              (doctor.availability!.availableTokens ?? 0) > 0;
        }).toList();

        return TopDoctorsResponse(
          success: true,
          message: 'Available doctors fetched successfully',
          data: availableDoctors,
          errors: null,
          meta: {'availableCount': availableDoctors.length},
          timestamp: DateTime.now().toIso8601String(),
        );
      }

      return response;
    } catch (e) {
      return TopDoctorsResponse(
        success: false,
        message: 'Failed to fetch available doctors: $e',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  Future<FilteredHospitalsResponse> getFilteredHospitalsTyped({
    required double latitude,
    required double longitude,
    String? searchQuery,
    String? city,
    String? state,
    double? distance,
    List<String>? speciality,
    String? availability,
    String? date,
    String? gender,
    String? workExperience,
    List<String>? languages,
    List<String>? practiceArea,
    int page = 1,
    int limit = 50,
    String? authToken,
  }) async {
    try {
      final url = Uri.parse(Endpoints.getFilteredHospitals);

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
        headers['x-access-token'] = authToken;
      }

      
      final requestBody = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'page': page,
        'limit': limit,
      };

      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        requestBody['searchQuery'] = searchQuery;
      }
      if (city != null && city.isNotEmpty) {
        requestBody['city'] = city;
      }
      if (state != null && state.isNotEmpty) {
        requestBody['state'] = state;
      }
      if (distance != null) {
        requestBody['distance'] = distance;
      }
      if (workExperience != null && workExperience.isNotEmpty) {
        requestBody['workExperience'] = workExperience;
      }
      if (practiceArea != null && practiceArea.isNotEmpty) {
        requestBody['practiceArea'] = practiceArea;
      }
      if (speciality != null && speciality.isNotEmpty) {
        requestBody['speciality'] = speciality;
      }
      if (availability != null && availability.isNotEmpty) {
        requestBody['availability'] = availability;
      }
      if (date != null && date.isNotEmpty) {
        requestBody['date'] = date;
      }
      if (gender != null && gender.isNotEmpty) {
        requestBody['gender'] = gender;
      }
      if (languages != null && languages.isNotEmpty) {
        requestBody['languages'] = languages;
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return FilteredHospitalsResponse.fromJson(responseData);
      } else {
        final responseData = jsonDecode(response.body);
        return FilteredHospitalsResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to fetch filtered hospitals',
          data: null,
          errors: responseData['errors'] ?? response.body,
          meta: {'statusCode': response.statusCode},
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return FilteredHospitalsResponse(
        success: false,
        message: 'Network error: $e',
        data: null,
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  
  
  
  
  
  
  Future<Map<String, dynamic>> getFilteredHospitals({
    required double latitude,
    required double longitude,
    String? city,
    double? distance,
    String? workExperience,
    List<String>? practiceArea,
    List<String>? speciality,
    String? availability,
    String? date,
    String? gender,
    List<String>? languages,
    String? searchQuery,
    int page = 1,
    int limit = 50,
    String? authToken,
  }) async {
    try {
      final url = Uri.parse(Endpoints.getFilteredHospitals);

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
        headers['x-access-token'] = authToken;
      }

      
      final requestBody = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'page': page,
        'limit': limit,
      };

      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        requestBody['searchQuery'] = searchQuery;
      }
      if (city != null && city.isNotEmpty) {
        requestBody['city'] = city;
      }
      if (distance != null) {
        requestBody['distance'] = distance;
      }
      if (workExperience != null && workExperience.isNotEmpty) {
        requestBody['workExperience'] = workExperience;
      }
      if (practiceArea != null && practiceArea.isNotEmpty) {
        requestBody['practiceArea'] = practiceArea;
      }
      if (speciality != null && speciality.isNotEmpty) {
        requestBody['speciality'] = speciality;
      }
      if (availability != null && availability.isNotEmpty) {
        requestBody['availability'] = availability;
      }
      if (date != null && date.isNotEmpty) {
        requestBody['date'] = date;
      }
      if (gender != null && gender.isNotEmpty) {
        requestBody['gender'] = gender;
      }
      if (languages != null && languages.isNotEmpty) {
        requestBody['languages'] = languages;
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch filtered hospitals',
          'data': null,
          'errors': responseData['errors'] ?? response.body,
          'meta': null,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
        'errors': e.toString(),
        'meta': null,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  
  
  
  
  
  Future<Map<String, dynamic>> getFilteredHospitalsFromMap({
    required Map<String, dynamic> filters,
    String? authToken,
  }) async {
    return getFilteredHospitals(
      latitude: filters['latitude'] as double? ?? 12.9173,
      longitude: filters['longitude'] as double? ?? 77.6377,
      city: filters['city'] as String?,
      distance: filters['distance'] as double?,
      workExperience: filters['workExperience'] as String?,
      practiceArea: filters['practiceArea'] as List<String>?,
      speciality: filters['speciality'] as List<String>?,
      availability: filters['availability'] as String?,
      date: filters['date'] as String?,
      gender: filters['gender'] as String?,
      languages: filters['languages'] as List<String>?,
      searchQuery: filters['searchQuery'] as String?,
      page: filters['page'] as int? ?? 1,
      limit: filters['limit'] as int? ?? 50,
      authToken: authToken,
    );
  }
}
