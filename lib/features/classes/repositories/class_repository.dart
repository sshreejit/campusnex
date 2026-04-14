import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/class_model.dart';
import '../../../core/models/result.dart';

final classRepositoryProvider = Provider<ClassRepository>((ref) {
  return ClassRepository(Supabase.instance.client);
});

class ClassRepository {
  final SupabaseClient _supabase;

  ClassRepository(this._supabase);

  Future<List<ClassModel>> getClasses(String schoolId) async {
    final res = await _supabase
        .from('classes')
        .select()
        .eq('school_id', schoolId)
        .eq('is_active', true)
        .order('class_name', ascending: true)
        .order('section', ascending: true);

    return (res as List).map((e) => ClassModel.fromMap(e)).toList();
  }

  Future<Result> addClass({
    required String className,
    required String section,
    required String schoolId,
  }) async {
    try {
      await _supabase.from('classes').insert({
        'class_name': className.trim(),
        'section': section.trim(),
        'school_id': schoolId,
      });

      return const Result(success: true);
    } catch (e) {
      return Result(success: false, error: e.toString());
    }
  }

  Future<Result> updateClass({
    required String id,
    required String className,
    required String section,
  }) async {
    try {
      await _supabase
          .from('classes')
          .update({
        'class_name': className.trim(),
        'section': section.trim(),
      })
          .eq('id', id);

      return const Result(success: true);
    } catch (e) {
      return Result(success: false, error: e.toString());
    }
  }

  Future<Result> deleteClass(String id) async {
    try {
      await _supabase
          .from('classes')
          .update({'is_active': false})
          .eq('id', id);

      return const Result(success: true);
    } catch (e) {
      return Result(success: false, error: e.toString());
    }
  }
}