import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/class_model.dart';
import '../repositories/class_repository.dart';
import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';

final classesProvider = FutureProvider<List<ClassModel>>((ref) async {
  final authState = ref.watch(authNotifierProvider);

  if (authState is! AuthSuccess) return [];

  return ref
      .read(classRepositoryProvider)
      .getClasses(authState.user.schoolId);
});