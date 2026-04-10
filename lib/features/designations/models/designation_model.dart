class DesignationModel {
  final String id;
  final String name;
  final String schoolId;
  final bool isActive;
  final DateTime createdAt;

  const DesignationModel({
    required this.id,
    required this.name,
    required this.schoolId,
    required this.isActive,
    required this.createdAt,
  });

  factory DesignationModel.fromJson(Map<String, dynamic> json) {
    return DesignationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      schoolId: json['school_id'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
