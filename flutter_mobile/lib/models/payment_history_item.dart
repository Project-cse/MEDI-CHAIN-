class PaymentHistoryItem {
  const PaymentHistoryItem({
    required this.id,
    required this.status,
    this.orderId,
    this.paymentId,
    this.appointmentId,
    this.doctorName,
    this.amountInr,
    this.amountPaise,
    this.error,
    this.createdAt,
  });

  final String id;
  final String? orderId;
  final String? paymentId;
  final String? appointmentId;
  final String? doctorName;
  final double? amountInr;
  final int? amountPaise;
  final String status;
  final String? error;
  final String? createdAt;

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      id: '${json['id'] ?? json['_id'] ?? ''}',
      orderId: json['order_id']?.toString(),
      paymentId: json['payment_id']?.toString(),
      appointmentId: json['appointment_id']?.toString(),
      doctorName: json['doctor_name']?.toString(),
      amountInr: (json['amount_inr'] as num?)?.toDouble(),
      amountPaise: (json['amount_paise'] as num?)?.toInt(),
      status: '${json['status'] ?? 'unknown'}',
      error: json['error']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  double get displayAmount {
    if (amountInr != null) return amountInr!;
    if (amountPaise != null) return amountPaise! / 100;
    return 0;
  }
}
