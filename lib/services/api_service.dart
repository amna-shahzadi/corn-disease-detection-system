import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Added import for MediaType
import 'package:corn_disease_app/config/api_config.dart';

/// Individual disease detection with bounding box
class DiseaseDetection {
  final String? disease;
  final double? confidence;
  final List<double>? bbox;
  final List<int>? color;

  DiseaseDetection({
    this.disease,
    this.confidence,
    this.bbox,
    this.color,
  });

  factory DiseaseDetection.fromJson(Map<String, dynamic> json) {
    return DiseaseDetection(
      disease: json['disease'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      bbox: (json['bbox'] as List?)?.map((e) => (e as num).toDouble()).toList(),
      color: (json['color'] as List?)?.map((e) => e as int).toList(),
    );
  }
}

/// Response from disease detection API
class DetectDiseaseResponse {
  final String? diseaseName;
  final String? confidence;
  final bool isHealthy;
  final String? message;
  final Map<String, dynamic>? raw;
  final List<DiseaseDetection>? detections;
  final int? totalDetections;
  final String? filename;

  DetectDiseaseResponse({
    this.diseaseName,
    this.confidence,
    this.isHealthy = false,
    this.message,
    this.raw,
    this.detections,
    this.totalDetections,
    this.filename,
  });

  factory DetectDiseaseResponse.fromJson(Map<String, dynamic> json) {
    // Handle the new API response format
    if (json.containsKey('success') && json['success'] == true && json.containsKey('data')) {
      final data = json['data'] as Map<String, dynamic>? ?? {};
      
      // Parse diseases from the new format
      final diseasesData = data['diseases'] as Map<String, dynamic>? ?? {};
      final List<DiseaseDetection> allDetections = [];
      
      diseasesData.forEach((diseaseKey, diseaseInfo) {
        if (diseaseInfo is Map<String, dynamic>) {
          final detections = diseaseInfo['detections'] as List? ?? [];
          for (final detection in detections) {
            if (detection is Map<String, dynamic>) {
              allDetections.add(DiseaseDetection.fromJson(detection));
            }
          }
        }
      });
      
      // Get the highest confidence detection as the primary result
      DiseaseDetection? primaryDetection;
      if (allDetections.isNotEmpty) {
        allDetections.sort((a, b) => (b.confidence ?? 0).compareTo(a.confidence ?? 0));
        primaryDetection = allDetections.first;
      }
      
      return DetectDiseaseResponse(
        diseaseName: primaryDetection?.disease,
        confidence: primaryDetection?.confidence != null 
            ? '${((primaryDetection!.confidence ?? 0) * 100).toStringAsFixed(1)}%' 
            : null,
        isHealthy: allDetections.isEmpty,
        message: json['message'] as String?,
        raw: json,
        detections: allDetections,
        totalDetections: data['total_detections'] as int?,
        filename: data['filename'] as String?,
      );
    }
    
    // Fallback to legacy format
    return DetectDiseaseResponse(
      diseaseName: json['diseaseName'] as String? ?? 
                   json['disease'] as String? ?? 
                   json['label'] as String? ?? 
                   json['prediction'] as String?,
      confidence: json['confidence']?.toString() ?? 
                  json['confidenceLevel']?.toString() ??
                  json['accuracy']?.toString(),
      isHealthy: json['isHealthy'] == true || 
                 (json['diseaseName']?.toString().toLowerCase().contains('healthy') ?? false) ||
                 (json['disease']?.toString().toLowerCase().contains('healthy') ?? false),
      message: json['message'] as String?,
      raw: json,
    );
  }
}

/// Response from registration API (201).
/// Backend should return at least username, email, and preferably user_id (or id).
class RegisterResponse {
  final String? userId;
  final String? username;
  final String? email;
  final String? phoneNumber;

