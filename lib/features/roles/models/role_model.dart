class RoleModel {
  final String id;
  final String name;
  final String schoolId;
  final String? createdBy;
  final DateTime createdAt;

  const RoleModel({
    required this.id,
    required this.name,
    required this.schoolId,
    this.createdBy,
    required this.createdAt,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] as String,
      name: json['name'] as String,
      schoolId: json['school_id'] as String,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
