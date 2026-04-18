import 'package:flutter/material.dart';
import 'package:campusnex/core/theme/app_colors.dart';

import '../utils/role_resolver.dart';

// ✅ Existing screens
import '../../staff/screens/staff_screen.dart';
import '../widgets/management/management_tab.dart';
import '../widgets/admin_management_tab.dart';
import '../widgets/student_management_tab.dart';
import '../widgets/school_profile_tab.dart';
import '../widgets/school_overview_tab.dart';
import '../widgets/role_banner.dart';

/// ─────────────────────────────────────────────────────────
/// Dashboard Config Model
/// ─────────────────────────────────────────────────────────
class DashboardConfig {
  final List<Tab> tabs;
  final List<Widget> views;
  final Widget? roleBanner;

  const DashboardConfig({
    required this.tabs,
    required this.views,
    this.roleBanner,
  });
}

/// ─────────────────────────────────────────────────────────
/// Config Generator (CORE BRAIN)
/// ─────────────────────────────────────────────────────────
DashboardConfig getDashboardConfig({
  required UserRole role,
  required String userName,
  required bool canCreateAdmin,
}) {
  switch (role) {

    case UserRole.superUser:
      return DashboardConfig(
        tabs: const [
          Tab(text: 'School'),
          Tab(text: 'Admins'),
          Tab(text: 'Overview'),
        ],
        views: const [
          SchoolProfileTab(),
          AdminManagementTab(),
          SchoolOverviewTab(),
        ],
        roleBanner: RoleBanner(
          label: 'Super User',
          color: AppColors.superUserColor,
          userName: userName,
        ),
      );

    case UserRole.adminManager:
      return DashboardConfig(
        tabs: const [
          Tab(text: 'Staff'),
          Tab(text: 'Students'),
          Tab(text: 'Management'),
        ],
        views: const [
          StaffScreen(),
          StudentManagementTab(),
          ManagementTab(),
        ],
        roleBanner: RoleBanner(
          label: 'Admin Manager',
          color: AppColors.adminColor,
          userName: userName,
        ),
      );

    case UserRole.admin:
      final tabs = [
        const Tab(text: 'Staff'),
        const Tab(text: 'Students'),
        if (canCreateAdmin) const Tab(text: 'Management'),
      ];

      final views = [
        const StaffScreen(),
        StudentManagementTab(),
        if (canCreateAdmin) const AdminManagementTab(),
      ];

      return DashboardConfig(
        tabs: tabs,
        views: views,
        roleBanner: RoleBanner(
          label: 'Admin',
          color: AppColors.adminColor,
          userName: userName,
        ),
      );
  }
}