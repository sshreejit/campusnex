import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/user_repository.dart';
import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';
import '../models/designation_model.dart';
import '../repositories/designation_repository.dart';

final designationsProvider =
    FutureProvider.autoDispose<List<DesignationModel>>((ref) async {
  var user = await ref.watch(currentUserProvider.future);

  if (user == null) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is AuthSuccess) user = authState.user;
  }

  if (user == null) return [];

  return ref
      .read(designationRepositoryProvider)
      .getDesignations(user.schoolId);
});
