class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? city;
  final String? country;
  final String? postalCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.city,
    this.country,
    this.postalCode,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
    'city': city,
    'country': country,
    'postalCode': postalCode,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

factory User.fromJson(Map<String, dynamic> json) {
    // Safe date parsing
    DateTime userCreatedAt;
    try {
      userCreatedAt = json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now();
    } catch (_) {
      userCreatedAt = DateTime.now();
    }

    DateTime userUpdatedAt;
    try {
      userUpdatedAt = json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now();
    } catch (_) {
      userUpdatedAt = DateTime.now();
    }

    return User(
      id: json['id'] is String ? json['id'] as String : '',
      name: json['name'] is String ? json['name'] as String : 'Unknown User',
      email: json['email'] is String ? json['email'] as String : '',
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      postalCode: json['postalCode'] as String?,
      createdAt: userCreatedAt,
      updatedAt: userUpdatedAt,
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? country,
    String? postalCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    city: city ?? this.city,
    country: country ?? this.country,
    postalCode: postalCode ?? this.postalCode,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
