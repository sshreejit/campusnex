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
          .order('name', ascending: true);

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
      /// STEP 1: Get OLD NAME
      final old = await _supabase
          .from(AppConstants.designationsTable)
          .select('name')
          .eq('id', id)
          .single();

      final oldName = old['name'];

      /// STEP 2: Update designation table
      await _supabase
          .from(AppConstants.designationsTable)
          .update({'name': name.trim()})
          .eq('id', id);

      /// STEP 3: Update staff table (FIXED)
      await _supabase
          .from('staff')
          .update({'designation': name.trim()})
          .ilike('designation', '%$oldName%');

      return DesignationResult(success: true);
    } catch (e) {
      return DesignationResult(success: false, error: e.toString());
    }
  }

  Future<DesignationResult> deleteDesignation({required String id}) async {
    try {
      /// STEP 1: Get designation name
      final old = await _supabase
          .from(AppConstants.designationsTable)
          .select('name')
          .eq('id', id)
          .single();

      final oldName = old['name'];

      /// STEP 2: DELETE (not soft delete)
      await _supabase
          .from(AppConstants.designationsTable)
          .delete()
          .eq('id', id);

      /// STEP 3: clear staff
      await _supabase
          .from('staff')
          .update({'designation': null})
          .ilike('designation', '%$oldName%');

      return DesignationResult(success: true);
    } catch (e) {
      return DesignationResult(success: false, error: e.toString());
    }
  }
  Future<bool> isDesignationUsed(String id) async {
    final old = await _supabase
        .from(AppConstants.designationsTable)
        .select('name')
        .eq('id', id)
        .single();

    final name = old['name'];

    final result = await _supabase
        .from('staff')
        .select('id')
        .eq('designation', name)
        .limit(1);

    return (result as List).isNotEmpty;
  }
}
