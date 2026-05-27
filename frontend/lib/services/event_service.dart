// Autor: Allan Giovanni Matias Paes - 25008211
import '../models/event.dart';
import '../models/api_response.dart';
import 'base_service.dart';

class EventService {
  static Future<ApiResponse<EventPaginatedResponse>> listEvents({
    String? startupId,
    int? limit,
    String? lastEventId,
  }) async {
    final Map<String, dynamic> data = {};
    if (startupId != null) data['startupId'] = startupId;
    if (limit != null) data['limit'] = limit;
    if (lastEventId != null) data['lastEventId'] = lastEventId;

    return BaseService.call<EventPaginatedResponse>(
      'listEvents',
      data: data,
      fromJson: (responseData) => EventPaginatedResponse.fromJson(responseData),
    );
  }
}
