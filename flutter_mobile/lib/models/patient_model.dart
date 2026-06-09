class PatientModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? dob;
  final String? gender;
  final String? bloodGroup;
  final String? address;
  final String? emergencyContact;
  final String? profilePicUrl;

  const PatientModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.dob,
    this.gender,
    this.bloodGroup,
    this.address,
    this.emergencyContact,
    this.profilePicUrl,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      email: '${json['email'] ?? ''}',
      phone: json['phone']?.toString(),
      dob: json['dob']?.toString() ?? json['dateOfBirth']?.toString(),
      gender: json['gender']?.toString(),
      bloodGroup: json['bloodGroup']?.toString() ?? json['blood_group']?.toString(),
      address: formatAddress(json['address']),
      emergencyContact: json['emergencyContact']?.toString(),
      profilePicUrl: json['image']?.toString() ?? json['profile_pic_url']?.toString(),
    );
  }

  static String? formatAddress(dynamic addr) {
    if (addr == null) return null;
    if (addr is String) {
      final t = addr.trim();
      return t.isEmpty ? null : t;
    }
    if (addr is Map) {
      final line1 = addr['line1']?.toString().trim() ?? '';
      final line2 = addr['line2']?.toString().trim() ?? '';
      final parts = [line1, line2].where((s) => s.isNotEmpty).toList();
      return parts.isEmpty ? null : parts.join(', ');
    }
    return null;
  }

  /// Splits display address into line1 / line2 (matches RN address screen).
  ({String line1, String line2}) get addressLines {
    if (address == null || address!.trim().isEmpty) {
      return (line1: '', line2: '');
    }
    final parts = address!.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return (line1: '', line2: '');
    if (parts.length == 1) return (line1: parts.first, line2: '');
    return (line1: parts.first, line2: parts.sublist(1).join(', '));
  }

  Map<String, dynamic> toPatchJson() => {
        if (name.isNotEmpty) 'name': name,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (dob != null && dob!.isNotEmpty) 'dob': dob,
        if (gender != null && gender!.isNotEmpty) 'gender': gender,
        if (bloodGroup != null && bloodGroup!.isNotEmpty) 'bloodGroup': bloodGroup,
        if (emergencyContact != null && emergencyContact!.isNotEmpty) 'emergencyContact': emergencyContact,
      };

  PatientModel copyWith({
    String? name,
    String? phone,
    String? dob,
    String? gender,
    String? bloodGroup,
    String? address,
    String? emergencyContact,
    String? profilePicUrl,
  }) {
    return PatientModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
    );
  }
}
