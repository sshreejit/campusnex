import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/staff_role_model.dart';
import 'staff_repository.dart';

/// 🔹 Params for provider (with schoolId)
class StaffRoleParams {
  final String staffId;
  final String session;
  final String schoolId;

  const StaffRoleParams({
    required this.staffId,
    required this.session,
    required this.schoolId,
  });

  @override
  bool operator ==(Object other) =>
      other is StaffRoleParams &&
          other.staffId == staffId &&
          other.session == session &&
          other.schoolId == schoolId;

  @override
  int get hashCode => Object.hash(staffId, session, schoolId);
}

/// 🔹 Repository Provider
final staffRolesRepositoryProvider = Provider<StaffRolesRepository>((ref) {
  return StaffRolesRepository(Supabase.instance.client);
});

/// 🔹 Provider
final staffRolesProvider = FutureProvider.autoDispose
    .family<List<StaffRoleModel>, StaffRoleParams>((ref, params) async {
  return ref.read(staffRolesRepositoryProvider).getStaffRoles(
    params.staffId,
    params.session,
    params.schoolId,
  );
});

class StaffRolesRepository {
  final SupabaseClient _supabase;

  StaffRolesRepository(this._supabase);

  /// 🔹 Normalize session
  String _normalizeSession(String input) {
    final trimmed = input.trim();

    final parts = trimmed.split('-');
    if (parts.length != 2) return trimmed;

    final start = parts[0];
    final end = parts[1];

    final startYear = start.length == 2 ? '20$start' : start;
    final endYear = end.length == 2 ? '20$end' : end;

    return '$startYear-$endYear';
  }

  /// 🔹 Validate class/section logic
  bool _requiresClassSection(String roleId) {
    final role = roleId.toLowerCase();

    return role.contains('class') ||
        role.contains('teacher') ||
        role.contains('ct');
  }

  /// 🔹 UI display helper (UPDATED to use roleName)
  String getDisplayText(StaffRoleModel role) {
    final buffer = StringBuffer();

    buffer.write(
      role.roleName.isNotEmpty ? role.roleName : role.roleId,
    );

    if (role.className != null && role.className!.isNotEmpty) {
      buffer.write(' - ${role.className}');
    }

    if (role.section != null && role.section!.isNotEmpty) {
      buffer.write('${role.className != null ? '' : ' -'} ${role.section}');
    }

    buffer.write(' (${role.session})');

    return buffer.toString();
  }

  /// 🔹 Assign Role
  Future<Result> assignRole({
    required String staffId,
    required String roleId,
    required String session,
    required String schoolId,
    String? className,
    String? section,
  }) async {
    try {
      final normalizedSession = _normalizeSession(session);

      final requiresClass = _requiresClassSection(roleId);

      if (requiresClass) {
        if (className == null || className.trim().isEmpty) {
          return Result(
            success: false,
            error: 'Class is required for this role',
          );
        }

        if (section == null || section.trim().isEmpty) {
          return Result(
            success: false,
            error: 'Section is required for this role',
          );
        }
      }

      await _supabase.from(AppConstants.staffRolesTable).insert({
        'staff_id': staffId,
        'role_id': roleId,
        'session': normalizedSession,
        'school_id': schoolId,
        if (className != null && className.isNotEmpty)
          'class_name': className,
        if (section != null && section.isNotEmpty) 'section': section,
      });

      return Result(success: true);
    } catch (e) {
      debugPrint('❌ assignRole error: $e');

      final errorMsg = e.toString().toLowerCase();

      if (errorMsg.contains('duplicate') ||
          errorMsg.contains('unique_staff_role_session')) {
        return Result(
          success: false,
          error: 'Role already assigned for this session',
        );
      }

      return Result(success: false, error: e.toString());
    }
  }

  /// 🔹 Fetch Staff Roles (UPDATED with JOIN)
  Future<List<StaffRoleModel>> getStaffRoles(
      String staffId,
      String session,
      String schoolId,
      ) async {
    try {
      final normalizedSession = _normalizeSession(session);

      final response = await _supabase
          .from(AppConstants.staffRolesTable)
          .select('''
            *,
            role:roles (
              id,
              name
            )
          ''')
          .eq('staff_id', staffId)
          .eq('session', normalizedSession)
          .eq('school_id', schoolId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => StaffRoleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ getStaffRoles error: $e');
      return [];
    }
  }
}