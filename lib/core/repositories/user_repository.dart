import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import 'auth_repository.dart';

part 'user_repository.g.dart';

class UserRepository {
  final SupabaseClient _client;

  UserRepository(this._client);

  /// Creates a new row in the [users] table.
  Future<UserModel> createUser({
    required String? authUserId,
    required String schoolId,
    required String role,
    required String name,
    required String mobile,
    String? schoolShortName,
    String? email,
    String? createdBy,
    String? roleId,
    bool isLoginEnabled = false,
  }) async {
    final isSuperUser = role == AppConstants.roleSuperUser;

    if (!isSuperUser &&
        (schoolShortName == null || schoolShortName.isEmpty)) {
      throw Exception('schoolShortName is required for role: $role');
    }

    final safeShortName =
    schoolShortName?.trim().toLowerCase().replaceAll(' ', '');

    final username =
    isSuperUser ? null : '$mobile.$safeShortName';

    try {
      final data = await _client
          .from(AppConstants.usersTable)
          .insert({
        'auth_user_id': authUserId,
        'school_id': schoolId,
        'role': role,
        'name': name,
        'mobile': mobile,
        if (username != null) 'username': username,
        'email': email,
        if (createdBy != null) 'created_by': createdBy,
        if (role == AppConstants.roleStaff && roleId != null)
          'role_id': roleId,
        'is_login_enabled': isLoginEnabled,
      })
          .select()
          .maybeSingle(); // ✅ FIX

      if (data == null || data['id'] == null) {
        throw Exception('User insert failed');
      }

      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception('createUser failed: $e');
    }
  }

  Future<UserModel?> getUserByMobile(String mobile, [String? schoolId]) async {
    try {
      var query = _client
          .from(AppConstants.usersTable)
          .select()
          .eq('mobile', mobile);

      if (schoolId != null) {
        query = query.eq('school_id', schoolId);
      }

      final data = await query.maybeSingle();
      if (data == null) return null;

      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception('getUserByMobile failed: $e');
    }
  }

  Future<UserModel?> getUserById(String id) async {
    try {
      final data = await _client
          .from(AppConstants.usersTable)
          .select()
          .eq('id', id)
          .maybeSingle(); // ✅ FIX

      if (data == null) return null;

      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception('getUserById failed: $e');
    }
  }

