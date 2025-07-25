import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marketplace_app/utils/constants.dart';

// Service class for authentication operations (login, registration, token management).
class AuthService {
  // Saves the access token to shared preferences.
  Future<void> _saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  // Retrieves the access token from shared preferences.
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Clears the access token from shared preferences (logs out user).
  Future<void> clearAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  // Parses the HTTP response body, handling JSON decoding errors.
  Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return {'message': 'Empty response from server.'};
    } on FormatException {
      return {'message': 'Received an unexpected response from the server.'};
    } catch (e) {
      return {'message': 'An unexpected error occurred: ${e.toString()}'};
    }
  }

  // Handles user registration.
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phoneNumber,
  }) async {
    final response = await http.post(
      Uri.parse('$kApiUrl/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'email': email,
        'password': password,
        if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
        if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phone_number': phoneNumber,
      }),
    );

    final responseBody = _parseResponse(response);

    if (response.statusCode == 201) {
      final accessToken = responseBody['access_token'];
      if (accessToken != null) {
        await _saveAccessToken(
          accessToken,
        ); // Save token on successful registration
        return {
          'success': true,
          'token': accessToken,
          'user': responseBody['user'],
        };
      } else {
        return {
          'success': false,
          'message': 'Registration successful but no token received.',
        };
      }
    } else if (response.statusCode == 429) {
      return {
        'success': false,
        'message': 'Too many registration attempts. Please try again later.',
      };
    } else {
      return {
        'success': false,
        'message':
            responseBody['message'] ??
            'Registration failed. Please check your details.',
      };
    }
  }

  // Handles user login.
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$kApiUrl/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
      }),
    );

    final responseBody = _parseResponse(response);

    if (response.statusCode == 200) {
      final accessToken = responseBody['access_token'];
      if (accessToken != null) {
        await _saveAccessToken(accessToken); // Save token on successful login
        return {'success': true, 'token': accessToken};
      } else {
        return {
          'success': false,
          'message': 'Login successful but no token received',
        };
      }
    } else if (response.statusCode == 429) {
      return {
        'success': false,
        'message': 'Too many login attempts. Please wait a moment.',
      };
    } else {
      return {
        'success': false,
        'message':
            responseBody['message'] ?? responseBody['msg'] ?? 'Login failed',
      };
    }
  }

  // Fetches the current authenticated user's details.
  Future<Map<String, dynamic>> fetchCurrentUser() async {
    final token = await getAccessToken();
    if (token == null) {
      return {'success': false, 'message': 'Not authenticated.'};
    }

    final response = await http.get(
      Uri.parse('$kApiUrl/user'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization':
            'Bearer $token', // Include access token for authorization
      },
    );

    final responseBody = _parseResponse(response);

    if (response.statusCode == 200) {
      return {'success': true, 'user': responseBody};
    } else if (response.statusCode == 401) {
      await clearAccessToken(); // Clear token if unauthorized (session expired)
      return {
        'success': false,
        'message': 'Session expired. Please log in again.',
      };
    } else {
      return {
        'success': false,
        'message': responseBody['message'] ?? 'Failed to fetch user data.',
      };
    }
  }

  // Updates the current authenticated user's profile.
  Future<Map<String, dynamic>> updateUser(Map<String, dynamic> userData) async {
    final token = await getAccessToken();
    if (token == null) {
      return {'success': false, 'message': 'Not authenticated.'};
    }

    final response = await http.put(
      Uri.parse('$kApiUrl/user'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization':
            'Bearer $token', // Include access token for authorization
      },
      body: jsonEncode(userData),
    );

    final responseBody = _parseResponse(response);

    if (response.statusCode == 200) {
      return {'success': true, 'user': responseBody};
    } else if (response.statusCode == 401) {
      await clearAccessToken(); // Clear token if unauthorized
      return {
        'success': false,
        'message': 'Session expired. Please log in again.',
      };
    } else if (response.statusCode == 409) {
      return {
        'success': false,
        'message':
            responseBody['message'] ?? 'Username or email already taken.',
      };
    } else {
      return {
        'success': false,
        'message': responseBody['message'] ?? 'Failed to update profile.',
      };
    }
  }

  // Deletes the current authenticated user's account.
  Future<Map<String, dynamic>> deleteCurrentUser() async {
    final token = await getAccessToken();
    if (token == null) {
      return {'success': false, 'message': 'Not authenticated.'};
    }

    final response = await http.delete(
      Uri.parse('$kApiUrl/user'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization':
            'Bearer $token', // Include access token for authorization
      },
    );
    final responseBody = _parseResponse(response);

    if (response.statusCode == 204) {
      await clearAccessToken(); // Clear token on successful deletion
      return {'success': true, 'message': 'Account deleted successfully!'};
    } else {
      final message =
          responseBody['message'] ??
          responseBody['msg'] ??
          'Failed to delete account.';
      return {'success': false, 'message': message};
    }
  }

  // Fetches a protected resource, requiring an access token.
  Future<http.Response> getProtectedResource(String endpoint) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('No access token found. User not logged in.');
    }

    final response = await http.get(
      Uri.parse('$kApiUrl/$endpoint'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // Include access token
      },
    );
    return response;
  }
}
