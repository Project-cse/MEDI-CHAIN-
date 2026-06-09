import '../config/api_config.dart';
import '../utils/json_parser.dart';
import 'api_service.dart';

class AgoraJoinCredentials {
  const AgoraJoinCredentials({
    required this.appId,
    required this.channel,
    required this.token,
    required this.uid,
    this.consultationId,
    this.callStartedAtMs,
  });

  final String appId;
  final String channel;
  final String token;
  final int uid;
  final int? consultationId;
  final int? callStartedAtMs;

  factory AgoraJoinCredentials.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse('$value');
    }

    return AgoraJoinCredentials(
      appId: '${json['appId'] ?? json['app_id'] ?? ''}',
      channel: '${json['channel'] ?? json['channelName'] ?? ''}',
      token: '${json['token'] ?? ''}',
      uid: (json['uid'] is num) ? (json['uid'] as num).toInt() : int.tryParse('${json['uid']}') ?? 0,
      consultationId: parseInt(json['consultationId'] ?? json['consultation_id']),
      callStartedAtMs: parseInt(json['callStartedAt'] ?? json['call_started_at']),
    );
  }
}

class ConsultationService {
  ConsultationService(this._api);

  final ApiService _api;

  Future<AgoraJoinCredentials> fetchAgoraToken(String appointmentId) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiConfig.agoraTokenForAppointment(appointmentId),
      data: {},
    );
    final data = res.data ?? {};
    assertSuccess(data, 'Could not start video call');
    return AgoraJoinCredentials.fromJson(data);
  }

  Future<Map<String, dynamic>> fetchVideoCallStatus(String appointmentId) async {
    final res = await _api.get<Map<String, dynamic>>(
      ApiConfig.videoCallStatusForAppointment(appointmentId),
    );
    return res.data ?? {};
  }

  Future<Map<String, dynamic>> syncCallTimer(String appointmentId) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiConfig.syncCallTimerForAppointment(appointmentId),
      data: {},
    );
    return res.data ?? {};
  }

  Future<void> endVideoCall(String appointmentId, {int? consultationId}) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiConfig.endVideoCallForAppointment(appointmentId),
      data: {
        if (consultationId != null) 'consultationId': consultationId,
      },
    );
    final data = res.data ?? {};
    assertSuccess(data, 'Could not end video call');
  }
}
