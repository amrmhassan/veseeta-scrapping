import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Vezeeta API Client with dynamic HMAC authentication
class VezeetaApiClient {
  static const String SECRET_KEY =
      "2fe8ddc8783365d04db348b9859efac2875521bd4f312930315f4d1f6c2c9bf7237492584b50a81137557be28951b5b3c41c8e0a91c3a838b98acf1eb653969d";
  static const String DEFAULT_TOKEN = "99999999-9999-9999-9999-000000000000";
  static const String BASE_URL =
      "https://vezeeta-mobile-gateway.vezeetaservices.com";
  static const String BRAND_KEY = "7B2BAB71-008D-4469-A966-579503B3C719";

  final http.Client _httpClient;
  String _userToken;
  String _countryId;
  String _languageId;
  String _language;
  String _countryCode;
  String _regionId;

  VezeetaApiClient({
    http.Client? httpClient,
    String userToken = DEFAULT_TOKEN,
    String countryId = "1",
    String languageId = "2", // 1 for English, 2 for Arabic
    String language = "ar-EG",
    String countryCode = "EG",
    String regionId = "Africa/Cairo",
  }) : _httpClient = httpClient ?? http.Client(),
       _userToken = userToken,
       _countryId = countryId,
       _languageId = languageId,
       _language = language,
       _countryCode = countryCode,
       _regionId = regionId;

  /// Generate current timestamp in milliseconds
  String _getCurrentTimestamp() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Generate HMAC-SHA256 signature
  String _generateHMAC(String message) {
    var key = utf8.encode(SECRET_KEY);
    var messageBytes = utf8.encode(message);

    var hmac = Hmac(sha256, key);
    var digest = hmac.convert(messageBytes);

    return digest.toString().toLowerCase();
  }

  /// Generate HMAC signature for GET requests
  String _generateHMACForGet({
    required String url,
    required String userToken,
    required String timestamp,
  }) {
    // Remove query parameters for GET requests
    String urlWithoutQuery = url.split('?')[0];

    // Use empty string if using default token
    String token = (userToken == DEFAULT_TOKEN) ? "" : userToken;

    // Construct message: url + token + timestamp
    String message = urlWithoutQuery + token + timestamp;

    print("🔐 HMAC Generation for GET:");
    print("   URL (no query): $urlWithoutQuery");
    print("   Token: '$token'");
    print("   Timestamp: $timestamp");
    print("   Message: $message");

    String hmac = _generateHMAC(message);
    print("   Generated HMAC: $hmac");

    return hmac;
  }

  /// Generate HMAC signature for POST/PUT requests
  String _generateHMACForPost({
    required String url,
    required String requestBody,
    required String userToken,
    required String timestamp,
  }) {
    // Use empty string if using default token
    String token = (userToken == DEFAULT_TOKEN) ? "" : userToken;

    // Construct message: full_url + body + token + timestamp
    String message = url + requestBody + token + timestamp;

    print("🔐 HMAC Generation for POST:");
    print("   URL: $url");
    print("   Body: $requestBody");
    print("   Token: '$token'");
    print("   Timestamp: $timestamp");
    print("   Message: $message");

    String hmac = _generateHMAC(message);
    print("   Generated HMAC: $hmac");

    return hmac;
  }

  /// Generate authentication headers
  Map<String, String> _generateAuthHeaders({
    required String url,
    String requestBody = "",
    String? customTimestamp,
  }) {
    String timestamp = customTimestamp ?? _getCurrentTimestamp();
    String hmacSignature;

    if (requestBody.isEmpty) {
      // GET request
      hmacSignature = _generateHMACForGet(
        url: url,
        userToken: _userToken,
        timestamp: timestamp,
      );
    } else {
      // POST/PUT request
      hmacSignature = _generateHMACForPost(
        url: url,
        requestBody: requestBody,
        userToken: _userToken,
        timestamp: timestamp,
      );
    }

    String tokenHeader = (_userToken == DEFAULT_TOKEN) ? "" : _userToken;

    return {
      'x-vzt-time': timestamp,
      'x-vzt-authorization': hmacSignature,
      'x-vzt-token': tokenHeader,
    };
  }

  /// Generate standard Vezeeta API headers
  Map<String, String> _generateStandardHeaders({
    required String url,
    String requestBody = "",
    String? customTimestamp,
  }) {
    Map<String, String> authHeaders = _generateAuthHeaders(
      url: url,
      requestBody: requestBody,
      customTimestamp: customTimestamp,
    );

    return {
      ...authHeaders,
      'User-Agent': 'okhttp/4.11.0',
      'Accept-Encoding': 'gzip',
      'authorization': _userToken,
      'countryid': _countryId,
      'language_cache': _languageId,
      'language': _language,
      'cache-control': 'max-age=7200',
      'country_cache': _countryId,
      'languageid': _languageId,
      'accept-language': _language,
      'regionid': _regionId,
      'brandkey': BRAND_KEY,
      'content-type': 'application/json',
      'x-vzt-component': 'PTKEY',
    };
  }

  /// Search for doctors/clinics
  Future<Map<String, dynamic>> searchDoctors({
    int page = 1,
    String bookingTypes = "physical",
    String? customTimestamp,
  }) async {
    try {
      String url = "$BASE_URL/api/Search?Page=$page&BookingTypes=$bookingTypes";

      print("🚀 Making Search API Request:");
      print("   URL: $url");

      Map<String, String> headers = _generateStandardHeaders(
        url: url,
        customTimestamp: customTimestamp,
      );

      print("📋 Request Headers:");
      headers.forEach((key, value) {
        print("   $key: $value");
      });

      final response = await _httpClient.get(Uri.parse(url), headers: headers);

      print("📨 Response:");
      print("   Status Code: ${response.statusCode}");
      print("   Status Text: ${response.reasonPhrase}");
      print("   Content Length: ${response.contentLength ?? 'unknown'}");

      if (response.headers.isNotEmpty) {
        print("📋 Response Headers:");
        response.headers.forEach((key, value) {
          print("   $key: $value");
        });
      }

      if (response.body.isNotEmpty) {
        print("📄 Response Body (first 500 chars):");
        String body = response.body;
        print(
          "   ${body.length > 500 ? body.substring(0, 500) + '...' : body}",
        );
      }

      Map<String, dynamic> result = {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'statusText': response.reasonPhrase,
        'headers': response.headers,
        'body': response.body,
      };

      if (response.statusCode == 200) {
        try {
          result['data'] = json.decode(response.body);
        } catch (e) {
          print("⚠️  Failed to parse JSON response: $e");
          result['parseError'] = e.toString();
        }
      }

      return result;
    } catch (e, stackTrace) {
      print("❌ Error making request: $e");
      print("📚 Stack trace: $stackTrace");

      return {
        'success': false,
        'error': e.toString(),
        'stackTrace': stackTrace.toString(),
      };
    }
  }

  /// Clean up resources
  void dispose() {
    _httpClient.close();
  }
}
