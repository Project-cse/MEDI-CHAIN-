class AppointmentModel {
  final String id;
  final String doctorId;
  final String doctorName;
  final String specialization;
  final String? doctorImageUrl;
  final String slotDate;
  final String slotTime;
  final String status;
  final bool cancelled;
  final bool isCompleted;
  final String? hospitalName;
  final String? location;
  final String? clinicPhone;
  final String? roomNo;
  final double? amount;
  final String? visitType;
  final String? paymentMethod;
  final String? patientName;
  final int? tokenNumber;
  final int? queuePosition;
  final String? bookingId;
  final String? publicId;
  final String? lifecycleStatus;
  final int? visitCount;
  final int? maxVisits;
  final String? validUntil;
  final int? followupVisitsUsed;
  final int? followupVisitsMax;
  final String? followupValidUntil;

  const AppointmentModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.specialization,
    this.doctorImageUrl,
    required this.slotDate,
    required this.slotTime,
    this.status = 'pending',
    this.cancelled = false,
    this.isCompleted = false,
    this.hospitalName,
    this.location,
    this.clinicPhone,
    this.roomNo,
    this.amount,
    this.visitType,
    this.paymentMethod,
    this.patientName,
    this.tokenNumber,
    this.queuePosition,
    this.bookingId,
    this.publicId,
    this.lifecycleStatus,
    this.visitCount,
    this.maxVisits,
    this.validUntil,
    this.followupVisitsUsed,
    this.followupVisitsMax,
    this.followupValidUntil,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final doc = json['docData'] ?? json['doctor'];
    final docMap = doc is Map ? Map<String, dynamic>.from(doc) : <String, dynamic>{};
    final addr = docMap['address'];
    String? addrLine1;
    String? addrLine2;
    if (addr is Map) {
      addrLine1 = addr['line1']?.toString().trim();
      addrLine2 = addr['line2']?.toString().trim();
      if (addrLine1 != null && addrLine1.isEmpty) addrLine1 = null;
      if (addrLine2 != null && addrLine2.isEmpty) addrLine2 = null;
    }
    final statusRaw = '${json['status'] ?? 'pending'}'.toLowerCase();
    final cancelled = _isTruthy(json['cancelled']) || statusRaw == 'cancelled';
    final completed =
        _isTruthy(json['isCompleted'] ?? json['is_completed']) || statusRaw == 'completed';
    return AppointmentModel(
      id: '${json['id'] ?? json['_id'] ?? ''}',
      doctorId: '${json['docId'] ?? docMap['id'] ?? json['doctorId'] ?? ''}',
      doctorName: '${docMap['name'] ?? json['docName'] ?? json['doctorName'] ?? 'Doctor'}',
      specialization: '${docMap['speciality'] ?? docMap['specialization'] ?? json['specialization'] ?? json['speciality'] ?? ''}',
      doctorImageUrl: (docMap['image'] ?? docMap['profile_pic_url'] ?? json['docImage'] ?? json['doctorImage'])?.toString(),
      slotDate: '${json['slotDate'] ?? json['slot_date'] ?? json['date'] ?? ''}',
      slotTime: '${json['slotTime'] ?? json['slot_time'] ?? json['time'] ?? ''}',
      status: statusRaw,
      cancelled: cancelled,
      isCompleted: completed,
      hospitalName: json['hospitalName']?.toString() ?? docMap['hospitalName']?.toString(),
      location: json['location']?.toString() ?? addrLine1,
      clinicPhone: (docMap['phone'] ?? docMap['hospital_contact'] ?? json['clinicPhone'])?.toString(),
      roomNo: json['roomNo']?.toString() ?? addrLine2,
      amount: (json['amount'] ?? json['fees']) is num
          ? ((json['amount'] ?? json['fees']) as num).toDouble()
          : double.tryParse('${json['amount'] ?? json['fees']}'),
      visitType: (json['visitType'] ?? json['mode'] ?? json['visit_type'])?.toString(),
      paymentMethod: (json['paymentMethod'] ?? json['payment_method'])?.toString(),
      patientName: _patientNameFromJson(json),
      tokenNumber: (json['tokenNumber'] ?? json['token_number']) is num
          ? ((json['tokenNumber'] ?? json['token_number']) as num).toInt()
          : int.tryParse('${json['tokenNumber'] ?? json['token_number'] ?? ''}'),
      queuePosition: (json['queuePosition'] ?? json['queue_position']) is num
          ? ((json['queuePosition'] ?? json['queue_position']) as num).toInt()
          : int.tryParse('${json['queuePosition'] ?? json['queue_position'] ?? ''}'),
      bookingId: (json['bookingId'] ?? json['booking_id'])?.toString(),
      publicId: (json['publicId'] ?? json['public_id'])?.toString(),
      lifecycleStatus: (json['lifecycleStatus'] ?? json['lifecycle_status'])?.toString(),
      visitCount: (json['visitCount'] ?? json['visit_count']) is num
          ? ((json['visitCount'] ?? json['visit_count']) as num).toInt()
          : int.tryParse('${json['visitCount'] ?? json['visit_count'] ?? ''}'),
      maxVisits: (json['maxVisits'] ?? json['max_visits']) is num
          ? ((json['maxVisits'] ?? json['max_visits']) as num).toInt()
          : int.tryParse('${json['maxVisits'] ?? json['max_visits'] ?? ''}'),
      validUntil: (json['validUntil'] ?? json['valid_until'])?.toString(),
      followupVisitsUsed: (json['followupVisitsUsed'] ?? json['followup_visits_used']) is num
          ? ((json['followupVisitsUsed'] ?? json['followup_visits_used']) as num).toInt()
          : null,
      followupVisitsMax: (json['followupVisitsMax'] ?? json['followup_visits_max']) is num
          ? ((json['followupVisitsMax'] ?? json['followup_visits_max']) as num).toInt()
          : null,
      followupValidUntil: (json['followupValidUntil'] ?? json['followup_valid_until'])?.toString(),
    );
  }

  bool get isUpcoming =>
      !cancelled &&
      !isCompleted &&
      status != 'cancelled' &&
      status != 'completed' &&
      !_terminalLifecycle;

  bool get _terminalLifecycle {
    final ls = (lifecycleStatus ?? '').toUpperCase();
    return {
      'CANCELLED',
      'NO_SHOW',
      'EXPIRED',
      'REFUNDED',
      'CLOSED',
      'FOLLOWUP_EXPIRED',
    }.contains(ls);
  }

  bool get followupEligible =>
      (lifecycleStatus ?? '').toUpperCase() == 'FOLLOWUP_AVAILABLE';

  bool get isOnlineVisit {
    // Only the visit type decides this — payment method is NOT a proxy
    // (an in-clinic appointment can still be paid online via Razorpay).
    final v = (visitType ?? '').toLowerCase();
    return v.contains('online') || v.contains('video');
  }

  static String? _patientNameFromJson(Map<String, dynamic> json) {
    final ap = json['actualPatient'];
    if (ap is Map && ap['name'] != null) return ap['name'].toString();
    if (ap is String && ap.isNotEmpty) return ap;
    return json['patientName']?.toString();
  }

  static bool _isTruthy(dynamic v) {
    if (v == true || v == 1) return true;
    if (v is String) {
      final s = v.toLowerCase();
      return s == 'true' || s == '1';
    }
    return false;
  }
}
