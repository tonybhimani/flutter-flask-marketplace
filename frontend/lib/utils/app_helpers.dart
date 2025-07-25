import 'package:marketplace_app/utils/constants.dart';

// Constructs a full URL for media by combining the base API URL with a relative path.
String getFullMediaUrl(String relativeUrl) {
  try {
    // Parse the base API URL from constants.
    final baseUri = Uri.parse(kApiUrl);

    // Reconstruct a "cleaned" base URL containing only the scheme, host, and port.
    // This is done to prevent double-slashing issues if kApiUrl already includes a path.
    final cleanedBaseUrl = baseUri.scheme.isNotEmpty && baseUri.host.isNotEmpty
        ? '${baseUri.scheme}://${baseUri.host}${baseUri.port != null ? ':${baseUri.port}' : ''}'
        : '';
    // Combine the cleaned base URL with the provided relative media URL.
    return '$cleanedBaseUrl$relativeUrl';
  } catch (e) {
    // Print an error if kApiUrl cannot be parsed and return the relative URL as a fallback.
    print('Error parsing kApiUrl for media URL: $e');
    return relativeUrl;
  }
}
