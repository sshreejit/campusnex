import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/staff_model.dart';
import '../../../core/models/user_model.dart'; // ✅ ADD THIS
import '../../../core/repositories/user_repository.dart';

import '../repositories/staff_repository.dart';
import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';

class StaffListNotifier extends StateNotifier<AsyncValue<List<StaffModel>>> {
  final Ref ref;

  int _from = 0;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  StaffListNotifier(this.ref) : super(const AsyncLoading()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    try {
      final user = await _getUser();
      if (user == null) {
        state = const AsyncData([]);
        return;
      }

      _from = 0;
      _hasMore = true;

      final data = await ref.read(staffRepositoryProvider).getStaffList(
        schoolId: user.schoolId,
        from: _from,
        to: _from + _pageSize - 1,
      );

      _from += _pageSize;

      state = AsyncData(data);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;

    _isLoadingMore = true;

    try {
      final user = await _getUser();
      if (user == null) return;

      final current = state.value ?? [];

      final data = await ref.read(staffRepositoryProvider).getStaffList(
        schoolId: user.schoolId,
        from: _from,
        to: _from + _pageSize - 1,
      );

      if (data.isEmpty) {
        _hasMore = false;
      } else {
        _from += _pageSize;
      }

      state = AsyncData([...current, ...data]);
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }

  Future<UserModel?> _getUser() async {
    var user = await ref.read(currentUserProvider.future);

    if (user == null) {
      final authState = ref.read(authNotifierProvider);
      if (authState is AuthSuccess) user = authState.user;
    }

    return user;
  }
}

final staffListProvider = StateNotifierProvider.autoDispose<
    StaffListNotifier, AsyncValue<List<StaffModel>>>(
      (ref) => StaffListNotifier(ref),
);

