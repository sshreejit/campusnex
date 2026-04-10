class AppConstants {
  AppConstants._();

  static const String appName = 'CampusNex';
  static const String appTagline = 'Education Management Simplified';

  // Supabase table names
  static const String usersTable = 'users';
  static const String schoolsTable = 'schools';
  static const String studentsTable = 'students';
  static const String staffTable = 'staff';
  static const String classesTable = 'classes';
  static const String sectionsTable = 'sections';
  static const String parentsTable = 'parents';
  static const String classTeachersTable = 'class_teachers';
  static const String timetableTable = 'timetables';
  static const String attendanceTable = 'attendance';
  static const String feesTable = 'fees';
  static const String paymentsTable = 'payments';
  static const String noticesTable = 'notices';
  static const String sessionsTable = 'sessions';
  static const String rolesTable = 'roles';
  static const String staffRolesTable = 'staff_roles';
  static const String designationsTable = 'designations';

  // Supabase storage buckets
  static const String studentPhotosBucket = 'student_photos';
  static const String staffPhotosBucket = 'staff_photos';
  static const String schoolLogosBucket = 'school_logos';

  // User roles
  static const String roleSuperUser = 'super_user';
  static const String roleAdmin = 'admin';
  static const String rolePrincipal = 'principal';
  static const String roleCoordinator = 'coordinator';
  static const String roleStaff = 'staff';
  static const String roleTtIncharge = 'tt_incharge';
  static const String roleParent = 'parent';

  // Shared preferences keys
  static const String prefSchoolId = 'school_id';
  static const String prefUserId = 'user_id';
  static const String prefUserRole = 'user_role';
  static const String prefSessionId = 'session_id';
}
