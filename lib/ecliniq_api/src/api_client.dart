import 'dart:convert';
import 'package:http/http.dart' as http;

typedef UnauthorizedCallback = void Function();

class EcliniqHttpClient {
  static UnauthorizedCallback? _onUnauthorized;

  static void setUnauthorizedCallback(UnauthorizedCallback callback) {
    _onUnauthorized = callback;
  }

  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final response = await http.get(url, headers: headers);
    _checkUnauthorized(response);
    return response;
  }

  static Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final response = await http.post(url, headers: headers, body: body, encoding: encoding);
    _checkUnauthorized(response);
    return response;
  }

  static Future<http.Response> patch(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final response = await http.patch(url, headers: headers, body: body, encoding: encoding);
    _checkUnauthorized(response);
    return response;
  }

  static Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final response = await http.delete(url, headers: headers, body: body, encoding: encoding);
    _checkUnauthorized(response);
    return response;
  }

  static Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final response = await http.put(url, headers: headers, body: body, encoding: encoding);
    _checkUnauthorized(response);
    return response;
  }

  static void _checkUnauthorized(http.Response response) {
    bool isUnauthorized = false;

    // Direct status code checks
    if (response.statusCode == 401 || response.statusCode == 403) {
      isUnauthorized = true;
    } else {
      // Check for specific error message patterns in the body
      try {
        final bodyString = response.body.toLowerCase();
        if (bodyString.contains('authentication required') ||
            bodyString.contains('invalid token') ||
            bodyString.contains('token expired') ||
            bodyString.contains('unauthorized access')) {
          isUnauthorized = true;
        }
        
        // Also check decoded body if it's JSON
        final body = jsonDecode(response.body);
        if (body is Map && body['message'] != null) {
          final msg = body['message'].toString().toLowerCase();
          if (msg.contains('login') && msg.contains('again')) {
             isUnauthorized = true;
          }
        }
      } catch (_) {
        // Not JSON or other parsing error, ignore
      }
    }

    if (isUnauthorized && _onUnauthorized != null) {
      _onUnauthorized!();
    }
  }
}
