import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, Supabase;

import '../../core/constants/app_constants.dart';
import '../../core/models/user_model.dart';
import '../../core/constants/dev_config.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/repositories/school_repository.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/services/supabase_service.dart';
import 'auth_state.dart';
import '../dashboard/providers/dashboard_providers.dart';

part 'auth_notifier.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthFlowState build() {
    final sub = ref
        .read(authRepositoryProvider)
        .authStateChanges
        .listen((event) {
      if (event.event == AuthChangeEvent.signedIn) {
        _handleSignedIn();
      } else if (event.event == AuthChangeEvent.signedOut) {
        if (state is! AuthFlowError) {
          state = const AuthInitial();
        }
      }
    });

    ref.onDispose(sub.cancel);

    Future.microtask(_restoreSession);
    return const AuthLoading();
  }

  // ── LOGIN ───────────────────────────────────────────────

  Future<void> login(String input) async {
    state = const AuthLoading();

    try {
      final data = await ref
          .read(userRepositoryProvider)
          .login(input.toLowerCase().trim());

      if (data == null) {
        state = const AuthFlowError('User not found');
      } else {
        final user = UserModel.fromJson(data);
        await _saveSession(user);
        ref.invalidate(schoolAdminsProvider);
        state = AuthSuccess(user);
      }
    } catch (e) {
      state = AuthFlowError(_message(e));
    }
  }

  // ✅ FIXED: matches UI (2 params)
  Future<void> signIn(String input, String schoolId) async {
    await login(input); // schoolId ignored safely
  }

  // ── DEV LOGIN ───────────────────────────────────────────

  Future<void> devLogin(String mobile) async {
    assert(isDevMode, 'devLogin must only be called in dev mode');
    state = const AuthLoading();

    try {
      final existing =
      await ref.read(userRepositoryProvider).getUserByMobile(mobile);

      if (existing != null) {
        await _saveSession(existing);
        state = AuthSuccess(existing);
      } else {
        state = DevNewUser(mobile: mobile);
      }
    } catch (e) {
      state = AuthFlowError(_message(e));
    }
  }

  // ✅ FIXED: positional createSchool
  Future<void> devOnboard({
    required String mobile,
    required String name,
  }) async {
    try {
      state = const AuthLoading();

      final school = await ref
          .read(schoolRepositoryProvider)
          .createSchool('DevSchool');

      final user = await ref.read(userRepositoryProvider).createUser(
        authUserId: null,
        schoolId: school.id,
        role: AppConstants.roleSuperUser,
        name: name,
        mobile: mobile,
        schoolShortName: school.shortName,
      );

      await _saveSession(user);
      state = AuthSuccess(user);
    } catch (e) {
      state = AuthFlowError(_message(e));
    }
  }

  // ── REGISTER ────────────────────────────────────────────

  // ✅ FIXED: positional args
  Future<void> register(String email, String password) async {
    try {
      state = const AuthLoading();

      await ref.read(authRepositoryProvider).signUp(email, password);

      state = const AwaitingEmailVerification();
    } catch (e) {
      state = AuthFlowError(_message(e));
    }
  }

  // ── RESET PASSWORD ──────────────────────────────────────

  Future<void> resetPassword(String email) async {
    try {
      await ref.read(authRepositoryProvider).resetPassword(email);
    } catch (e) {
      state = AuthFlowError(_message(e));
    }
  }

  // ── SETUP SCHOOL ────────────────────────────────────────

  // ✅ FIXED: added mobile + positional createSchool
  Future<void> setupSchoolAndUser({
    required String schoolName,
    required String userName,
    required String mobile,
  }) async {
    try {
      state = const AuthLoading();

      final school = await ref
          .read(schoolRepositoryProvider)
          .createSchool(schoolName);

      final authUser = Supabase.instance.client.auth.currentUser;

      if (authUser == null) {
        throw Exception('User not authenticated');
      }

      final user = await ref.read(userRepositoryProvider).createUser(
        authUserId: authUser.id,
        schoolId: school.id,
        role: AppConstants.roleAdmin,
        name: userName,
        mobile: mobile,
        schoolShortName: school.shortName,
      );

      await _saveSession(user);
      state = AuthSuccess(user);
    } catch (e) {
      state = AuthFlowError(_message(e));
    }
  }

  // ── LOGOUT ──────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _clearSession();
      await ref.read(authRepositoryProvider).signOut();
      state = const AuthInitial();
    } catch (e) {
      state = AuthFlowError(_message(e));
    }
  }

  Future<void> signOut() async {
    await logout();
  }

  // ── INTERNAL HANDLER ────────────────────────────────────

  Future<void> _handleSignedIn() async {
    try {
      final authUser = Supabase.instance.client.auth.currentUser;

      if (authUser == null) return;

      final user = await ref
          .read(userRepositoryProvider)
          .getUserByAuthId(authUser.id);

      if (user == null) {
        state = NewUserDetected(
          authUid: authUser.id,
          email: authUser.email ?? '',
        );
      } else {
        await _saveSession(user);
        state = AuthSuccess(user);
      }
    } catch (e) {
      state = AuthFlowError(_message(e));
    }
  }

  // ── SESSION ─────────────────────────────────────────────

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.prefUserId);

      if (userId == null) {
        state = const AuthInitial();
        return;
      }

      final user =
      await ref.read(userRepositoryProvider).getUserById(userId);

      if (user == null) {
        await _clearSession();
        state = const AuthInitial();
      } else {
        ref.invalidate(schoolAdminsProvider);
        state = AuthSuccess(user);
      }
    } catch (e) {
      state = AuthFlowError(_message(e));
    }
  }

  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefUserId, user.id);
    await prefs.setString(AppConstants.prefUserRole, user.role);
    await prefs.setString(AppConstants.prefSchoolId, user.schoolId);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefUserId);
    await prefs.remove(AppConstants.prefUserRole);
    await prefs.remove(AppConstants.prefSchoolId);
  }

  void updateUser(UserModel updatedUser) {
    if (state is AuthSuccess) state = AuthSuccess(updatedUser);
  }

  void resetToInitial() => state = const AuthInitial();

  String _message(Object e) =>
      e.toString().replaceFirst('Exception: ', '');
}