import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';
import '../models/role_model.dart';
import '../repositories/roles_repository.dart';

final rolesProvider =
FutureProvider.autoDispose<List<RoleModel>>((ref) async {
  final authState = ref.watch(authNotifierProvider);

  if (authState is! AuthSuccess) {
    return [];
  }

  final roles = await ref
      .read(rolesRepositoryProvider)
      .getRolesBySchool(authState.user.schoolId);

  return roles;
});