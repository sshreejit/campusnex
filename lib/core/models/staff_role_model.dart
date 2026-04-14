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
      id: json['id']?.toString() ?? '',

      schoolId: json['school_id']?.toString() ?? '',

      staffId: json['staff_id']?.toString() ?? '',

      roleId: json['role_id']?.toString() ?? '',

      // ✅ SAFE JOIN EXTRACTION
      roleName: json['role']?['name']?.toString() ?? '',

      session: json['session']?.toString() ?? '',

      className: json['class_name']?.toString(),
      section: json['section']?.toString(),

      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
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