  RegisterResponse({
    this.userId,
    this.username,
    this.email,
    this.phoneNumber,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      userId: json['user_id']?.toString() ?? json['id']?.toString(),
      username: json['username'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String?,
    );
  }
}

/// Response from login API: message, user_id, username, email.
class LoginResponse {
  final String? message;
  final String? userId;
  final String? username;
  final String? email;

  LoginResponse({
    this.message,
    this.userId,
    this.username,
    this.email,
  });
}

/// Request/response for user update (PUT /users/edit/{user_id}/).
class UserUpdateResponse {
  final String? username;
  final String? location;
  final String? profilePicture;

  UserUpdateResponse({
    this.username,
    this.location,
    this.profilePicture,
  });

  factory UserUpdateResponse.fromJson(Map<String, dynamic> json) {
    return UserUpdateResponse(
      username: json['username']?.toString(),
      location: json['location']?.toString(),
      profilePicture: json['profile_picture']?.toString(),
    );
  }
}

/// Full user profile from GET /users/{user_id}/.
class UserProfile {
  final String? userId;
  final String? username;
  final String? email;
  final String? phoneNumber;
  final String? location;
  final String? profilePicture;

  UserProfile({
    this.userId,
    this.username,
    this.email,
    this.phoneNumber,
    this.location,
    this.profilePicture,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id']?.toString(),
      username: json['username']?.toString(),
      email: json['email']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      location: json['location']?.toString(),
      profilePicture: json['profile_picture']?.toString(),
    );
  }
}

/// Response from GET /users/lists/ (paginated users list).
class UsersListResponse {
  final bool success;
  final int count;
  final List<UserProfile> data;

  UsersListResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory UsersListResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'];
    List<UserProfile> users = [];
    if (dataList is List) {
      for (final e in dataList) {
        if (e is Map<String, dynamic>) {
          users.add(UserProfile.fromJson(e));
        } else if (e is Map) {
          users.add(UserProfile.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return UsersListResponse(
      success: json['success'] == true,
      count: (json['count'] is int) ? json['count'] as int : users.length,
      data: users,
    );
  }
}

/// Response for a single history item from API
class HistoryItemResponse {
  final String id;
  final String? title;
  final String? diseaseName;
  final String? date;
  final String? time;
  final bool isHealthy;
  final Map<String, dynamic>? raw;

  HistoryItemResponse({
    required this.id,
    this.title,
    this.diseaseName,
    this.date,
    this.time,
    this.isHealthy = false,
    this.raw,
  });

  factory HistoryItemResponse.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? json['historyId']?.toString() ?? '';
    final diseaseName = json['diseaseName'] as String? ??
        json['disease'] as String? ??
        json['label'] as String? ??
        json['disease_name'] as String?;
    final rawStatus = (json['status'] ?? '').toString().toLowerCase();
    final isHealthy = json['isHealthy'] == true ||
        rawStatus.contains('healthy') ||
        (diseaseName?.toLowerCase().contains('healthy') ?? false);
    return HistoryItemResponse(
      id: id,
      title: json['title'] as String? ?? (isHealthy ? 'Healthy Leaf' : 'Disease Detected'),
      diseaseName: diseaseName,
      date: json['date'] as String? ??
          json['created_at']?.toString().split('T').first ??
          json['createdAt']?.toString().split('T').first,
      time: json['time'] as String? ??
          (json['created_at']?.toString().split('T').length == 2
              ? json['created_at']!.toString().split('T').last.split('.').first
              : json['createdAt']?.toString().split('T').last.split('.').first),
      isHealthy: isHealthy,
      raw: json,
    );
  }
}

/// Service for all backend API calls (FYP-2022 Railway).
/// Endpoints should match your Swagger at https://fyp-2022.up.railway.app/swagger
class ApiService {
  static final _client = http.Client();
  static final _timeout = Duration(seconds: ApiConfig.requestTimeoutSeconds);

  static String get _base => ApiConfig.baseUrl;

  /// Detect disease from image bytes (works on mobile and web).
  /// Endpoint: POST /predict with multipart form field "image".
  static Future<DetectDiseaseResponse> detectDiseaseFromBytes(
    Uint8List imageBytes,
    String filename,
  ) async {
    final uri = Uri.parse('$_base${ApiConfig.detectPath}');
    final request = http.MultipartRequest('POST', uri);
    
    // Detect content type based on filename
    String contentType = 'image/jpeg';
    if (filename.toLowerCase().endsWith('.png')) {
      contentType = 'image/png';
    } else if (filename.toLowerCase().endsWith('.webp')) {
      contentType = 'image/webp';
    }
    
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: filename,
      contentType: MediaType.parse(contentType),
    ));

    final streamed = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        if (json != null) return DetectDiseaseResponse.fromJson(json);
      } catch (_) {}
      return DetectDiseaseResponse(
        message: response.body.isNotEmpty ? response.body : 'Detection successful',
        raw: {'body': response.body},
      );
    }

