import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/staff_model.dart';
import '../../../core/models/result.dart';
import '../../../core/repositories/user_repository.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final supabase = Supabase.instance.client;
  final userRepo = ref.read(userRepositoryProvider);
  return StaffRepository(supabase, userRepo);
});

class StaffRepository {
  final SupabaseClient _supabase;
  final UserRepository _userRepository;

  StaffRepository(this._supabase, this._userRepository);

  /// Fetch staff list (READ)
  Future<List<StaffModel>> getStaffList({
    required String schoolId,
    required int from,
    required int to,
  }) async {
    try {
      final response = await _supabase
          .from(AppConstants.staffTable)
          .select()
          .eq('school_id', schoolId)
          .order('created_at', ascending: false)
          .range(from, to); // ✅ PAGINATION

      return (response as List)
          .map((e) => StaffModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ getStaffList error: $e');
      return [];
    }
  }

  /// Upload a staff photo to Supabase Storage and return the public URL.
  /// Compresses iteratively until size ≤ 100 KB or minimum quality is reached.
  Future<String?> uploadStaffPhoto({
    required String schoolId,
    required Uint8List bytes,
  }) async {
    try {
      const int maxSizeBytes = 100 * 1024; // 100 KB
      const List<int> qualitySteps = [80, 70, 60, 50, 40, 30];

      Uint8List compressed = bytes;
      for (final quality in qualitySteps) {
        final result = await FlutterImageCompress.compressWithList(
          bytes,
          quality: quality,
          format: CompressFormat.jpeg,
        );
        if (result == null) break;
        compressed = result;
        if (compressed.lengthInBytes <= maxSizeBytes) break;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '$schoolId/staff/$timestamp.jpg';
      await _supabase.storage
          .from(AppConstants.staffPhotosBucket)
          .uploadBinary(
            path,
            compressed,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      return _supabase.storage
          .from(AppConstants.staffPhotosBucket)
          .getPublicUrl(path);
    } catch (e) {
      debugPrint('❌ uploadStaffPhoto error: $e');
      return null;
    }
  }

  /// Creates a user row (role=staff) then inserts a staff record linked to it.
  Future<Result> createStaffWithUser({
    required String schoolId,
    required String schoolShortName,
    required String createdBy,
    required String empCode,
    required String name,
    required String designation,
    required String mobile,
    String? photoUrl,
  }) async {
    try {
      final user = await _userRepository.createUser(
        authUserId: null,
        schoolId: schoolId,
        schoolShortName: schoolShortName,
        role: AppConstants.roleStaff,
        name: name,
        mobile: mobile,
        createdBy: createdBy,
        isLoginEnabled: false,
      );

      await _supabase
          .from(AppConstants.staffTable)
          .insert({
        'school_id': schoolId,
        'user_id': user.id,
        'empcode': empCode,
        'name': name,
        'designation': designation,
        'mobile': mobile,
        'created_by': createdBy,
        if (photoUrl != null) 'photo_url': photoUrl,
      })
          .select()
          .single();

      return Result(success: true);
    } catch (e) {
      debugPrint('❌ createStaffWithUser error: $e');
      return Result(success: false, error: e.toString());
    }
  }

  /// Update existing staff record
  Future<Result> updateStaff({
    required String staffId,
    required String schoolId,
    required String empCode,
    required String name,
    required String designation,
    required String mobile,
    String? photoUrl,
  }) async {
    try {
      debugPrint('🟡 UPDATE STAFF ID: $staffId');

      final data = await _supabase
          .from(AppConstants.staffTable)
          .update({
        'empcode': empCode,
        'name': name,
        'designation': designation,
        'mobile': mobile,
        if (photoUrl != null) 'photo_url': photoUrl,
      })
          .eq('id', staffId)
          .select()
          .maybeSingle();

      if (data == null) {
        return Result(
          success: false,
          error: 'Staff not found or access denied',
        );
      }

      return Result(success: true);
    } catch (e) {
      debugPrint('❌ updateStaff error: $e');
      return Result(success: false, error: e.toString());
    }
  }

  /// Fetch all staff (active + inactive)
  Future<List<StaffModel>> getAllStaffList(String schoolId) async {
    try {
      final response = await _supabase
          .from(AppConstants.staffTable)
          .select()
          .eq('school_id', schoolId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => StaffModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ getAllStaffList error: $e');
      return [];
    }
  }

  /// Toggle active/inactive status for a staff member
  Future<Result> updateStaffStatus({
    required String staffId,
    required String schoolId,
    required bool isActive,
  }) async {
    try {
      final data = await _supabase
          .from(AppConstants.staffTable)
          .update({'is_active': isActive})
          .eq('id', staffId)
          .eq('school_id', schoolId)
          .select()
          .maybeSingle();

      if (data == null) {
        return Result(success: false, error: 'Staff not found or access denied');
      }

      return Result(success: true);
    } catch (e) {
      debugPrint('❌ updateStaffStatus error: $e');
      return Result(success: false, error: e.toString());
    }
  }

  /// Soft delete staff (is_active = false)
  Future<Result> deleteStaff({
    required String staffId,
    required String schoolId,
  }) async {
    try {
      final data = await _supabase
          .from(AppConstants.staffTable)
          .update({'is_active': false})
          .eq('id', staffId)
          .eq('school_id', schoolId)
          .select()
          .maybeSingle();

      if (data == null) {
        return Result(
          success: false,
          error: 'Staff not found or already deleted',
        );
      }

      return Result(success: true);
    } catch (e) {
      debugPrint('❌ deleteStaff error: $e');
      return Result(success: false, error: e.toString());
    }
  }
  /// 🔥 NEW: Fetch staff roles with joins
  Future<List<Map<String, dynamic>>> getStaffRolesRaw(String schoolId) async {
    try {
      final response = await _supabase
          .from('staff_roles')
          .select('''
          id,
          staff_id,
          role_id,
          session,
          class_name,
          section,
          created_at,
          role:roles(name),
          staff:staff(id, name)
        ''')
          .eq('school_id', schoolId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ getStaffRolesRaw error: $e');
      return [];
    }
  }
}