import 'dart:convert';
import 'package:ecliniq/ecliniq_api/src/api_client.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:http/http.dart' as http;

class SearchService {
  Future<Map<String, dynamic>> searchProviders({
    required String query,
    String? authToken,
  }) async {
    try {
      
      if (query.length < 3) {
        return {
          'success': false,
          'message': 'Search query must be at least 3 characters',
          'data': null,
          'errors': [
            {
              'message': 'Search query must be at least 3 characters',
              'path': ['q'],
              'type': 'string.min',
              'context': {
                'limit': 3,
                'value': query,
                'label': 'q',
                'key': 'q',
              },
            },
          ],
          'meta': null,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }

      final url = Uri.parse('${Endpoints.searchProviders}?q=${Uri.encodeComponent(query)}');

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
        headers['x-access-token'] = authToken;
      }

      final response = await EcliniqHttpClient.get(url, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Search failed',
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
}
