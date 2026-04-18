import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/school_model.dart';
import '../../../core/models/staff_model.dart';
import '../../../core/models/user_model.dart';

import '../../../core/repositories/school_repository.dart';
import '../../../core/repositories/student_repository.dart';
import '../../../core/repositories/user_repository.dart';

import '../../staff/repositories/staff_repository.dart';
import '../../roles/models/role_model.dart';
import '../../roles/repositories/roles_repository.dart';

import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';

/// ─────────────────────────────────────────────────────────
/// SCHOOL OVERVIEW MODEL
/// ─────────────────────────────────────────────────────────
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

/// ─────────────────────────────────────────────────────────
/// CURRENT SCHOOL
/// ─────────────────────────────────────────────────────────
final currentSchoolProvider =
FutureProvider.autoDispose<SchoolModel?>((ref) async {
  var user = await ref.watch(currentUserProvider.future);

  if (user == null) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is AuthSuccess) user = authState.user;
  }

  if (user == null) return null;

  return ref
      .read(schoolRepositoryProvider)
      .getSchoolById(user.schoolId);
});

/// ─────────────────────────────────────────────────────────
/// SCHOOL ADMINS
/// ─────────────────────────────────────────────────────────
final schoolAdminsProvider =
FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final school = await ref.watch(currentSchoolProvider.future);
  if (school == null) return [];

  return ref.read(userRepositoryProvider).getUsersByRole(
    school.id,
    AppConstants.roleAdmin,
  );
});

/// ─────────────────────────────────────────────────────────
/// SCHOOL USERS COUNT (FOR SHORT NAME LOCK LOGIC)
/// ─────────────────────────────────────────────────────────
final schoolUsersCountProvider =
FutureProvider.autoDispose<int>((ref) async {
  var user = await ref.watch(currentUserProvider.future);

  if (user == null) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is AuthSuccess) user = authState.user;
  }

  if (user == null) return 0;

  final schoolId = user.schoolId;

  final userRepo = ref.read(userRepositoryProvider);
  final staffRepo = ref.read(staffRepositoryProvider);
  final studentRepo = ref.read(studentRepositoryProvider);

  // Count all types
  final admins =
  await userRepo.getUsersByRole(schoolId, AppConstants.roleAdmin);

  final staff = await staffRepo.getStaffList(
    schoolId: schoolId,
    from: 0,
    to: 0, // we only need count
  );

  final students = await studentRepo.getCount(schoolId);

  return admins.length + staff.length + students;
});

/// ─────────────────────────────────────────────────────────
/// ADMIN CREATOR NAMES
/// ─────────────────────────────────────────────────────────
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

/// ─────────────────────────────────────────────────────────
/// ROLES (USED IN ADMIN MANAGEMENT TAB)
/// ─────────────────────────────────────────────────────────
final rolesProvider =
FutureProvider.autoDispose<List<RoleModel>>((ref) async {
  var user = await ref.watch(currentUserProvider.future);

  if (user == null) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is AuthSuccess) user = authState.user;
  }

  if (user == null) return [];

  return ref.read(rolesRepositoryProvider).getRolesBySchool(user.schoolId);
});

/// ─────────────────────────────────────────────────────────
/// SCHOOL OVERVIEW (STATS)
/// ─────────────────────────────────────────────────────────
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
  final studentsPerClass =
  await studentRepo.getCountPerClass(schoolId);

  final staffList = await staffRepo.getStaffList(
    schoolId: schoolId,
    from: 0,
    to: 49,
  );

  final admins =
  await userRepo.getUsersByRole(schoolId, AppConstants.roleAdmin);

  return SchoolOverview(
    totalStudents: totalStudents,
    studentsPerClass: studentsPerClass,
    totalStaff: staffList.length,
    totalAdmins: admins.length,
  );
});

/// ─────────────────────────────────────────────────────────
/// CREATE ADMIN PROVIDER
/// ─────────────────────────────────────────────────────────
final createAdminProvider =
StateNotifierProvider.autoDispose<CreateAdminNotifier, AsyncValue<void>>(
      (ref) => CreateAdminNotifier(ref),
);

/// ─────────────────────────────────────────────────────────
/// CREATE ADMIN NOTIFIER
/// ─────────────────────────────────────────────────────────
class CreateAdminNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  CreateAdminNotifier(this.ref) : super(const AsyncData(null));

  Future<void> createAdmin({
    required String name,
    required String mobile,
    required String schoolId,
    required String schoolShortName,
    required String createdBy,
  }) async {
    state = const AsyncLoading();

    try {
      final userRepo = ref.read(userRepositoryProvider);

      await userRepo.createUser(
        authUserId: null, // ✅ TEMP (as discussed earlier)
        schoolId: schoolId,
        name: name,
        mobile: mobile,
        role: AppConstants.roleAdmin,
        roleId: null,
        createdBy: createdBy,
        schoolShortName: schoolShortName,
      );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
