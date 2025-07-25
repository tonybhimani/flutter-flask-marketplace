import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:marketplace_app/utils/constants.dart';
import 'package:marketplace_app/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

// Service for interacting with listing-related API endpoints.
class ListingService {
  final AuthService _authService =
      AuthService(); // Authentication service to get tokens.

  // Handles and parses HTTP responses, providing a success status and data/message.
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': response.body.isNotEmpty ? jsonDecode(response.body) : null,
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Authentication required or unauthorized access.',
        };
      } else if (response.statusCode == 429) {
        return {
          'success': false,
          'message': 'Too many requests. Please try again later.',
        };
      } else if (response.statusCode == 415) {
        final errorData = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : null;
        return {
          'success': false,
          'message':
              errorData?['message'] ?? 'Unsupported media type uploaded.',
        };
      } else {
        final errorData = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : null;
        return {
          'success': false,
          'message':
              errorData?['message'] ??
              errorData?['msg'] ??
              'An unknown error occurred.',
        };
      }
    } on FormatException {
      return {
        'success': false,
        'message': 'Received an unexpected response from the server.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Prepares HTTP headers, optionally including authorization token.
  Future<Map<String, String>> _getHeaders({
    bool includeAuth = false,
    String? contentType,
  }) async {
    final Map<String, String> headers = {};
    if (contentType != null) {
      headers['Content-Type'] = contentType;
    } else {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    }

    if (includeAuth) {
      final token = await _authService.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // Fetches all listings, with optional search parameters.
  Future<Map<String, dynamic>> fetchAllListings({
    Map<String, String>? searchParams,
  }) async {
    Uri uri = Uri.parse('$kApiUrl/listings');
    if (searchParams != null && searchParams.isNotEmpty) {
      uri = uri.replace(
        queryParameters: searchParams,
      ); // Add search parameters if provided.
    }

    final response = await http.get(uri, headers: await _getHeaders());
    return _handleResponse(response);
  }

  // Fetches a single listing by its ID.
  Future<Map<String, dynamic>> fetchListingById(int id) async {
    final response = await http.get(
      Uri.parse('$kApiUrl/listings/$id'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  // Creates a new listing.
  Future<Map<String, dynamic>> createListing({
    required String title,
    required String description,
    double? price,
    String? category,
    String? location,
    String? validUntil,
    bool isActive = true,
  }) async {
    final response = await http.post(
      Uri.parse('$kApiUrl/listings'),
      headers: await _getHeaders(includeAuth: true), // Requires authentication.
      body: jsonEncode(<String, dynamic>{
        'title': title,
        'description': description,
        if (price != null) 'price': price,
        if (category != null) 'category': category,
        if (location != null) 'location': location,
        if (validUntil != null) 'valid_until': validUntil,
        'is_active': isActive,
      }),
    );
    return _handleResponse(response);
  }

  // Updates an existing listing by its ID.
  Future<Map<String, dynamic>> updateListing(
    int id,
    Map<String, dynamic> updates,
  ) async {
    final response = await http.put(
      Uri.parse('$kApiUrl/listings/$id'),
      headers: await _getHeaders(includeAuth: true), // Requires authentication.
      body: jsonEncode(updates),
    );
    return _handleResponse(response);
  }

  // Deletes a listing by its ID.
  Future<Map<String, dynamic>> deleteListing(int id) async {
    final response = await http.delete(
      Uri.parse('$kApiUrl/listings/$id'),
      headers: await _getHeaders(includeAuth: true), // Requires authentication.
    );
    return _handleResponse(response);
  }

  // Uploads media files (images/videos) for a specific listing.
  Future<Map<String, dynamic>> uploadMediaForListing(
    int listingId,
    List<XFile> files,
  ) async {
    final uri = Uri.parse('$kApiUrl/listings/$listingId/media');
    final request = http.MultipartRequest('POST', uri);

    final authHeaders = await _getHeaders(
      includeAuth: true,
      contentType: null,
    ); // Auth headers for multipart request.
    request.headers.addAll(authHeaders);

    for (XFile file in files) {
      Uint8List fileBytes = await file.readAsBytes();
      String fileName = file.name;

      // Determine the MIME type of the file.
      String? actualMimeType = file.mimeType ?? lookupMimeType(file.path);
      MediaType? mediaType;

      if (actualMimeType != null) {
        final parts = actualMimeType.split('/');
        if (parts.length == 2) {
          mediaType = MediaType(parts[0], parts[1]);
        }
      }

      if (mediaType == null) {
        print(
          'Warning: Could not determine MIME type for ${file.name}. Sending as octet-stream.',
        );
      }

      if (fileBytes.isEmpty) {
        print("No file bytes available for upload: ${file.name}.");
        continue; // Skip empty files.
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'files', // Field name for the files on the server side.
          fileBytes,
          filename: fileName,
          contentType: mediaType,
        ),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Error uploading media: ${e.toString()}',
      };
    }
  }

  // Deletes a specific media item by its ID.
  Future<Map<String, dynamic>> deleteMedia(int mediaId) async {
    final response = await http.delete(
      Uri.parse('$kApiUrl/media/$mediaId'),
      headers: await _getHeaders(includeAuth: true), // Requires authentication.
    );
    return _handleResponse(response);
  }

  // Updates the display order of media items for a listing.
  Future<Map<String, dynamic>> updateMediaOrder(
    String listingId,
    List<int> mediaIds,
  ) async {
    final response = await http.put(
      Uri.parse('$kApiUrl/listings/$listingId/media/order'),
      headers: await _getHeaders(includeAuth: true), // Requires authentication.
      body: jsonEncode({'media_ids': mediaIds}),
    );
    return _handleResponse(response);
  }
}
