class GuardianModel {
  final String name;
  final String email;
  final String mobileNumber;

  const GuardianModel({
    required this.name,
    required this.email,
    required this.mobileNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'mobile_number': mobileNumber,
    };
  }

  factory GuardianModel.fromJson(Map<String, dynamic> json) {
    return GuardianModel(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      mobileNumber: json['mobile_number'] as String? ?? json['phone'] as String? ?? '',
    );
  }

  GuardianModel copyWith({
    String? name,
    String? email,
    String? mobileNumber,
  }) {
    return GuardianModel(
      name: name ?? this.name,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
    );
  }

  static const GuardianModel empty = GuardianModel(
    name: 'Guardian',
    email: '',
    mobileNumber: '',
  );
}
