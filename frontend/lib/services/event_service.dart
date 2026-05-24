// Autor: Gemini CLI
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';
import '../models/api_response.dart';
import 'base_service.dart';

class EventService {
  static const String _listEventsUrl = 'https://listevents-obpz3whteq-uc.a.run.app';

  static Future<ApiResponse<EventPaginatedResponse>> listEvents({
    String? startupId,
    int? limit,
    String? lastEventId,
    http.Client? client,
    FirebaseAuth? auth,
  }) async {
    final Map<String, dynamic> data = {};
    if (startupId != null) data['startupId'] = startupId;
    if (limit != null) data['limit'] = limit;
    if (lastEventId != null) data['lastEventId'] = lastEventId;

    return BaseService.post<EventPaginatedResponse>(
      _listEventsUrl,
      data: data,
      fromJson: (responseData) => EventPaginatedResponse.fromJson(responseData as Map<String, dynamic>),
      client: client,
      auth: auth,
    );
  }
}
