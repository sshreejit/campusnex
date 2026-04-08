import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../services/supabase_service.dart';

class StudentRepository {
  final SupabaseClient _client;

  StudentRepository(this._client);

  Future<int> getCount(String schoolId) async {
    final data = await _client
        .from(AppConstants.studentsTable)
        .select('id')
        .eq('school_id', schoolId);
    return data.length;
  }

  /// Returns student count grouped by class_id.
  /// Clients with no class assignment are keyed as 'Unassigned'.
  Future<Map<String, int>> getCountPerClass(String schoolId) async {
    final data = await _client
        .from(AppConstants.studentsTable)
        .select('class_id')
        .eq('school_id', schoolId);

    final counts = <String, int>{};
    for (final row in data) {
      final classId = (row['class_id'] as String?) ?? 'Unassigned';
      counts[classId] = (counts[classId] ?? 0) + 1;
    }
    return counts;
  }

  Future<List<Map<String, dynamic>>> getList(String schoolId) async {
    return await _client
        .from(AppConstants.studentsTable)
        .select('id, name, class_id, section_id')
        .eq('school_id', schoolId)
        .order('created_at', ascending: false);
  }

  Future<void> addStudent({
    required String schoolId,
    required String name,
    String? classId,
    String? sectionId,
    String? parentId,
  }) async {
    await _client.from(AppConstants.studentsTable).insert({
      'school_id': schoolId,
      'name': name,
      if (classId != null) 'class_id': classId,
      if (sectionId != null) 'section_id': sectionId,
      if (parentId != null) 'parent_id': parentId,
    });
  }
}

final studentRepositoryProvider = Provider<StudentRepository>(
  (ref) => StudentRepository(SupabaseService.client),
);
