class SchoolModel {
  final String id;
  final String name;
  final String? shortName;
  final String? logoUrl;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? mobile;
  final String? email;
  final String? website;
  final bool isActive;
  final DateTime createdAt;

  const SchoolModel({
    required this.id,
    required this.name,
    this.shortName,
    this.logoUrl,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.mobile,
    this.email,
    this.website,
    this.isActive = true,
    required this.createdAt,
  });

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['short_name'] as String?,
      logoUrl: json['logo_url'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      mobile: json['mobile'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'short_name': shortName,
    'logo_url': logoUrl,
    'address': address,
    'city': city,
    'state': state,
    'pincode': pincode,
    'mobile': mobile,
    'email': email,
    'website': website,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };

  SchoolModel copyWith({
    String? name,
    String? shortName,
    String? logoUrl,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? mobile,
    String? email,
    String? website,
  }) {
    return SchoolModel(
      id: id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      logoUrl: logoUrl ?? this.logoUrl,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      website: website ?? this.website,
      isActive: isActive,
      createdAt: createdAt,
    );
  }
}
