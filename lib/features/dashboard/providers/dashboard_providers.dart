import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/school_model.dart';
import '../../../core/models/staff_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/repositories/school_repository.dart';
import '../../roles/models/role_model.dart';
import '../../roles/repositories/roles_repository.dart';
import '../../staff/repositories/staff_repository.dart';
import '../../../core/repositories/student_repository.dart';
import '../../../core/repositories/user_repository.dart';
import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';

class SchoolOverview {
  final int totalStudents;
  final Map<String, int> studentsPerClass;
  final int totalStaff;
  final int totalAdmins;

  const SchoolOverview({
    required this.totalStudents,
    required this.studentsPerClass,
    required this.totalStaff,
    required this.totalAdmins,
  });
}

/// Admins belonging to the current user's school.
final schoolAdminsProvider =
FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final school = await ref.watch(currentSchoolProvider.future);
  if (school == null) return [];

  return ref.read(userRepositoryProvider).getUsersByRole(
    school.id,
    AppConstants.roleAdmin,
  );
});

/// Count of users belonging to the current school
final schoolUsersCountProvider =
FutureProvider.autoDispose<int>((ref) async {
  var user = await ref.watch(currentUserProvider.future);

  if (user == null) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is AuthSuccess) user = authState.user;
  }

  if (user == null) return 0;

  return ref
      .read(schoolRepositoryProvider)
      .getSchoolUsersCount(user.schoolId);
});

/// School record for the current user.
final currentSchoolProvider =
FutureProvider.autoDispose<SchoolModel?>((ref) async {
  var user = await ref.watch(currentUserProvider.future);

  // Dev fallback
  if (user == null) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is AuthSuccess) user = authState.user;
  }

  if (user == null) return null;

  return ref
      .read(schoolRepositoryProvider)
      .getSchoolById(user.schoolId);
});

/// Aggregated dashboard overview
final schoolOverviewProvider =
FutureProvider.autoDispose<SchoolOverview>((ref) async {
  var user = await ref.watch(currentUserProvider.future);

  if (user == null) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is AuthSuccess) user = authState.user;
  }

  if (user == null) {
    return const SchoolOverview(
      totalStudents: 0,
      studentsPerClass: {},
      totalStaff: 0,
      totalAdmins: 0,
    );
  }

  final schoolId = user.schoolId;

  final studentRepo = ref.read(studentRepositoryProvider);
  final staffRepo = ref.read(staffRepositoryProvider);
  final userRepo = ref.read(userRepositoryProvider);

  final totalStudents = await studentRepo.getCount(schoolId);
  final studentsPerClass = await studentRepo.getCountPerClass(schoolId);

  final staffList = await staffRepo.getStaffList(schoolId); // ✅ FIX
  final totalStaff = staffList.length; // ✅ FIX

  final admins =
  await userRepo.getUsersByRole(schoolId, AppConstants.roleAdmin);

  return SchoolOverview(
    totalStudents: totalStudents,
    studentsPerClass: studentsPerClass,
    totalStaff: totalStaff,
    totalAdmins: admins.length,
  );
});

/// Create Admin
class CreateAdminNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> createAdmin({
    required String name,
    required String mobile,
    required String schoolId,
    required String schoolShortName,
    required String createdBy,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
          () => ref.read(userRepositoryProvider).createAdmin(
        name: name,
        mobile: mobile,
        schoolId: schoolId,
        schoolShortName: schoolShortName,
        createdBy: createdBy,
      ),
    );
  }
}

final createAdminProvider =
AsyncNotifierProvider<CreateAdminNotifier, void>(
    CreateAdminNotifier.new);

/// Set Admin Manager
class SetAdminManagerNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> setAdminManager({
    required String adminId,
    required String schoolId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(userRepositoryProvider).setAdminManager(
        adminId: adminId,
        schoolId: schoolId,
      ),
    );
  }
}

final setAdminManagerProvider =
AsyncNotifierProvider<SetAdminManagerNotifier, void>(
    SetAdminManagerNotifier.new);

/// All users in school
final schoolUsersProvider =
FutureProvider.autoDispose<List<UserModel>>((ref) async {
  var user = await ref.watch(currentUserProvider.future);

  if (user == null) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is AuthSuccess) user = authState.user;
  }

  if (user == null) return [];

  return ref.read(userRepositoryProvider).getUsersBySchool(user.schoolId);
});

/// All staff (active + inactive) — used by StaffScreen for toggle management
final staffListProvider =
FutureProvider.autoDispose<List<StaffModel>>((ref) async {
  var user = await ref.watch(currentUserProvider.future);

  if (user == null) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is AuthSuccess) user = authState.user;
  }

  if (user == null) return [];

  return ref
      .read(staffRepositoryProvider)
      .getAllStaffList(user.schoolId);
});

/// ✅ FIXED: Staff list provider
final schoolStaffProvider =
FutureProvider.autoDispose<List<StaffModel>>((ref) async {
  var user = await ref.watch(currentUserProvider.future);

  if (user == null) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is AuthSuccess) user = authState.user;
  }

  if (user == null) return [];

  return ref
      .read(staffRepositoryProvider)
      .getStaffList(user.schoolId);
});

/// Student list
final schoolStudentsProvider =
FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  var user = await ref.watch(currentUserProvider.future);

  if (user == null) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is AuthSuccess) user = authState.user;
  }

  if (user == null) return [];

  return ref.read(studentRepositoryProvider).getList(user.schoolId);
});

/// Roles for the current school
final rolesProvider = FutureProvider.autoDispose<List<RoleModel>>((ref) async {
  var user = await ref.watch(currentUserProvider.future);

  if (user == null) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is AuthSuccess) user = authState.user;
  }

  if (user == null) return [];

  return ref.read(rolesRepositoryProvider).getRolesBySchool(user.schoolId);
});

/// Creator names for admins
final adminCreatorNamesProvider =
FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final admins = await ref.watch(schoolAdminsProvider.future);

  final creatorIds = admins
      .map((a) => a.createdBy)
      .whereType<String>()
      .toSet()
      .toList();

  if (creatorIds.isEmpty) return {};

  return ref.read(userRepositoryProvider).getCreatorLabels(creatorIds);
});

