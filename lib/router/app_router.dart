import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/dev_config.dart';
import '../features/auth/auth_notifier.dart';
import '../features/auth/auth_state.dart';
import '../features/auth/screens/dev_login_screen.dart';
import '../features/auth/screens/dev_onboarding_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/phone_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/setup_school_screen.dart';
import '../features/dashboard/screens/admin_dashboard.dart';
import '../features/dashboard/screens/coordinator_dashboard.dart';
import '../features/dashboard/screens/parent_dashboard.dart';
import '../features/dashboard/screens/staff_dashboard.dart';
import '../features/dashboard/screens/super_user_dashboard.dart';

part 'app_router.g.dart';

// ── Route paths ─────────────────────────────────────────────

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String setupSchool = '/setup-school';
  static const String devOnboarding = '/dev-onboarding';
  static const String superUserDashboard = '/super-user';
  static const String adminDashboard = '/admin';
  static const String coordinatorDashboard = '/coordinator';
  static const String staffDashboard = '/staff';
  static const String parentDashboard = '/parent';

  static String forRole(String role) => switch (role) {
    AppConstants.roleSuperUser => superUserDashboard,
    AppConstants.roleAdmin => adminDashboard,
    AppConstants.roleCoordinator => coordinatorDashboard,
    AppConstants.roleStaff => staffDashboard,
    AppConstants.roleParent => parentDashboard,
    _ => welcome,
  };

  static const _dashboardRoutes = {
    superUserDashboard,
    adminDashboard,
    coordinatorDashboard,
    staffDashboard,
    parentDashboard,
  };

  static bool isDashboard(String loc) => _dashboardRoutes.contains(loc);
}

// ── Router notifier ─────────────────────────────────────────

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _auth = _ref.read(authNotifierProvider);
    _sub = _ref.listen<AuthFlowState>(authNotifierProvider, (_, next) {
      _auth = next;
      notifyListeners();
    });
  }

  final Ref _ref;
  late AuthFlowState _auth;
  late final ProviderSubscription<AuthFlowState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }

  String? redirect(BuildContext context, GoRouterState state) =>
      _authGuard(_auth, state.uri.toString());
}

// ── Auth Guard (FIXED) ─────────────────────────────────────

String? _authGuard(AuthFlowState auth, String location) {
  switch (auth) {
    case AuthSuccess(:final user):
      final dest = AppRoutes.forRole(user.role);
      return location == dest ? null : dest;

    case NewUserDetected():
      return location == AppRoutes.setupSchool
          ? null
          : AppRoutes.setupSchool;

    case DevNewUser():
      return location == AppRoutes.devOnboarding
          ? null
          : AppRoutes.devOnboarding;

    case AuthLoading():
      return null; // ✅ FIX

    case AwaitingEmailVerification():
      return null;

    default:
    // ✅ IMPROVED
      if (location == AppRoutes.login ||
          location == AppRoutes.welcome ||
          location == AppRoutes.register) {
        return null;
      }
      return AppRoutes.login;
  }
}

// ── Router provider ─────────────────────────────────────────

@riverpod
GoRouter appRouter(Ref ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: isDevMode ? AppRoutes.login : AppRoutes.splash,
    debugLogDiagnostics: isDevMode, // ✅ FIX
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) =>
        isDevMode ? const DevLoginScreen() : const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.setupSchool,
        builder: (context, state) => const SetupSchoolScreen(),
      ),
      GoRoute(
        path: AppRoutes.devOnboarding,
        builder: (context, state) => const DevOnboardingScreen(),
      ),

      // Dashboards
      GoRoute(
        path: AppRoutes.superUserDashboard,
        builder: (context, state) => const SuperUserDashboard(),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: AppRoutes.coordinatorDashboard,
        builder: (context, state) => const CoordinatorDashboard(),
      ),
      GoRoute(
        path: AppRoutes.staffDashboard,
        builder: (context, state) => const StaffDashboard(),
      ),
      GoRoute(
        path: AppRoutes.parentDashboard,
        builder: (context, state) => const ParentDashboard(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}

// ── Splash Screen ─────────────────────────────────────────

class _SplashScreen extends ConsumerStatefulWidget {
  const _SplashScreen();

  @override
  ConsumerState<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<_SplashScreen> {
  bool _navigated = false;

  void _go(String route) {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go(route);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  Future<void> _redirect() async {
    ref.read(authNotifierProvider);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);

    switch (authState) {
      case AuthSuccess():
        _go(AppRoutes.forRole(authState.user.role));
      case NewUserDetected():
        _go(AppRoutes.setupSchool);
      case DevNewUser():
        _go(AppRoutes.devOnboarding);
      case AuthLoading():
        break;
      default:
        _go(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthFlowState>(authNotifierProvider, (_, next) {
      switch (next) {
        case AuthSuccess():
          _go(AppRoutes.forRole(next.user.role));
        case NewUserDetected():
          _go(AppRoutes.setupSchool);
        case DevNewUser():
          _go(AppRoutes.devOnboarding);
        case AuthFlowError():
          _go(AppRoutes.welcome);
        default:
          break;
      }
    });

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'CampusNex',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Education Management Simplified',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}