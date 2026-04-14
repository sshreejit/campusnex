import '../constants/app_constants.dart';

class UserModel {
  final String id;
  final String? authUserId; // null in dev mode (no Supabase auth session)
  final String schoolId;
  final String role;
  final String name;
  final String mobile;
  final String? email;
  final String? photoUrl;
  final bool isActive;
  final bool canCreateAdmin;
  final String? createdBy;
  final String? roleId;

  // ✅ NEW FIELD (REQUIRED FIX)
  final String? schoolShortName;

  final DateTime createdAt;

  const UserModel({
    required this.id,
    this.authUserId,
    required this.schoolId,
    required this.role,
    required this.name,
    required this.mobile,
    this.email,
    this.photoUrl,
    this.isActive = true,
    this.canCreateAdmin = false,
    this.createdBy,
    this.roleId,

    // ✅ ADD IN CONSTRUCTOR
    this.schoolShortName,

    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      authUserId: json['auth_user_id'] as String?,
      schoolId: json['school_id'] as String,
      role: json['role'] as String,
      name: json['name'] as String,
      mobile: json['mobile'] as String,
      email: json['email'] as String?,
      photoUrl: json['photo_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      canCreateAdmin: json['can_create_admin'] as bool? ?? false,
      createdBy: json['created_by'] as String?,
      roleId: json['role_id'] as String?,

      // ✅ MAP FROM DB
      schoolShortName: json['school_short_name'] as String?,

      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'auth_user_id': authUserId,
    'school_id': schoolId,
    'role': role,
    'name': name,
    'mobile': mobile,
    'email': email,
    'photo_url': photoUrl,
    'is_active': isActive,
    'can_create_admin': canCreateAdmin,
    'created_by': createdBy,
    'role_id': roleId,

    // ✅ ADD TO DB
    'school_short_name': schoolShortName,

    'created_at': createdAt.toIso8601String(),
  };

  bool get isSuperUser => role == AppConstants.roleSuperUser;
  bool get isAdmin => role == AppConstants.roleAdmin;
  bool get isPrincipal => role == AppConstants.rolePrincipal;
  bool get isCoordinator => role == AppConstants.roleCoordinator;
  bool get isStaff => role == AppConstants.roleStaff;
  bool get isTtIncharge => role == AppConstants.roleTtIncharge;
  bool get isParent => role == AppConstants.roleParent;
}