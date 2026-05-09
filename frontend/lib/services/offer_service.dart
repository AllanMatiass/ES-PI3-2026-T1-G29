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

    final token = await user.getIdToken();
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
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"data": data}),
      );

      final body = jsonDecode(response.body);
      
      // Checking for Firebase Function wrapper
      final result = body['result'];
      if (response.statusCode == 200) {
        if (result != null && result['success'] == false) {
           final error = result['error'];
           throw Exception(error?['message'] ?? 'Unknown error');
        }

        // If result is null, maybe it's not a standard Firebase wrapper but the direct response?
        // But the user said "response em caso de erro: { "result": ... }"
        // So it's definitely wrapped.
        
        final responseData = result is Map ? (result['data'] ?? result) : body;
        
        final List<dynamic> offersJson = responseData['offers'] ?? [];
        final List<OfferWithId> offers = offersJson
            .map((json) => OfferWithId.fromJson(json as Map<String, dynamic>))
            .toList();
        
        return {
          'offers': offers,
          'lastOfferId': responseData['lastOfferId'],
        };
      } else {
        // Error handling based on provided format
        if (result != null && result['error'] != null) {
           throw Exception(result['error']['message']);
        }
        throw Exception('Failed to load offers: ${response.statusCode}');
      }
    } finally {
      if (client == null) httpClient.close();
    }
  }
}
