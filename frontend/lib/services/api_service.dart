/// GreenBin Genius – API Service
/// Central HTTP client for all communication with the FastAPI backend.
/// Handles JWT token storage, injection into headers, and error parsing.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';  // for MediaType

// ─────────────────────────────────────────────────────────────
// Base URL – Hugging Face Space (production)
// ─────────────────────────────────────────────────────────────
const String _kBaseUrl = 'https://rg2323-greenbin-backend.hf.space';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final _storage = const FlutterSecureStorage();
  final _client = http.Client();

  // ── Base URL (can be overridden at runtime) ─────────────────
  static String baseUrl = _kBaseUrl;

  // ── Token helpers ───────────────────────────────────────────

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: 'jwt_token');
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Generic error parser ─────────────────────────────────────

  /// Wrap network calls to handle SocketException, ClientException, etc.
  /// to avoid exposing backend URLs and provide user-friendly messages.
  Future<T> _wrapNetworkCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on SocketException {
      throw Exception('No internet connection. Please check your network and try again.');
    } on http.ClientException {
      throw Exception('Unable to reach the server. Please try again later.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  Exception _handleError(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      return Exception(body['detail'] ?? 'Server error ${res.statusCode}');
    } catch (_) {
      return Exception('Server error ${res.statusCode}');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════════════════════════

  /// Register a new user. Returns the token response on success.
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String language = 'en',
  }) async {
    return _wrapNetworkCall(() async {
      final res = await _client.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'language': language,
        }),
      );
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        await saveToken(data['access_token']);
        return data;
      }
      throw _handleError(res);
    });
  }

  /// Login an existing user. Returns the token response on success.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return _wrapNetworkCall(() async {
      final res = await _client.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        await saveToken(data['access_token']);
        return data;
      }
      throw _handleError(res);
    });
  }

  /// Fetch the currently authenticated user's profile.
  Future<Map<String, dynamic>> getMe() async {
    return _wrapNetworkCall(() async {
      final res = await _client.get(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: await _authHeaders(),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw _handleError(res);
    });
  }

  // ═══════════════════════════════════════════════════════════
  // CLASSIFICATION
  // ═══════════════════════════════════════════════════════════

  /// Send an image file to the backend for AI classification.
  /// Automatically detects JPEG / PNG and sets the correct MIME type.
  Future<ClassificationResult> classifyImage(File imageFile) async {
    return _wrapNetworkCall(() async {
      final token = await getToken();
      if (token == null) throw Exception('Not authenticated. Please log in first.');

      // Detect MIME type from file extension.
      final ext = imageFile.path.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'png' : 'jpeg';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/classify'),
      )
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType('image', mimeType),
          filename: 'photo.$mimeType',
        ));

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 200) {
        return ClassificationResult.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>,
        );
      }
      throw _handleError(res);
    });
  }

  // ═══════════════════════════════════════════════════════════
  // HISTORY
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getHistory({int page = 1, int limit = 20}) async {
    return _wrapNetworkCall(() async {
      final res = await _client.get(
        Uri.parse('$baseUrl/api/history?page=$page&limit=$limit'),
        headers: await _authHeaders(),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw _handleError(res);
    });
  }

  Future<void> deleteHistoryEntry(String id) async {
    return _wrapNetworkCall(() async {
      final res = await _client.delete(
        Uri.parse('$baseUrl/api/history/$id'),
        headers: await _authHeaders(),
      );
      if (res.statusCode != 200) throw _handleError(res);
    });
  }

  // ═══════════════════════════════════════════════════════════
  // BINS
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getNearbyBins({
    required double lat,
    required double lng,
    int maxDistanceM = 5000,
    int limit = 10,
  }) async {
    return _wrapNetworkCall(() async {
      final res = await _client.get(
        Uri.parse(
          '$baseUrl/api/bins/nearby?lat=$lat&lng=$lng'
          '&max_distance_m=$maxDistanceM&limit=$limit',
        ),
        headers: await _authHeaders(),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw _handleError(res);
    });
  }

  // ═══════════════════════════════════════════════════════════
  // ANALYTICS
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getMyAnalytics() async {
    return _wrapNetworkCall(() async {
      final res = await _client.get(
        Uri.parse('$baseUrl/api/analytics/me'),
        headers: await _authHeaders(),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw _handleError(res);
    });
  }

  Future<Map<String, dynamic>> getGlobalAnalytics() async {
    return _wrapNetworkCall(() async {
      final res = await _client.get(
        Uri.parse('$baseUrl/api/analytics/global'),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw _handleError(res);
    });
  }

  // ═══════════════════════════════════════════════════════════
  // LEADERBOARD
  // ═══════════════════════════════════════════════════════════

  Future<List<dynamic>> getMemberLeaderboard({int limit = 10}) async {
    return _wrapNetworkCall(() async {
      final res = await _client.get(
        Uri.parse('$baseUrl/api/leaderboard/members?limit=$limit'),
        headers: await _authHeaders(),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw _handleError(res);
    });
  }

  Future<List<dynamic>> getCountryLeaderboard({int limit = 10}) async {
    return _wrapNetworkCall(() async {
      final res = await _client.get(
        Uri.parse('$baseUrl/api/leaderboard/countries?limit=$limit'),
        headers: await _authHeaders(),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw _handleError(res);
    });
  }

  // ═══════════════════════════════════════════════════════════
  // HEALTH CHECK
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> healthCheck() async {
    return _wrapNetworkCall(() async {
      final res = await _client.get(Uri.parse('$baseUrl/health'));
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw Exception('Backend unreachable');
    });
  }
}

// ─────────────────────────────────────────────────────────────
// Data Model
// ─────────────────────────────────────────────────────────────

class YOLODetection {
  final String label;
  final double confidence;
  final List<double> box; // [xmin, ymin, xmax, ymax]

  const YOLODetection({
    required this.label,
    required this.confidence,
    required this.box,
  });

  factory YOLODetection.fromJson(Map<String, dynamic> json) {
    return YOLODetection(
      label: json['label'] ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      box: (json['box'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [0.0, 0.0, 0.0, 0.0],
    );
  }
}

class ClassificationResult {
  final String category;
  final String objectDetected;
  final String material;
  final double confidence;
  final double cnnConfidence;
  final double yoloConfidence;
  final List<YOLODetection> detections;
  final String disposalTip;
  final String disposalTipUr;
  final bool recyclable;
  final String? imageUrl;
  final DateTime timestamp;

  const ClassificationResult({
    required this.category,
    required this.objectDetected,
    required this.material,
    required this.confidence,
    this.cnnConfidence = 0.0,
    this.yoloConfidence = 0.0,
    this.detections = const [],
    required this.disposalTip,
    required this.disposalTipUr,
    required this.recyclable,
    this.imageUrl,
    required this.timestamp,
  });

  factory ClassificationResult.fromJson(Map<String, dynamic> json) {
    return ClassificationResult(
      category: json['category'] ?? 'Unknown',
      objectDetected: json['object_detected'] ?? 'Unknown',
      material: json['material'] ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      cnnConfidence: (json['cnn_confidence'] as num?)?.toDouble() ?? (json['confidence'] as num?)?.toDouble() ?? 0.0,
      yoloConfidence: (json['yolo_confidence'] as num?)?.toDouble() ?? 0.0,
      detections: (json['detections'] as List<dynamic>?)
          ?.map((e) => YOLODetection.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      disposalTip: json['disposal_tip'] ?? '',
      disposalTipUr: json['disposal_tip_ur'] ?? '',
      recyclable: json['recyclable'] ?? false,
      imageUrl: json['image_url'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  /// Confidence as a percentage string e.g. "94%"
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(0)}%';

  String get cnnConfidencePercent => '${(cnnConfidence * 100).toStringAsFixed(0)}%';
  String get yoloConfidencePercent => '${(yoloConfidence * 100).toStringAsFixed(0)}%';
}
