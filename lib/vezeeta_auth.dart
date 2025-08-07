import 'dart:convert';
import 'package:crypto/crypto.dart';

/// A class to generate HMAC authentication headers for Vezeeta API requests.
///
/// Usage:
/// ```dart
/// // For GET requests
/// Map<String, String> headers = {
///   ...VezeetaAuth.generateAuthHeaders(url: 'https://api.vezeeta.com/search'),
///   'Content-Type': 'application/json',
/// };
///
/// // For POST requests
/// Map<String, String> headers = {
///   ...VezeetaAuth.generateAuthHeaders(
///     url: 'https://api.vezeeta.com/authenticate',
///     requestBody: '{"username":"test","password":"test123"}',
///     userToken: 'your-token-here',
///   ),
///   'Content-Type': 'application/json',
/// };
/// ```
class VezeetaAuth {
  /// The secret key used for HMAC generation
  static const String _secretKey =
      "2fe8ddc8783365d04db348b9859efac2875521bd4f312930315f4d1f6c2c9bf7237492584b50a81137557be28951b5b3c41c8e0a91c3a838b98acf1eb653969d";

  /// Default token used when no user token is provided
  static const String _defaultToken = "99999999-9999-9999-9999-000000000000";

  /// Generates authentication headers that can be spread into request headers.
  ///
  /// [url] - The full request URL
  /// [requestBody] - The request body (empty string for GET requests)
  /// [userToken] - The user authentication token (defaults to default token)
  /// [customTimestamp] - Custom timestamp (defaults to current time)
  ///
  /// Returns a Map<String, String> containing the auth headers:
  /// - x-vzt-time: Current timestamp in milliseconds
  /// - x-vzt-authorization: HMAC-SHA256 signature
  /// - x-vzt-token: User authentication token
  static Map<String, String> generateAuthHeaders({
    required String url,
    String requestBody = "",
    String userToken = _defaultToken,
    String? customTimestamp,
  }) {
    final timestamp = customTimestamp ?? _getCurrentTimestamp();
    final hmacSignature = requestBody.isEmpty
        ? _generateHMACForGet(
            url: url,
            userToken: userToken,
            timestamp: timestamp,
          )
        : _generateHMACForPost(
            url: url,
            requestBody: requestBody,
            userToken: userToken,
            timestamp: timestamp,
          );

    return {
      'x-vzt-time': timestamp,
      'x-vzt-authorization': hmacSignature,
      'x-vzt-token': (userToken == _defaultToken) ? "" : userToken,
    };
  }

  /// Generates HMAC signature for GET requests
  static String _generateHMACForGet({
    required String url,
    required String userToken,
    required String timestamp,
  }) {
    // Remove query parameters for GET requests
    final urlWithoutQuery = url.split('?')[0];

    // Use empty string if using default token
    final token = (userToken == _defaultToken) ? "" : userToken;

    // Construct message: url + token + timestamp
    final message = urlWithoutQuery + token + timestamp;

    return _generateHMAC(message);
  }

  /// Generates HMAC signature for POST/PUT requests
  static String _generateHMACForPost({
    required String url,
    required String requestBody,
    required String userToken,
    required String timestamp,
  }) {
    // Use empty string if using default token
    final token = (userToken == _defaultToken) ? "" : userToken;

    // Construct message: full_url + body + token + timestamp
    final message = url + requestBody + token + timestamp;

    return _generateHMAC(message);
  }

  /// Generates current timestamp in milliseconds
  static String _getCurrentTimestamp() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Internal HMAC generation using SHA256
  static String _generateHMAC(String message) {
    final key = utf8.encode(_secretKey);
    final messageBytes = utf8.encode(message);

    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(messageBytes);

    return digest.toString(); // Returns lowercase hex string
  }
}
