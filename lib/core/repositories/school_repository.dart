import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../models/school_model.dart';
import '../services/supabase_service.dart';

part 'school_repository.g.dart';

class SchoolRepository {
  final SupabaseClient _client;

  SchoolRepository(this._client);

  Future<SchoolModel> createSchool(String name, {String? mobile}) async {
    final data = await _client
        .from(AppConstants.schoolsTable)
        .insert({
          'name': name,
          if (mobile != null) 'mobile': mobile,
        })
        .select()
        .single();
    return SchoolModel.fromJson(data);
  }

  Future<SchoolModel?> getSchoolById(String id) async {
    final data = await _client
        .from(AppConstants.schoolsTable)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return SchoolModel.fromJson(data);
  }

  Future<SchoolModel> updateSchool(
    String id, {
    String? name,
    String? mobile,
    String? logoUrl,
    String? shortName,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (mobile != null) updates['mobile'] = mobile;
    if (logoUrl != null) updates['logo_url'] = logoUrl;
    if (shortName != null) updates['short_name'] = shortName;

    final data = await _client
        .from(AppConstants.schoolsTable)
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return SchoolModel.fromJson(data);
  }

  /// Uploads [bytes] to the school-logos bucket as `[schoolId].jpg`,
  /// then updates [schools.logo_url] and returns the public URL.
  Future<String> uploadSchoolLogo(
    String schoolId,
    Uint8List bytes,
    String mimeType,
  ) async {
    final filePath = '$schoolId.jpg';
    await _client.storage
        .from(AppConstants.schoolLogosBucket)
        .uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );
    final baseUrl = _client.storage
        .from(AppConstants.schoolLogosBucket)
        .getPublicUrl(filePath);
    final url = '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    await updateSchool(schoolId, logoUrl: url);
    return url;
  }

  Future<int> getSchoolUsersCount(String schoolId) async {
    final data = await _client
        .from(AppConstants.usersTable)
        .select('id')
        .eq('school_id', schoolId)
        .neq('role', 'super_user');
    final count = (data as List).length;
    dev.log('[SchoolRepo] non-super_user count for school $schoolId: $count', name: 'short_name');
    return count;
  }

  Future<SchoolModel?> getSchoolByMobile(String mobile) async {
    final data = await _client
        .from(AppConstants.schoolsTable)
        .select()
        .eq('mobile', mobile)
        .maybeSingle();
    if (data == null) return null;
    return SchoolModel.fromJson(data);
  }
}

@riverpod
SchoolRepository schoolRepository(Ref ref) {
  return SchoolRepository(SupabaseService.client);
}
