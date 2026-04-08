class StaffRoleModel {
  final String id;
  final String schoolId;
  final String staffId;
  final String roleId;

  /// ✅ NEW FIELD (for UI display)
  final String roleName;

  final String session;
  final String? className;
  final String? section;
  final DateTime createdAt;

  const StaffRoleModel({
    required this.id,
    required this.schoolId,
    required this.staffId,
    required this.roleId,
    required this.roleName, // ✅ NEW
    required this.session,
    this.className,
    this.section,
    required this.createdAt,
  });

  factory StaffRoleModel.fromJson(Map<String, dynamic> json) {
    return StaffRoleModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      staffId: json['staff_id'] as String,
      roleId: json['role_id'] as String,

      /// ✅ SAFE EXTRACTION (handles JOIN)
      roleName: (json['role'] != null &&
          json['role'] is Map &&
          json['role']['name'] != null)
          ? json['role']['name'] as String
          : '',

      session: json['session'] as String,
      className: json['class_name'] as String?,
      section: json['section'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'school_id': schoolId,
    'staff_id': staffId,
    'role_id': roleId,

    /// ⚠️ roleName NOT stored in DB
    'session': session,
    'class_name': className,
    'section': section,
    'created_at': createdAt.toIso8601String(),
  };
}