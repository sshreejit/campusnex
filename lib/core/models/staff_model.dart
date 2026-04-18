class StaffModel {
  final String id;
  final String schoolId;
  final String userId;
  final String empcode;
  final String name;
  final String designation;
  final String mobile;
  final bool isActive;
  final DateTime createdAt;
  final String? photoUrl;

  const StaffModel({
    required this.id,
    required this.schoolId,
    required this.userId,
    required this.empcode,
    required this.name,
    required this.designation,
    required this.mobile,
    required this.isActive,
    required this.createdAt,
    this.photoUrl,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      userId: json['user_id'] as String,
      empcode: json['empcode'] as String,
      name: json['name'] as String,
      designation: json['designation'] as String? ?? '',
      mobile: json['mobile'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      photoUrl: json['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'school_id': schoolId,
        'user_id': userId,
        'empcode': empcode,
        'name': name,
        'designation': designation,
        'mobile': mobile,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'photo_url': photoUrl,
      };
}
