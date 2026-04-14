import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/class_model.dart';
import '../repositories/class_repository.dart';
import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';

final classesProvider = FutureProvider<List<ClassModel>>((ref) async {
  final authState = ref.read(authNotifierProvider);

  if (authState is! AuthSuccess) return [];

  final user = authState.user;

  return ref
      .read(classRepositoryProvider)
      .getClasses(user.schoolId);
});