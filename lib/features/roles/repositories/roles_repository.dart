import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../models/role_model.dart';

final rolesRepositoryProvider = Provider<RolesRepository>((ref) {
  return RolesRepository(Supabase.instance.client);
});

class RoleResult {
  final bool success;
  final String? error;

  RoleResult({required this.success, this.error});
}

class RolesRepository {
  final SupabaseClient _supabase;

  RolesRepository(this._supabase);

  // ─────────────────────────────────────────────
  // GET ROLES
  // ─────────────────────────────────────────────
  Future<List<RoleModel>> getRolesBySchool(String schoolId) async {
    try {
      final response = await _supabase
          .from(AppConstants.rolesTable)
          .select()
          .eq('school_id', schoolId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => RoleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ getRolesBySchool error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // ADD ROLE
  // ─────────────────────────────────────────────
  Future<RoleResult> addRole({
    required String name,
    required String schoolId,
    required String createdBy,
  }) async {
    try {
      await _supabase.from(AppConstants.rolesTable).insert({
        'name': name.trim(),
        'school_id': schoolId,
        'created_by': createdBy,
      });

      return RoleResult(success: true);
    } on PostgrestException catch (e) {
      debugPrint('❌ addRole error: $e');

      if (e.code == '23505') {
        return RoleResult(success: false, error: 'Role already exists');
      }

      return RoleResult(success: false, error: e.message);
    } catch (e) {
      debugPrint('❌ addRole error: $e');
      return RoleResult(success: false, error: e.toString());
    }
  }

  // ─────────────────────────────────────────────
  // UPDATE ROLE (FIXED)
  // ─────────────────────────────────────────────
  Future<RoleResult> updateRole({
    required String roleId,
    required String schoolId,
    required String name,
  }) async {
    debugPrint('DEBUG ROLE ID: $roleId');
    debugPrint('DEBUG SCHOOL ID: $schoolId');
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return RoleResult(success: false, error: 'Role name cannot be empty');
    }

    try {
      final response = await _supabase
          .from(AppConstants.rolesTable)
          .update({'name': trimmed})
          .eq('id', roleId)
          .eq('school_id', schoolId)
          .select()
          .maybeSingle();

      // 🔴 CRITICAL CHECK
      if (response == null) {
        return RoleResult(
          success: false,
          error: 'Role update failed (no matching record)',
        );
      }

      return RoleResult(success: true);
    } on PostgrestException catch (e) {
      debugPrint('❌ updateRole error: $e');

      if (e.code == '23505') {
        return RoleResult(success: false, error: 'Role already exists');
      }

      return RoleResult(success: false, error: e.message);
    } catch (e) {
      debugPrint('❌ updateRole error: $e');
      return RoleResult(success: false, error: e.toString());
    }
  }

  // ─────────────────────────────────────────────
  // DELETE ROLE (WITH FK HANDLING)
  // ─────────────────────────────────────────────
  Future<RoleResult> deleteRole({
    required String roleId,
    required String schoolId,
  }) async {
    try {
      await _supabase
          .from(AppConstants.rolesTable)
          .delete()
          .eq('id', roleId)
          .eq('school_id', schoolId);

      return RoleResult(success: true);
    } catch (e) {
      debugPrint('❌ deleteRole error: $e');

      final message = e.toString().toLowerCase();

      if (message.contains('fk_role') ||
          message.contains('foreign key')) {
        return RoleResult(
          success: false,
          error:
          'Role is already assigned to staff. Please remove it from staff before deleting.',
        );
      }

      return RoleResult(success: false, error: 'Failed to delete role');
    }
  }
}