    String message = 'Detection failed (${response.statusCode})';
    if (response.statusCode == 404) {
      message = 'Prediction endpoint not found (404). '
          'Endpoint is now correctly set to /predict.';
    } else {
      try {
        final json = jsonDecode(response.body);
        if (json is Map && json['message'] != null) message = json['message'].toString();
        if (json is Map && json['detail'] != null) message = json['detail'].toString();
      } catch (_) {
        final body = response.body.toLowerCase();
        if (body.contains('user') && body.contains('not defined')) {
          message = 'Detection endpoint error. Backend path or auth may be wrong (check api_config.dart and Swagger).';
        }
      }
    }
    throw ApiException(message, response.statusCode);
  }

  /// Register user in backend database. POST /registeration/.
  /// Sends multipart/form-data to match Swagger: username, email, password, confirm_password, phone_number (optional).
  static Future<RegisterResponse> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
    String? phoneNumber,
  }) async {
    final uri = Uri.parse('$_base${ApiConfig.registrationPath}');
    final request = http.MultipartRequest('POST', uri);
    request.fields['username'] = username;
    request.fields['email'] = email;
    request.fields['password'] = password;
    request.fields['confirm_password'] = confirmPassword;
    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      request.fields['phone_number'] = phoneNumber.trim();
    }

    final streamed = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 201) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        if (json != null) return RegisterResponse.fromJson(json);
      } catch (_) {}
      return RegisterResponse(username: username, email: email, phoneNumber: phoneNumber);
    }

    // Build a clear error message from 400 response body (e.g. validation errors)
    String message = 'Registration failed (${response.statusCode})';
    if (response.body.isNotEmpty) {
      try {
        final json = jsonDecode(response.body);
        if (json is Map) {
          final parts = <String>[];
          for (final entry in json.entries) {
            final key = entry.key.toString();
            final value = entry.value;
            if (value is List && value.isNotEmpty) {
              parts.add('$key: ${value.join(', ')}');
            } else if (value is String) {
              parts.add('$key: $value');
            }
          }
          if (parts.isNotEmpty) message = parts.join(' • ');
        }
      } catch (_) {}
    }
    throw ApiException(message, response.statusCode);
  }

  /// Login response from backend: message, user_id, username, email.
  static LoginResponse? _parseLoginResponse(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>?;
      if (json == null) return null;
      return LoginResponse(
        message: json['message']?.toString(),
        userId: json['user_id']?.toString(),
        username: json['username']?.toString(),
        email: json['email']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Login user via backend. POST /login/ with JSON body including email, password,
  /// returnSecureToken, and clientType. Returns [LoginResponse] on 200/201; throws [ApiException] otherwise.
  static Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_base${ApiConfig.loginPath}');
    final body = jsonEncode({
      'returnSecureToken': true,
      'email': email.trim(),
      'password': password,
      'clientType': 'CLIENT_TYPE_WEB',
    });
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(_timeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final loginData = _parseLoginResponse(response.body);
      return loginData ?? LoginResponse(email: email.trim());
    }

    String message = 'Login failed (${response.statusCode})';
    if (response.statusCode == 401 || response.statusCode == 403) {
      message = 'Invalid email or password.';
    } else if (response.body.isNotEmpty) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        if (json != null) {
          final err = json['error'];
          if (err is Map) {
            final errMsg = err['message']?.toString() ?? '';
            if (errMsg == 'INVALID_LOGIN_CREDENTIALS') {
              message = 'Invalid email or password.';
            } else if (errMsg.isNotEmpty) {
              message = errMsg;
            }
          }
          if (message == 'Login failed (${response.statusCode})') {
            if (json['message'] != null) message = json['message'].toString();
            if (json['detail'] != null) message = json['detail'].toString();
          }
        }
      } catch (_) {}
    }
    throw ApiException(message, response.statusCode);
  }

  /// Login with Google via your backend.
  /// POST to [ApiConfig.googleLoginPath] with body matching backend `GoogleSignIn` model:
  /// {
  ///   "id_token": "<google_id_token>",
  ///   "credential": "<google_credential_or_id_token>",
  ///   "access_token": "<google_access_token>" // optional
  /// }
  static Future<LoginResponse> loginWithGoogle({
    required String idToken,
    String? credential,
    String? accessToken,
  }) async {
    final uri = Uri.parse('$_base${ApiConfig.googleLoginPath}');
    final bodyMap = <String, dynamic>{
      'id_token': idToken,
      // Fallback to idToken if separate credential is not provided.
      'credential': credential ?? idToken,
    };
    if (accessToken != null && accessToken.isNotEmpty) {
      bodyMap['access_token'] = accessToken;
    }
    final body = jsonEncode(bodyMap);
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(_timeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final loginData = _parseLoginResponse(response.body);
      if (loginData != null) return loginData;
    }

    String message = 'Google login failed (${response.statusCode})';
    if (response.body.isNotEmpty) {
      try {
        final json = jsonDecode(response.body);
        if (json is Map && json['message'] != null) message = json['message'].toString();
        if (json is Map && json['detail'] != null) message = json['detail'].toString();
      } catch (_) {}
    }
    throw ApiException(message, response.statusCode);
  }

  /// Step 1: Request password reset code via email.
  /// POST /auth/forgot-password/ with JSON body:
  /// {
  ///   "email": "<user_email>"
  /// }
  /// Backend should send a 6-digit code to the email address.
  static Future<void> forgotPassword({
    required String email,
  }) async {
    final uri = Uri.parse('$_base${ApiConfig.authForgotPasswordPath}');

    final body = jsonEncode({
      'email': email.trim(),
    });

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(_timeout);

    // Helpful for debugging forgot-password issues.
    // ignore: avoid_print
    print('forgotPassword => ${response.statusCode}: ${response.body}');

    // Swagger usually returns 201, but accept 200 as well.
    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    String message = 'Failed to send reset code (${response.statusCode})';
    if (response.body.isNotEmpty) {
      try {
        final json = jsonDecode(response.body);
        if (json is Map && json['message'] != null) message = json['message'].toString();
        if (json is Map && json['detail'] != null) message = json['detail'].toString();
      } catch (_) {}
    }
    throw ApiException(message, response.statusCode);
  }

  /// Step 2: Confirm reset with code and set new password.
  /// POST /auth/reset-password/ with JSON body:
  /// {
  ///   "email": "<user_email>",
  ///   "code": "<code>",
  ///   "new_password": "<new_password>",
  ///   "confirm_password": "<confirm_password>"
  /// }
  /// Expects 201 on success.
  static Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final uri = Uri.parse('$_base${ApiConfig.authResetPasswordPath}');

    final body = jsonEncode({
      'email': email.trim(),
      'code': code.trim(),
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    });

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(_timeout);

    // Helpful for debugging reset-password issues.
    // ignore: avoid_print
    print('resetPassword => ${response.statusCode}: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    String message = 'Password reset failed (${response.statusCode})';
    if (response.body.isNotEmpty) {
      try {
        final json = jsonDecode(response.body);
        if (json is Map && json['message'] != null) message = json['message'].toString();
        if (json is Map && json['detail'] != null) message = json['detail'].toString();
      } catch (_) {}
    }
    throw ApiException(message, response.statusCode);
  }

  /// Update user profile. PUT /users/edit/{user_id}/ with multipart/form-data:
  /// username, phone_number? (fields), location? (fields), profile_picture? (file).
  /// If [removeProfilePicture] is true and no file is sent, a field
  /// `remove_profile_picture=true` is included so backend can clear it.
  /// Returns [UserUpdateResponse] on 200; throws [ApiException] otherwise.
  static Future<UserUpdateResponse> updateUser({
    required String userId,
    required String username,
    String? phoneNumber,
    String? location,
    List<int>? profilePictureBytes,
    bool removeProfilePicture = false,
  }) async {
    final path = '${ApiConfig.userEditPath}/$userId/';
    final uri = Uri.parse('$_base$path');
    final request = http.MultipartRequest('PUT', uri);
    request.fields['username'] = username.trim();
    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      request.fields['phone_number'] = phoneNumber.trim();
    }
    if (location != null && location.trim().isNotEmpty) {
      request.fields['location'] = location.trim();
    }
    if (profilePictureBytes != null && profilePictureBytes.isNotEmpty) {
      request.files.add(http.MultipartFile.fromBytes(
        'profile_picture',
        profilePictureBytes,
        filename: 'profile.jpg',
      ));
    } else if (removeProfilePicture) {
      // Hint for backend to remove existing profile picture if supported.
      request.fields['remove_profile_picture'] = 'true';
    }

    final streamed = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        if (json != null) return UserUpdateResponse.fromJson(json);
      } catch (_) {}
      return UserUpdateResponse(username: username, location: location);
    }

    String message = 'Update failed (${response.statusCode})';
    if (response.body.isNotEmpty) {
      try {
        final json = jsonDecode(response.body);
        if (json is Map && json['message'] != null) message = json['message'].toString();
        if (json is Map && json['detail'] != null) message = json['detail'].toString();
      } catch (_) {}
    }
    throw ApiException(message, response.statusCode);
  }

  /// Update user profile via JSON endpoint.
  /// PUT /users/edit/{user_id}/ with application/json body:
  /// {
  ///   "username": "...",
  ///   "location": "...",
  ///   "profile_picture_url": "<url>",
  ///   "remove_profile_picture": false
  /// }
  /// When [removeProfilePicture] is true, this sends `"remove_profile_picture": true`
  /// so that the backend can clear any existing profile picture.
  static Future<UserUpdateResponse> updateUserOwn({
    required String userId,
    required String username,
    String? location,
    String? profilePictureUrl,
    bool removeProfilePicture = false,
  }) async {
    // Backend Swagger: PUT /users/edit/{user_id}/ with UserUpdate model
    final path = '${ApiConfig.userEditPath}/$userId/';
    final uri = Uri.parse('$_base$path');

    final bodyMap = <String, dynamic>{
      'username': username.trim(),
      'remove_profile_picture': removeProfilePicture,
    };

    if (location != null && location.trim().isNotEmpty) {
      bodyMap['location'] = location.trim();
    }

    // Only send profile_picture_url when not removing (Swagger: x-nullable: true).
    if (!removeProfilePicture && profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
      bodyMap['profile_picture_url'] = profilePictureUrl;
    }

    final response = await _client
        .put(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(bodyMap),
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        if (json != null) return UserUpdateResponse.fromJson(json);
      } catch (_) {}
      return UserUpdateResponse(username: username, location: location);
    }

    String message = 'Update failed (${response.statusCode})';
    if (response.body.isNotEmpty) {
      try {
        final json = jsonDecode(response.body);
        if (json is Map && json['message'] != null) message = json['message'].toString();
        if (json is Map && json['detail'] != null) message = json['detail'].toString();
      } catch (_) {}
    }
    throw ApiException(message, response.statusCode);
  }

  /// Get user profile image as bytes to bypass CORS issues
  static Future<Uint8List?> getProfileImageBytes(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      final imageUrl = profile.profilePicture;
      
      if (imageUrl == null || imageUrl.isEmpty) {
        return null;
      }
      
      final uri = Uri.parse(imageUrl);
      final response = await _client.get(uri).timeout(_timeout);
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      // If image fetch fails, return null and use fallback
    }
    return null;
  }

  /// Get user profile. GET /users/profile/{user_id}/. Returns [UserProfile] on 200.
  static Future<UserProfile> getUserProfile(String userId) async {
    final path = '${ApiConfig.userProfilePath}/$userId/';
    final uri = Uri.parse('$_base$path');
    final response = await _client.get(uri).timeout(_timeout);

    if (response.statusCode == 200) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        if (json != null) {
          return UserProfile.fromJson(json);
        }
      } catch (_) {}
    }

    String message = 'Failed to load profile (${response.statusCode})';
    if (response.body.isNotEmpty) {
      try {
        final json = jsonDecode(response.body);
        if (json is Map && json['message'] != null) message = json['message'].toString();
        if (json is Map && json['detail'] != null) message = json['detail'].toString();
      } catch (_) {}
    }
    throw ApiException(message, response.statusCode);
  }

  /// Get paginated users list. GET /users/lists/?page=...
  /// Returns [UsersListResponse] with success, count, and data (list of [UserProfile]).
  static Future<UsersListResponse> getUsersList({int? page}) async {
    var path = '${ApiConfig.usersListPath}/';
    if (page != null) {
      path += '?page=$page';
    }
    final uri = Uri.parse('$_base$path');
    final response = await _client.get(uri).timeout(_timeout);

    if (response.statusCode == 200) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        if (json != null) return UsersListResponse.fromJson(json);
      } catch (_) {}
    }

    String message = 'Failed to load users (${response.statusCode})';
    if (response.body.isNotEmpty) {
      try {
        final json = jsonDecode(response.body);
        if (json is Map && json['message'] != null) message = json['message'].toString();
        if (json is Map && json['detail'] != null) message = json['detail'].toString();
      } catch (_) {}
    }
    throw ApiException(message, response.statusCode);
  }

  /// Fetch detection history for a specific user.
  /// Uses GET /users/history/{user_id}/?page=...
  static Future<List<HistoryItemResponse>> getHistory({
    required String userId,
    int? page,
  }) async {
    if (userId.isEmpty) {
      throw ApiException('User id is required for history', 0);
    }
    var path = '${ApiConfig.historyPath}/$userId/';
    if (page != null) {
      path += '?page=$page';
    }
    final uri = Uri.parse('$_base$path');
    final response = await _client.get(uri).timeout(_timeout);

    if (response.statusCode != 200) {
      throw ApiException(
        'Failed to load history (${response.statusCode})',
        response.statusCode,
      );
    }

    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['data'] is List) {
        final list = data['data'] as List;
        return list
            .map((e) => HistoryItemResponse.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      // Fallbacks for older formats if backend changes again:
      if (data is Map && data['results'] is List) {
        final list = data['results'] as List;
        return list
            .map((e) => HistoryItemResponse.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      if (data is List) {
        return data
            .map((e) => HistoryItemResponse.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      if (data is Map && data['items'] is List) {
        final list = data['items'] as List;
        return list
            .map((e) => HistoryItemResponse.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      throw ApiException('Invalid history response: $e', 0);
    }
    return [];
  }

  /// Health check / ping backend
  static Future<bool> ping() async {
    try {
      final r = await _client.get(Uri.parse('$_base/api/health')).timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
