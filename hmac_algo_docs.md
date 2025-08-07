# Vezeeta API HMAC Authentication Documentation

This document explains how to generate valid HMAC signatures for authenticating requests to the Vezeeta API, based on reverse engineering of the Android application.

## Overview

The Vezeeta API uses HMAC-SHA256 for request authentication with custom headers:
- `x-vzt-time`: Current timestamp in milliseconds
- `x-vzt-authorization`: HMAC-SHA256 signature
- `x-vzt-token`: User authentication token (optional)

## HMAC Algorithm Details

### Secret Key
```
2fe8ddc8783365d04db348b9859efac2875521bd4f312930315f4d1f6c2c9bf7237492584b50a81137557be28951b5b3c41c8e0a91c3a838b98acf1eb653969d
```

### Algorithm
- **Hash Function**: HMAC-SHA256
- **Encoding**: UTF-8
- **Output Format**: Lowercase hexadecimal string

## Message Construction Rules

The message format depends on the request type:

### For GET Requests (no body)
```
message = url_without_query_params + user_token + timestamp
```

### For POST/PUT Requests (with body)
```
message = full_url + request_body + user_token + timestamp
```

### Important Notes:
1. **URL Processing**: For GET requests, remove query parameters from URL
2. **User Token**: Use empty string `""` when using the default token `99999999-9999-9999-9999-000000000000`
3. **Request Body**: Use empty string `""` for GET requests
4. **Timestamp**: Unix timestamp in milliseconds as string

## Implementation Examples

