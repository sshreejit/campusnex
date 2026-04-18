import 'package:campusnex/core/models/user_model.dart';

enum UserRole {
  superUser,
  adminManager,
  admin,
}

UserRole getUserRole(UserModel user) {
  if (user.isSuperUser) {
    return UserRole.superUser;
  }

  if (user.isAdmin && user.canCreateAdmin) {
    return UserRole.adminManager;
  }

  if (user.isAdmin) {
    return UserRole.admin;
  }

  assert(false, 'Unsupported role: ${user.role}');
  return UserRole.admin;
}