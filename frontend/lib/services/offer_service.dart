import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/offer.dart';

class OfferService {
  static const String _url = 'https://getoffers-obpz3whteq-uc.a.run.app';

  static Future<Map<String, dynamic>> getOffers({
    int limit = 15,
    String? startAfter,
    http.Client? client,
    FirebaseAuth? auth,
  }) async {
    final firebaseAuth = auth ?? FirebaseAuth.instance;
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // Force token refresh to avoid 'Invalid request' due to expired tokens
    final token = await user.getIdToken(true);
    final httpClient = client ?? http.Client();

    final Map<String, dynamic> data = {
      "limit": limit,
    };
    if (startAfter != null) {
      data["startAfter"] = startAfter;
    }

    try {
      final response = await httpClient.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"data": data}),
      );

      if (response.body.isEmpty) {
        throw Exception('Empty response from server');
      }

      dynamic body;
      try {
        body = jsonDecode(response.body);
      } catch (e) {
        throw Exception('Invalid response format: ${response.body}');
      }
      
      final result = body['result'];
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (result != null && result['success'] == false) {
           final error = result['error'];
           throw Exception(error?['message'] ?? 'Unknown error');
        }
        
        final responseData = result is Map ? (result['data'] ?? result) : body;
        
        final List<dynamic> offersJson = (responseData is Map ? responseData['offers'] : null) ?? [];
        final List<OfferWithId> offers = offersJson
            .map((json) => OfferWithId.fromJson(json as Map<String, dynamic>))
            .toList();
        
        return {
          'offers': offers,
          'lastOfferId': responseData is Map ? responseData['lastOfferId'] : null,
        };
      } else {
        if (result != null && result['error'] != null) {
           throw Exception(result['error']['message']);
        }
        throw Exception('Failed to load offers: ${response.statusCode} - ${response.body}');
      }
    } finally {
      if (client == null) httpClient.close();
    }
  }

  static Future<List<Map<String, dynamic>>> getMyOffers({
    http.Client? client,
    FirebaseAuth? auth,
  }) async {
    const String myOffersUrl = 'https://getmyoffers-obpz3whteq-uc.a.run.app';
    final firebaseAuth = auth ?? FirebaseAuth.instance;
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final token = await user.getIdToken(true);
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.post(
        Uri.parse(myOffersUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"data": {}}),
      );

      if (response.body.isEmpty) {
        throw Exception('Empty response from server');
      }

      dynamic body;
      try {
        body = jsonDecode(response.body);
      } catch (e) {
        throw Exception('Invalid response format: ${response.body}');
      }

      final result = body['result'];
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (result != null && result['success'] == false) {
          final error = result['error'];
          throw Exception(error?['message'] ?? 'Unknown error');
        }
        
        final responseData = result is Map ? (result['data'] ?? result) : body;
        final List<dynamic> offersJson = (responseData is Map ? responseData['offers'] : null) ?? [];
        return List<Map<String, dynamic>>.from(offersJson);
      } else {
        if (result != null && result['error'] != null) {
          throw Exception(result['error']['message']);
        }
        throw Exception('Failed to load my offers: ${response.statusCode} - ${response.body}');
      }
    } finally {
      if (client == null) httpClient.close();
    }
  }

  static Future<OfferWithId> createOffer({
    required String startupId,
    required int qtdTokens,
    required int tokenPriceCents,
    required DateTime expiresAt,
    http.Client? client,
    FirebaseAuth? auth,
  }) async {
    const String createUrl = 'https://createoffer-obpz3whteq-uc.a.run.app';
    final firebaseAuth = auth ?? FirebaseAuth.instance;
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final token = await user.getIdToken(true);
    final httpClient = client ?? http.Client();

    final Map<String, dynamic> requestData = {
      "data": {
        "startupId": startupId,
        "qtdTokens": qtdTokens,
        "tokenPriceCents": tokenPriceCents,
        "expiresAt": expiresAt.toUtc().toIso8601String(),
      }
    };

    try {
      final response = await httpClient.post(
        Uri.parse(createUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestData),
      );

      if (response.body.isEmpty) {
        throw Exception('Empty response from server');
      }

      dynamic body;
      try {
        body = jsonDecode(response.body);
      } catch (e) {
        throw Exception('Invalid response format: ${response.body}');
      }

      final result = body['result'];
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (result != null && result['success'] == false) {
          final error = result['error'];
          throw Exception(error?['message'] ?? 'Unknown error');
        }
        
        final responseData = result is Map ? (result['data'] ?? result) : body;
        return OfferWithId.fromJson(responseData as Map<String, dynamic>);
      } else {
        if (result != null && result['error'] != null) {
          throw Exception(result['error']['message']);
        }
        throw Exception('Failed to create offer: ${response.statusCode} - ${response.body}');
      }
    } finally {
      if (client == null) httpClient.close();
    }
  }

  static Future<Map<String, dynamic>> acceptOffer({
    required String offerId,
    required int qtdTokens,
    http.Client? client,
    FirebaseAuth? auth,
  }) async {
    const String acceptUrl = 'https://acceptoffer-obpz3whteq-uc.a.run.app';
    final firebaseAuth = auth ?? FirebaseAuth.instance;
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final token = await user.getIdToken(true);
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.post(
        Uri.parse(acceptUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "data": {
            "offerId": offerId,
            "qtdTokens": qtdTokens,
          }
        }),
      );

      final body = jsonDecode(response.body);
      final result = body['result'];

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (result != null && result['success'] == false) {
          final error = result['error'];
          throw Exception(error?['message'] ?? 'Unknown error');
        }
        
        final responseData = result is Map ? (result['data'] ?? result) : body;
        return Map<String, dynamic>.from(responseData);
      } else {
        if (result != null && result['error'] != null) {
          throw Exception(result['error']['message']);
        }
        throw Exception('Failed to accept offer: ${response.statusCode} - ${response.body}');
      }
    } finally {
      if (client == null) httpClient.close();
    }
  }

  static Future<bool> isOfferExpired({
    required String offerId,
    http.Client? client,
    FirebaseAuth? auth,
  }) async {
    const String expireUrl = 'https://expireoffer-obpz3whteq-uc.a.run.app';
    final firebaseAuth = auth ?? FirebaseAuth.instance;
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final token = await user.getIdToken(true);
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.post(
        Uri.parse(expireUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "data": {
            "offerId": offerId,
          }
        }),
      );

      if (response.body.isEmpty) {
        throw Exception('Empty response from server');
      }

      final body = jsonDecode(response.body);
      final result = body['result'];

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (result != null && result['success'] == false) {
          final error = result['error'];
          throw Exception(error?['message'] ?? 'Unknown error');
        }
        
        final responseData = result is Map ? (result['data'] ?? result) : body;
        return responseData['expired'] == true;
      } else {
        if (result != null && result['error'] != null) {
          throw Exception(result['error']['message']);
        }
        throw Exception('Failed to check offer expiration: ${response.statusCode} - ${response.body}');
      }
    } finally {
      if (client == null) httpClient.close();
    }
  }
}
