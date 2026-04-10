import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../models/designation_model.dart';

final designationRepositoryProvider = Provider<DesignationRepository>((ref) {
  return DesignationRepository(Supabase.instance.client);
});

class DesignationResult {
  final bool success;
  final String? error;

  DesignationResult({required this.success, this.error});
}

class DesignationRepository {
  final SupabaseClient _supabase;

  DesignationRepository(this._supabase);

  Future<List<DesignationModel>> getDesignations(String schoolId) async {
    try {
      final response = await _supabase
          .from(AppConstants.designationsTable)
          .select()
          .eq('school_id', schoolId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => DesignationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ getDesignations error: $e');
      return [];
    }
  }

  Future<DesignationResult> addDesignation({
    required String name,
    required String schoolId,
  }) async {
    try {
      await _supabase.from(AppConstants.designationsTable).insert({
        'name': name.trim(),
        'school_id': schoolId,
      });
      return DesignationResult(success: true);
    } on PostgrestException catch (e) {
      debugPrint('❌ addDesignation error: $e');
      if (e.code == '23505') {
        return DesignationResult(success: false, error: 'Designation already exists');
      }
      return DesignationResult(success: false, error: e.message);
    } catch (e) {
      debugPrint('❌ addDesignation error: $e');
      return DesignationResult(success: false, error: e.toString());
    }
  }

  Future<DesignationResult> updateDesignation({
    required String id,
    required String name,
  }) async {
    try {
      await _supabase
          .from(AppConstants.designationsTable)
          .update({'name': name.trim()})
          .eq('id', id);
      return DesignationResult(success: true);
    } on PostgrestException catch (e) {
      debugPrint('❌ updateDesignation error: $e');
      if (e.code == '23505') {
        return DesignationResult(success: false, error: 'Designation already exists');
      }
      return DesignationResult(success: false, error: e.message);
    } catch (e) {
      debugPrint('❌ updateDesignation error: $e');
      return DesignationResult(success: false, error: e.toString());
    }
  }

  Future<DesignationResult> deleteDesignation({required String id}) async {
    try {
      await _supabase
          .from(AppConstants.designationsTable)
          .update({'is_active': false})
          .eq('id', id);
      return DesignationResult(success: true);
    } catch (e) {
      debugPrint('❌ deleteDesignation error: $e');
      return DesignationResult(success: false, error: e.toString());
    }
  }
}
