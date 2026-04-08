import 'package:flutter/foundation.dart';
import '../../core/models/user_model.dart';

/// Represents every distinct stage of the authentication flow.
@immutable
sealed class AuthFlowState {
  const AuthFlowState();
}

/// App just launched; no action taken yet.
class AuthInitial extends AuthFlowState {
  const AuthInitial();
}

/// An async operation is in progress (signing in, creating records).
class AuthLoading extends AuthFlowState {
  const AuthLoading();
}

/// signUp succeeded but Supabase email confirmation is enabled.
/// The user must click the verification link before they can sign in.
class AwaitingEmailVerification extends AuthFlowState {
  const AwaitingEmailVerification();
}

/// Session created, but no matching row in [users] table.
/// The user must provide school name + their name to complete registration.
class NewUserDetected extends AuthFlowState {
  final String authUid;
  final String email;

  const NewUserDetected({
    required this.authUid,
    required this.email,
  });
}

/// Dev mode only: mobile number provided but no matching row in [users] table.
/// The user must enter their name to complete onboarding.
/// Only reachable when [isDevMode] is true.
class DevNewUser extends AuthFlowState {
  final String mobile;

  const DevNewUser({
    required this.mobile,
  });
}

/// User row found (or just created). The router reads [user.role] to redirect.
class AuthSuccess extends AuthFlowState {
  final UserModel user;

  const AuthSuccess(this.user);
}

/// Any error from Supabase or from our own logic.
class AuthFlowError extends AuthFlowState {
  final String message;

  const AuthFlowError(this.message);
}