### Dart Implementation

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class VezeetaHMACAuth {
  static const String SECRET_KEY = "2fe8ddc8783365d04db348b9859efac2875521bd4f312930315f4d1f6c2c9bf7237492584b50a81137557be28951b5b3c41c8e0a91c3a838b98acf1eb653969d";
  static const String DEFAULT_TOKEN = "99999999-9999-9999-9999-000000000000";
  
  /// Generate HMAC signature for GET requests
  static String generateHMACForGet({
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
    
    return _generateHMAC(message);
  }
  
  /// Generate HMAC signature for POST/PUT requests
  static String generateHMACForPost({
    required String url,
    required String requestBody,
    required String userToken,
    required String timestamp,
  }) {
    // Use empty string if using default token
    String token = (userToken == DEFAULT_TOKEN) ? "" : userToken;
    
    // Construct message: full_url + body + token + timestamp
    String message = url + requestBody + token + timestamp;
    
    return _generateHMAC(message);
  }
  
  /// Generate current timestamp
  static String getCurrentTimestamp() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  /// Internal HMAC generation
  static String _generateHMAC(String message) {
    var key = utf8.encode(SECRET_KEY);
    var messageBytes = utf8.encode(message);
    
    var hmac = Hmac(sha256, key);
    var digest = hmac.convert(messageBytes);
    
    return digest.toString(); // Returns lowercase hex string
  }
  
  /// Generate authentication headers
  static Map<String, String> generateAuthHeaders({
    required String url,
    String requestBody = "",
    String userToken = DEFAULT_TOKEN,
    String? customTimestamp,
  }) {
    String timestamp = customTimestamp ?? getCurrentTimestamp();
    String hmacSignature;
    
    if (requestBody.isEmpty) {
      // GET request
      hmacSignature = generateHMACForGet(
        url: url,
        userToken: userToken,
        timestamp: timestamp,
      );
    } else {
      // POST/PUT request
      hmacSignature = generateHMACForPost(
        url: url,
        requestBody: requestBody,
        userToken: userToken,
        timestamp: timestamp,
      );
    }
    
    return {
      'x-vzt-time': timestamp,
      'x-vzt-authorization': hmacSignature,
      'x-vzt-token': (userToken == DEFAULT_TOKEN) ? "" : userToken,
    };
  }
}
```

### Usage Examples

#### GET Request Example
```dart
void main() {
  String url = "https://vezeeta-mobile-gateway.vezeetaservices.com/api/Search?Page=1&BookingTypes=physical";
  String userToken = "99999999-9999-9999-9999-000000000000";
  String timestamp = "1754558400898";
  
  // Generate HMAC for GET request
  String hmac = VezeetaHMACAuth.generateHMACForGet(
    url: url,
    userToken: userToken,
    timestamp: timestamp,
  );
  
  print("HMAC: $hmac");
  // Expected: 5c08a713e07fd0202f4366247d16e357911287da162bd24b2c5a1b46900b5bc0
  
  // Generate complete headers
  Map<String, String> headers = VezeetaHMACAuth.generateAuthHeaders(url: url);
  print("Headers: $headers");
}
```

#### POST Request Example
```dart
void makePostRequest() async {
  String url = "https://vezeeta-mobile-gateway.vezeetaservices.com/api/authenticate";
  String requestBody = '{"username":"test","password":"test123"}';
  String userToken = "your-user-token-here";
  
  Map<String, String> authHeaders = VezeetaHMACAuth.generateAuthHeaders(
    url: url,
    requestBody: requestBody,
    userToken: userToken,
  );
  
  // Add other required headers
  Map<String, String> headers = {
    ...authHeaders,
    'Content-Type': 'application/json',
    'User-Agent': 'okhttp/4.11.0',
    'Accept-Encoding': 'gzip',
    'authorization': userToken,
    'countryid': '1',
    'language_cache': '2',
    'language': 'ar-EG',
    'cache-control': 'max-age=7200',
    'country_cache': '1',
    'languageid': '2',
    'accept-language': 'ar-EG',
    'regionid': 'Africa/Cairo',
    'brandkey': '7B2BAB71-008D-4469-A966-579503B3C719',
    'x-vzt-component': 'PTKEY',
  };
  
  // Make HTTP request with these headers
  // ... your HTTP client code here
}
```

## Step-by-Step Verification

### Example from curl request:
- **URL**: `https://vezeeta-mobile-gateway.vezeetaservices.com/api/Search?Page=1&BookingTypes=physical`
- **Timestamp**: `1754558400898`
- **User Token**: `99999999-9999-9999-9999-000000000000` (default, so use empty string)

### Step 1: Prepare URL (GET request)
```
URL without query: https://vezeeta-mobile-gateway.vezeetaservices.com/api/Search
```

### Step 2: Construct Message
```
Message = "https://vezeeta-mobile-gateway.vezeetaservices.com/api/Search" + "" + "1754558400898"
Message = "https://vezeeta-mobile-gateway.vezeetaservices.com/api/Search1754558400898"
```

### Step 3: Generate HMAC
```
HMAC-SHA256(secret_key, message) = "5c08a713e07fd0202f4366247d16e357911287da162bd4b2c5a1b46900b5bc0"
```

### Step 4: Verify
This matches the `x-vzt-authorization` header in the original curl request! ✅

## Required Dependencies

### For Dart
Add to your `pubspec.yaml`:
```yaml
dependencies:
  crypto: ^3.0.3
```

## Additional Headers

The Vezeeta API also expects these standard headers:

```dart
Map<String, String> standardHeaders = {
  'User-Agent': 'okhttp/4.11.0',
  'Accept-Encoding': 'gzip',
  'authorization': userToken,
  'countryid': '1',
  'language_cache': '2',
  'language': 'ar-EG',
  'cache-control': 'max-age=7200',
  'country_cache': '1',
  'languageid': '2',
  'accept-language': 'ar-EG',
  'regionid': 'Africa/Cairo',
  'brandkey': '7B2BAB71-008D-4469-A966-579503B3C719',
  'content-type': 'application/json',
  'x-vzt-component': 'PTKEY',
};
```

## Security Considerations

⚠️ **Important Security Notes:**

1. **Hardcoded Secret**: The secret key is hardcoded in the application, which is a security vulnerability
2. **Client-Side Validation**: This HMAC is generated client-side, so it's not providing server-side security
3. **Reverse Engineering**: This information was obtained through reverse engineering and should be used responsibly
4. **Terms of Service**: Ensure compliance with Vezeeta's terms of service before using this information

## Troubleshooting

### Common Issues:

1. **Wrong HMAC**: 
   - Check URL processing (remove query params for GET)
   - Verify timestamp format (milliseconds as string)
   - Ensure proper user token handling (empty string for default)

2. **Encoding Issues**:
   - Use UTF-8 encoding for all strings
   - Ensure lowercase hex output

3. **Request Type**:
   - Use appropriate method (GET vs POST) for message construction
   - Include request body only for POST/PUT requests

### Debug Helper:
```dart
void debugHMAC() {
  String url = "https://vezeeta-mobile-gateway.vezeetaservices.com/api/Search?Page=1&BookingTypes=physical";
  String timestamp = "1754558400898";
  
  String urlWithoutQuery = url.split('?')[0];
  String message = urlWithoutQuery + "" + timestamp;
  
  print("URL without query: $urlWithoutQuery");
  print("Message: $message");
  print("Message length: ${message.length}");
  print("Message bytes: ${utf8.encode(message)}");
  
  String hmac = VezeetaHMACAuth.generateHMACForGet(
    url: url,
    userToken: "99999999-9999-9999-9999-000000000000",
    timestamp: timestamp,
  );
  
  print("Generated HMAC: $hmac");
  print("Expected HMAC:   5c08a713e07fd0202f4366247d16e357911287da162bd24b2c5a1b46900b5bc0");
  print("Match: ${hmac == '5c08a713e07fd0202f4366247d16e357911287da162bd24b2c5a1b46900b5bc0'}");
}
```

---

**Disclaimer**: This documentation is based on reverse engineering of the Vezeeta Android application. Use this information responsibly and ensure compliance with applicable terms of service and laws.