  Future<List<UserModel>> getUsersByRole(
      String schoolId, String role) async {
    try {
      final data = await _client
          .from(AppConstants.usersTable)
          .select()
          .eq('school_id', schoolId)
          .eq('role', role)
          .eq('is_active', true)
          .order('name', ascending: true);

      return data.map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('is_active') || msg.contains('column')) {
        // is_active column not yet migrated — fall back to unfiltered
        final data = await _client
            .from(AppConstants.usersTable)
            .select()
            .eq('school_id', schoolId)
            .eq('role', role)
            .order('name', ascending: false);
        return data.map((e) => UserModel.fromJson(e)).toList();
      }
      throw Exception('getUsersByRole failed: $e');
    }
  }

  Future<List<UserModel>> getUsersBySchool(String schoolId) async {
    try {
      final data = await _client
          .from(AppConstants.usersTable)
          .select()
          .eq('school_id', schoolId)
          .eq('is_active', true)
          .neq('role', AppConstants.roleSuperUser)
          .order('created_at', ascending: false);

      return data.map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('is_active') || msg.contains('column')) {
        // is_active column not yet migrated — fall back to unfiltered
        final data = await _client
            .from(AppConstants.usersTable)
            .select()
            .eq('school_id', schoolId)
            .neq('role', AppConstants.roleSuperUser)
            .order('created_at', ascending: false);
        return data.map((e) => UserModel.fromJson(e)).toList();
      }
      throw Exception('getUsersBySchool failed: $e');
    }
  }

  Future<UserModel?> getUserByAuthId(String authUserId) async {
    try {
      final data = await _client
          .from(AppConstants.usersTable)
          .select()
          .eq('auth_user_id', authUserId)
          .maybeSingle();

      if (data == null) return null;

      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception('getUserByAuthId failed: $e');
    }
  }

  /// Login (no schoolId required)
  Future<Map<String, dynamic>?> login(String input) async {
    try {
      final cleaned = input.trim().toLowerCase();
      final isMobile = RegExp(r'^\d{10}$').hasMatch(cleaned);

      if (isMobile) {
        return await _client
            .from(AppConstants.usersTable)
            .select()
            .eq('mobile', cleaned)
            .eq('role', AppConstants.roleSuperUser)
            .maybeSingle();
      } else {
        return await _client
            .from(AppConstants.usersTable)
            .select()
            .eq('username', cleaned)
            .maybeSingle();
      }
    } catch (e) {
      throw Exception('login failed: $e');
    }
  }

  Future<UserModel> createAdmin({
    required String name,
    required String mobile,
    required String schoolId,
    required String schoolShortName,
    required String createdBy,
  }) async {
    final existing = await getUserByMobile(mobile, schoolId);

    if (existing != null) {
      throw Exception('Mobile number is already registered');
    }

    return createUser(
      authUserId: null,
      schoolId: schoolId,
      role: AppConstants.roleAdmin,
      name: name,
      mobile: mobile,
      schoolShortName: schoolShortName,
      createdBy: createdBy,
    );
  }

  /// ✅ NEW: Toggle admin manager
  Future<void> toggleAdminManager({
    required String userId,
    required bool value,
    required String schoolId,
  }) async {
    await _client
        .from(AppConstants.usersTable)
        .update({'can_create_admin': value})
        .eq('id', userId)
        .eq('school_id', schoolId);
  }

  /// ✅ NEW: Creator labels
  Future<Map<String, String>> getCreatorLabels(
      List<String> creatorIds) async {
    if (creatorIds.isEmpty) return {};

    final data = await _client
        .from(AppConstants.usersTable)
        .select('id, name')
        .inFilter('id', creatorIds);

    return {
      for (final item in data) item['id']: item['name'] ?? 'Unknown'
    };
  }

  Future<void> setAdminManager({
    required String adminId,
    required String schoolId,
  }) async {
    await _client
        .from(AppConstants.usersTable)
        .update({'can_create_admin': false})
        .eq('school_id', schoolId)
        .eq('role', AppConstants.roleAdmin);

    await _client
        .from(AppConstants.usersTable)
        .update({'can_create_admin': true})
        .eq('id', adminId);
  }

  Future<UserModel> updateUserName(String userId, String name) async {
    final target = await getUserById(userId);

    if (target != null && target.canCreateAdmin) {
      throw Exception('Admin manager cannot be modified');
    }

    final data = await _client
        .from(AppConstants.usersTable)
        .update({'name': name})
        .eq('id', userId)
        .select()
        .maybeSingle();

    if (data == null) {
      throw Exception('User not found');
    }

    return UserModel.fromJson(data);
  }

  Future<UserModel> updateUser({
    required String userId,
    required String name,
    required String mobile,
    required String schoolId,
    required String schoolShortName,
    bool allowModifyManager = false,
  }) async {
    if (!allowModifyManager) {
      final target = await getUserById(userId);
      if (target != null && target.canCreateAdmin) {
        throw Exception('Admin manager cannot be modified');
      }
    }

    final trimmedMobile = mobile.trim();

    final existing = await getUserByMobile(trimmedMobile, schoolId);
    if (existing != null && existing.id != userId) {
      throw Exception('Mobile already in use');
    }

    final newUsername =
        '$trimmedMobile.${schoolShortName.trim().toLowerCase().replaceAll(' ', '')}';

    final existingUsername = await _client
        .from(AppConstants.usersTable)
        .select('id')
        .eq('username', newUsername)
        .neq('id', userId)
        .maybeSingle();

    if (existingUsername != null) {
      throw Exception('Username already exists');
    }

    final data = await _client
        .from(AppConstants.usersTable)
        .update({
      'name': name,
      'mobile': trimmedMobile,
      'username': newUsername,
    })
        .eq('id', userId)
        .eq('school_id', schoolId)
        .select()
        .maybeSingle();

      if (data == null) {
        throw Exception('User not found or access denied');
      }

    return UserModel.fromJson(data);
  }

  /// SOFT DELETE
  Future<void> deleteUser({
    required String userId,
    required String schoolId,
  }) async {
    final target = await getUserById(userId);

    if (target != null && target.canCreateAdmin) {
      throw Exception('Admin manager cannot be modified');
    }

    try {
      final response = await _client
          .from(AppConstants.usersTable)
          .update({'is_active': false})
          .eq('id', userId)
          .eq('school_id', schoolId)
          .eq('role', AppConstants.roleAdmin)
          .select();

      if (response.isEmpty) {
        throw Exception('Operation failed');
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('is_active') || msg.contains('column')) {
        throw Exception(
            'Soft delete is not available yet. Run the required database migration first.');
      }
      throw Exception('deleteUser failed: $e');
    }
  }
}

@riverpod
UserRepository userRepository(Ref ref) {
  return UserRepository(SupabaseService.client);
}


@riverpod
Future<UserModel> currentUser(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString(AppConstants.prefUserId);

  if (userId == null) {
    throw Exception('User not available');
  }

  final user =
  await ref.read(userRepositoryProvider).getUserById(userId);

  if (user == null) {
    throw Exception('User not found');
  }

  return user;
}